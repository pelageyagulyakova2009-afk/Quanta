import AppKit
import SceneKit

/// Данные для рисования текстуры — копируются в фоновую задачу.
struct CardSpec: Sendable {
    let number: Int
    let symbol: String
    let name: String
    let mass: Double
    let phase: String?
    let color: CodableColor

    init(_ e: ChemicalElement) {
        number = e.number
        symbol = e.symbol
        name = RussianNames.name(e.number)
        mass = e.atomicMass
        phase = e.phase
        let c = e.elementCategory.nsColor.usingColorSpace(.sRGB) ?? .white
        color = CodableColor(r: c.redComponent, g: c.greenComponent, b: c.blueComponent)
    }
}

struct CodableColor: Sendable {
    let r, g, b: CGFloat
    var ns: NSColor { NSColor(srgbRed: r, green: g, blue: b, alpha: 1) }
}

struct CardTextures: @unchecked Sendable {
    let diffuse: CGImage
    let emission: CGImage
    let hover: CGImage
}

final class CardNode: SCNNode {
    static let size = CGSize(width: 1.0, height: 1.2)
    static let geometryTemplate: SCNPlane = {
        let p = SCNPlane(width: size.width, height: size.height)
        p.cornerRadius = 0.08
        return p
    }()

    let element: ChemicalElement
    /// Внутренний узел: layout двигает self, а hover/flip анимируют content — анимации не конфликтуют.
    let content = SCNNode()
    private let material = SCNMaterial()
    private let hoverMaterial = SCNMaterial()
    private(set) var isHovered = false

    init(element: ChemicalElement) {
        self.element = element
        super.init()
        name = "card-\(element.number)"

        let plane = Self.geometryTemplate.copy() as! SCNPlane
        material.lightingModel = .constant
        material.isDoubleSided = true
        material.blendMode = .alpha
        material.writesToDepthBuffer = false
        material.diffuse.contents = NSColor(white: 0.05, alpha: 0.6)
        material.emission.contents = NSColor.black
        material.emission.intensity = 1.0
        plane.materials = [material]
        content.geometry = plane
        content.name = name
        addChildNode(content)

        let overlay = Self.geometryTemplate.copy() as! SCNPlane
        hoverMaterial.lightingModel = .constant
        hoverMaterial.isDoubleSided = true
        hoverMaterial.blendMode = .alpha
        hoverMaterial.writesToDepthBuffer = false
        hoverMaterial.transparency = 0
        hoverMaterial.diffuse.contents = NSColor.clear
        overlay.materials = [hoverMaterial]
        let hoverNode = SCNNode(geometry: overlay)
        hoverNode.position.z = 0.02
        content.addChildNode(hoverNode)
    }

    required init?(coder: NSCoder) { fatalError() }

    func apply(_ tex: CardTextures) {
        material.diffuse.contents = tex.diffuse
        material.emission.contents = tex.emission
        hoverMaterial.diffuse.contents = tex.hover
    }

    /// Прозрачность от температуры и поискового фильтра. t — °C, melt/boil в данных — кельвины.
    func applyVisual(celsius: Double, query: String) {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        let ru = RussianNames.name(element.number).lowercased()
        let match = q.isEmpty || ru.contains(q) || element.name.lowercased().contains(q)
            || element.symbol.lowercased().contains(q) || String(element.number) == q
        let kelvin = celsius + 273.15
        let melt = element.melt ?? .greatestFiniteMagnitude
        let boil = element.boil ?? .greatestFiniteMagnitude
        var alpha: CGFloat = 1
        if kelvin >= boil { alpha = 0.28 }
        else if kelvin >= melt { alpha = 0.62 }
        if !match { alpha = 0.08 }
        material.transparency = alpha
        material.diffuse.intensity = kelvin >= melt && kelvin < boil ? 0.75 : 1
    }

    // MARK: Интерактив

    func setHover(_ on: Bool) {
        guard on != isHovered else { return }
        isHovered = on
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        content.scale = on ? SCNVector3(1.08, 1.08, 1.08) : SCNVector3(1, 1, 1)
        content.position.z = on ? 0.4 : 0
        material.emission.intensity = on ? 2.5 : 1.0
        hoverMaterial.transparency = on ? 1 : 0
        SCNTransaction.commit()
    }

    /// Флип на 180° по Y. После завершения карточка возвращается в исходное состояние.
    func flip(completion: @escaping () -> Void) {
        let flip = SCNAction.rotateBy(x: 0, y: .pi, z: 0, duration: 0.45)
        flip.timingMode = .easeInEaseOut
        let pop = SCNAction.scale(to: 1.6, duration: 0.45)
        content.runAction(.group([flip, pop])) { [weak self] in
            DispatchQueue.main.async {
                completion()
                self?.content.eulerAngles.y = 0
                self?.content.scale = SCNVector3(1, 1, 1)
                self?.isHovered = false
                self?.setHover(false)
            }
        }
    }

    // MARK: Генерация текстур (фон)

    static let pixelSize = CGSize(width: 300, height: 360)

    static func renderTextures(_ specs: [CardSpec]) async -> [Int: CardTextures] {
        await withTaskGroup(of: (Int, CardTextures?).self) { group in
            for s in specs { group.addTask(priority: .userInitiated) { (s.number, render(s)) } }
            var out: [Int: CardTextures] = [:]
            for await (n, t) in group { if let t { out[n] = t } }
            return out
        }
    }

    private static func makeContext() -> CGContext? {
        CGContext(data: nil, width: Int(pixelSize.width), height: Int(pixelSize.height), bitsPerComponent: 8,
                  bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    }

    static func render(_ s: CardSpec) -> CardTextures? {
        guard let ctx = makeContext(), let glowCtx = makeContext() else { return nil }
        let W = pixelSize.width, H = pixelSize.height
        let inset: CGFloat = 14
        let rect = CGRect(x: inset, y: inset, width: W - 2 * inset, height: H - 2 * inset)
        let path = CGPath(roundedRect: rect, cornerWidth: 22, cornerHeight: 22, transform: nil)
        let neon = s.color.ns

        // Стекло: вертикальный градиент тёмного полупрозрачного фона.
        ctx.saveGState()
        ctx.addPath(path); ctx.clip()
        let grad = CGGradient(colorsSpace: nil, colors: [
            NSColor(srgbRed: 0.10, green: 0.11, blue: 0.16, alpha: 0.78).cgColor,
            NSColor(srgbRed: 0.03, green: 0.03, blue: 0.06, alpha: 0.70).cgColor,
        ] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: H), end: .zero, options: [])
        // Лёгкий цветной отлив категории.
        ctx.setFillColor(neon.withAlphaComponent(0.08).cgColor)
        ctx.fill(rect)
        // Шум «матового стекла»: детерминированные точки.
        var rng = SplitMix64(seed: UInt64(s.number) &* 7919)
        for _ in 0..<900 {
            let a = CGFloat(rng.unit()) * 0.07
            ctx.setFillColor(NSColor(white: 1, alpha: a).cgColor)
            ctx.fill(CGRect(x: CGFloat(rng.unit()) * W, y: CGFloat(rng.unit()) * H, width: 1.5, height: 1.5))
        }
        // Блик в верхней части.
        ctx.setFillColor(NSColor(white: 1, alpha: 0.05).cgColor)
        ctx.fill(CGRect(x: rect.minX, y: rect.midY + 40, width: rect.width, height: rect.height / 2))
        ctx.restoreGState()

        // Неоновая обводка с размытием-свечением (рисуется в оба контекста).
        for c in [ctx, glowCtx] {
            c.saveGState()
            c.setShadow(offset: .zero, blur: 14, color: neon.cgColor)
            c.setStrokeColor(neon.cgColor)
            c.setLineWidth(4)
            c.addPath(path); c.strokePath()
            c.restoreGState()
        }

        // Текст.
        let ns = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ns
        func draw(_ str: String, font: NSFont, color: NSColor, at p: CGPoint, center: Bool = false, glow: Bool = false) {
            let shadow = NSShadow()
            shadow.shadowBlurRadius = glow ? 12 : 0
            shadow.shadowColor = neon
            var attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
            if glow { attrs[.shadow] = shadow }
            let a = NSAttributedString(string: str, attributes: attrs)
            let sz = a.size()
            a.draw(at: CGPoint(x: center ? p.x - sz.width / 2 : p.x, y: p.y))
        }
        draw("\(s.number)", font: .monospacedSystemFont(ofSize: 30, weight: .medium), color: neon, at: CGPoint(x: 34, y: H - 76))
        draw(s.symbol, font: .systemFont(ofSize: 120, weight: .heavy), color: .white, at: CGPoint(x: W / 2, y: H / 2 - 62), center: true, glow: true)
        var name = s.name
        if name.count > 13 { name = String(name.prefix(12)) + "." }
        var title = s.name
        if title.count > 14 { title = String(title.prefix(13)) + "." }
        draw(title, font: .monospacedSystemFont(ofSize: 20, weight: .medium), color: NSColor(white: 0.88, alpha: 1), at: CGPoint(x: W / 2, y: 42), center: true)
        NSGraphicsContext.restoreGraphicsState()

        guard let d = ctx.makeImage(), let e = glowCtx.makeImage(), let h = Self.hoverImage(s) else { return nil }
        return CardTextures(diffuse: d, emission: e, hover: h)
    }

    /// Слой, который проявляется при наведении: масса и знак фазы.
    private static func hoverImage(_ s: CardSpec) -> CGImage? {
        guard let ctx = makeContext() else { return nil }
        let W = pixelSize.width, H = pixelSize.height
        let ns = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ns
        let text = NSAttributedString(string: String(format: "%.3f", s.mass), attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 22, weight: .semibold),
            .foregroundColor: NSColor.white,
        ])
        let sz = text.size()
        text.draw(at: CGPoint(x: W / 2 - sz.width / 2 - 16, y: 78))
        let phase = phaseGlyph(s.phase)
        let g = NSAttributedString(string: phase, attributes: [
            .font: NSFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: s.color.ns,
        ])
        g.draw(at: CGPoint(x: W / 2 + sz.width / 2 - 4, y: 78))
        NSGraphicsContext.restoreGraphicsState()
        return ctx.makeImage()
    }

    /// Твёрдое ■, жидкость ●, газ ≈ — агрегатное состояние при 20 °C.
    private static func phaseGlyph(_ phase: String?) -> String {
        switch phase?.lowercased() {
        case "gas": "≈"
        case "liquid": "●"
        default: "■"
        }
    }
}
