import AppKit
import SceneKit

@MainActor
final class SceneManager: NSObject, ObservableObject, SCNSceneRendererDelegate {
    @Published private(set) var mode: LayoutMode = .table
    @Published private(set) var hoveredElement: ChemicalElement?
    @Published var temperatureC: Double = 20 { didSet { refreshVisuals() } }
    @Published var query: String = "" { didSet { refreshVisuals(); centerMatch() } }

    let scene = SCNScene()
    let root = SCNNode()          // наклон режима и вращение раскладки
    let tilt = SCNNode()          // параллакс всей таблицы, не больше ~8°
    let cameraRig = SCNNode()
    let cameraNode = SCNNode()
    private(set) var cards: [CardNode] = []
    private var layoutTask: Task<Void, Never>?

    /// Нормализованное положение мыши в окне [-1, 1]; параллакс сглаживает его.
    nonisolated(unsafe) var mouseTarget = SIMD2<Float>(0, 0)
    nonisolated(unsafe) private var mouseSmoothed = SIMD2<Float>(0, 0)

    var onElementSelected: ((ChemicalElement) -> Void)?
    var onHoverChange: ((Bool) -> Void)?

    override init() {
        super.init()
        scene.background.contents = NSColor.clear

        let camera = SCNCamera()
        camera.fieldOfView = 50
        camera.zFar = 200
        camera.wantsHDR = true
        camera.bloomIntensity = 1.4
        camera.bloomThreshold = 0.35
        camera.bloomBlurRadius = 10
        camera.wantsExposureAdaptation = false
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 22)
        cameraRig.addChildNode(cameraNode)
        scene.rootNode.addChildNode(cameraRig)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light!.type = .ambient
        ambient.light!.intensity = 400
        scene.rootNode.addChildNode(ambient)
        let omni = SCNNode()
        omni.light = SCNLight()
        omni.light!.type = .omni
        omni.position = SCNVector3(0, 10, 20)
        scene.rootNode.addChildNode(omni)

        tilt.addChildNode(root)
        scene.rootNode.addChildNode(tilt)
        addBackdrop()
        buildCards()
    }

    /// Едва заметная сетка и радиальный градиент за таблицей.
    private func addBackdrop() {
        let gradient = SCNPlane(width: 80, height: 50)
        let mat = SCNMaterial()
        mat.lightingModel = .constant
        mat.isDoubleSided = true
        let img = NSImage(size: NSSize(width: 64, height: 64), flipped: false) { rect in
            let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
                NSColor(srgbRed: 0.04, green: 0.10, blue: 0.23, alpha: 1).cgColor,
                NSColor.black.cgColor,
            ] as CFArray, locations: [0, 1])!
            NSGraphicsContext.current?.cgContext.drawRadialGradient(
                g, startCenter: CGPoint(x: 32, y: 40), startRadius: 2,
                endCenter: CGPoint(x: 32, y: 32), endRadius: 46, options: [])
            return true
        }
        mat.diffuse.contents = img
        gradient.materials = [mat]
        let bg = SCNNode(geometry: gradient)
        bg.position = SCNVector3(0, 0, -16)
        scene.rootNode.addChildNode(bg)

        let grid = SCNNode()
        let step: Float = 2
        for i in stride(from: -20, through: 20, by: Int(step)) {
            for axis in 0..<2 {
                let line = SCNBox(width: axis == 0 ? 40 : 0.015, height: 0.015, length: axis == 0 ? 0.015 : 40, chamferRadius: 0)
                line.firstMaterial?.lightingModel = .constant
                line.firstMaterial?.diffuse.contents = NSColor(white: 1, alpha: 0.08)
                let n = SCNNode(geometry: line)
                if axis == 0 { n.position.y = CGFloat(i) } else { n.position.x = CGFloat(i) }
                grid.addChildNode(n)
            }
        }
        grid.position.z = -6
        scene.rootNode.addChildNode(grid)
    }

    // MARK: Карточки

    private func buildCards() {
        let elements = ElementStore.shared.elements
        cards = elements.map { CardNode(element: $0) }
        cards.forEach(root.addChildNode)
        let specs = elements.map(CardSpec.init)
        Task {
            let textures = await CardNode.renderTextures(specs)
            for card in cards { if let t = textures[card.element.number] { card.apply(t) } }
        }
        setMode(.table, animated: false)
    }

    // MARK: Режимы

    func setMode(_ newMode: LayoutMode, animated: Bool = true) {
        let previous = mode
        mode = newMode
        let inputs = cards.map { LayoutInput(number: $0.element.number, xpos: $0.element.xpos, ypos: $0.element.ypos) }
        let current = cards.map { SIMD3<Float>($0.position) }
        layoutTask?.cancel()
        layoutTask = Task {
            let targets = await LayoutEngine.compute(newMode, inputs: inputs)
            guard !Task.isCancelled else { return }
            prepareRoot(for: newMode)
            guard animated else {
                for (i, c) in cards.enumerated() {
                    c.position = SCNVector3(targets[i].position)
                    c.eulerAngles = SCNVector3(targets[i].euler)
                }
                return
            }
            // Сфера/спираль → сетка: сначала «распад на частицы», затем сборка в облако.
            if newMode == .grid, previous != .grid {
                LayoutEngine.apply(LayoutEngine.scatter(from: current), to: cards, duration: 0.45, stagger: 0,
                                   timing: CAMediaTimingFunction(name: .easeOut))
                try? await Task.sleep(for: .milliseconds(450))
                guard !Task.isCancelled else { return }
            }
            LayoutEngine.apply(targets, to: cards)
        }
    }

    /// Состояние корневого узла и ограничений для режима.
    private func prepareRoot(for mode: LayoutMode) {
        root.removeAction(forKey: "spin")
        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = .all
        for c in cards { c.constraints = mode == .sphere ? [billboard] : nil }

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        switch mode {
        case .table:
            // Изометрия: наклон всей таблицы на −15° по X.
            root.eulerAngles = SCNVector3(-15 * CGFloat.pi / 180, 0, 0)
            cameraNode.position = SCNVector3(0, 0, 21)
        case .helix:
            root.eulerAngles = SCNVector3(0, 0, 0)
            cameraNode.position = SCNVector3(0, 0, 24)
        case .sphere:
            root.eulerAngles = SCNVector3(0, 0, 0)
            cameraNode.position = SCNVector3(0, 0, 20)
        case .grid:
            root.eulerAngles = SCNVector3(0.2, 0.3, 0)
            cameraNode.position = SCNVector3(0, 0, 24)
        }
        SCNTransaction.commit()

        // Медленное вращение вокруг оси Y (период ~40 с); для сферы — чуть быстрее.
        if mode == .helix || mode == .sphere {
            let period: TimeInterval = mode == .helix ? 40 : 30
            root.runAction(.repeatForever(.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: period)), forKey: "spin")
        }
    }

    // MARK: Hit-test

    func card(at point: CGPoint, in view: SCNView) -> CardNode? {
        let hits = view.hitTest(point, options: [.searchMode: SCNHitTestSearchMode.closest.rawValue, .ignoreHiddenNodes: true])
        var node = hits.first?.node
        while let n = node, !(n is CardNode) { node = n.parent }
        return node as? CardNode
    }

    func updateHover(_ card: CardNode?) {
        for c in cards where c !== card && c.isHovered { c.setHover(false) }
        card?.setHover(true)
        if hoveredElement?.number != card?.element.number {
            hoveredElement = card?.element
            onHoverChange?(card != nil)
        }
        if card != nil { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() }
    }

    private func refreshVisuals() {
        for c in cards { c.applyVisual(celsius: temperatureC, query: query) }
    }

    /// Сдвигает таблицу так, чтобы найденная карточка оказалась у центра кадра.
    private func centerMatch() {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty, let card = cards.first(where: { matches($0, q) }) else {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.6
            root.position = SCNVector3Zero
            SCNTransaction.commit()
            return
        }
        card.setHover(true)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.6
        root.position = SCNVector3(-card.position.x, -card.position.y, 0)
        SCNTransaction.commit()
    }

    private func matches(_ card: CardNode, _ q: String) -> Bool {
        let s = q.lowercased()
        return RussianNames.name(card.element.number).lowercased().contains(s)
            || card.element.name.lowercased().contains(s)
            || card.element.symbol.lowercased().contains(s)
            || String(card.element.number) == s
    }

    func select(_ card: CardNode) {
        card.flip { [weak self] in
            self?.onElementSelected?(card.element)
        }
    }

    // MARK: Параллакс (рендер-поток)

    nonisolated func renderer(_ renderer: any SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Экспоненциальное сглаживание: s += (t − s)·α, α ≈ 0.08 при 60 FPS даёт «инерцию» камеры.
        mouseSmoothed += (mouseTarget - mouseSmoothed) * 0.08
        let maxAngle: Float = 0.14 // ≈ 8°
        let euler = SCNVector3(-mouseSmoothed.y * maxAngle, mouseSmoothed.x * maxAngle, 0)
        DispatchQueue.main.async { [tilt] in tilt.eulerAngles = euler }
    }
}

// MARK: - SCNView с отслеживанием мыши

final class QuantaSCNView: SCNView {
    weak var manager: SceneManager?
    private var tracking: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let t = NSTrackingArea(rect: bounds, options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
        addTrackingArea(t)
        tracking = t
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseMoved(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        manager?.mouseTarget = SIMD2(Float(p.x / bounds.width) * 2 - 1, Float(p.y / bounds.height) * 2 - 1)
        manager?.updateHover(manager?.card(at: p, in: self))
    }

    override func mouseExited(with event: NSEvent) {
        manager?.mouseTarget = .zero
        manager?.updateHover(nil)
    }

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        if let card = manager?.card(at: p, in: self) {
            manager?.select(card)
        } else {
            window?.performDrag(with: event)
        }
    }
}
