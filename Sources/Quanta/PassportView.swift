import Charts
import SceneKit
import SwiftUI

// MARK: - Размытый фон

struct VisualEffectBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .hudWindow
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Паспорт

struct PassportView: View {
    let element: ChemicalElement
    let allElements: [ChemicalElement]
    let onClose: () -> Void

    @State private var appear = false
    private var accent: Color { element.elementCategory.color }

    var body: some View {
        ZStack {
            VisualEffectBlur().ignoresSafeArea()
            Color.black.opacity(0.55).ignoresSafeArea()
            ScanLines().opacity(0.06).ignoresSafeArea().allowsHitTesting(false)

            HStack(alignment: .top, spacing: 28) {
                leftColumn.frame(maxWidth: 460)
                ScrollView { rightColumn }.scrollIndicators(.never)
            }
            .padding(36)
            .frame(maxWidth: 1280, maxHeight: 820)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color.black.opacity(0.35)))
            .overlay(HUDFrame(color: accent))
            .overlay(alignment: .topTrailing) { closeButton.padding(18) }
            .scaleEffect(appear ? 1 : 0.92)
            .opacity(appear ? 1 : 0)
            .padding(40)
        }
        .preferredColorScheme(.dark)
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { appear = true } }
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .bold))
                .frame(width: 38, height: 38)
                .foregroundStyle(accent)
                .overlay(Circle().stroke(accent, lineWidth: 1.5))
                .shadow(color: accent, radius: 8)
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.cancelAction)
    }

    // MARK: Левая колонка

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("ЭЛЕКТРОННЫЙ ПАСПОРТ · #\(String(format: "%03d", element.number))")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(accent.opacity(0.8))
            BohrAtomView(element: element)
                .frame(height: 400)
                .background(RadialGradient(colors: [accent.opacity(0.18), .clear], center: .center, startRadius: 10, endRadius: 220))
                .overlay(HUDFrame(color: accent.opacity(0.5), corner: 14))
            HStack(alignment: .lastTextBaseline, spacing: 16) {
                Text(element.symbol)
                    .font(.system(size: 96, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: accent, radius: 18)
                VStack(alignment: .leading, spacing: 4) {
                    Text(element.name.uppercased())
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                    Text(element.elementCategory.title)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(accent)
                }
            }
            if let summary = element.summary {
                Text(summary)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(5)
            }
        }
    }

    // MARK: Правая колонка

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            section("БАЗОВЫЕ ДАННЫЕ") {
                row("Атомный номер", "\(element.number)")
                row("Атомная масса", String(format: "%.4f а.е.м.", element.atomicMass))
                row("Категория", element.elementCategory.title)
                row("Период / группа", "\(element.period) / \(element.group)")
                row("Год открытия", element.extra.year)
                row("Первооткрыватель", element.discoveredBy ?? "—")
            }
            section("ФИЗИЧЕСКИЕ СВОЙСТВА") {
                row("Плотность", element.density.map { String(format: "%.4g г/см³", $0) } ?? "—")
                row("Т. плавления", element.melt.map { String(format: "%.1f K (%.1f °C)", $0, $0 - 273.15) } ?? "—")
                row("Т. кипения", element.boil.map { String(format: "%.1f K (%.1f °C)", $0, $0 - 273.15) } ?? "—")
                row("Состояние при 20 °C", phaseTitle)
            }
            section("АТОМНЫЕ СВОЙСТВА") {
                row("Электронная конфигурация", element.electronConfigurationSemantic ?? element.electronConfiguration ?? "—")
                row("Электроотрицательность", element.electronegativityPauling.map { String(format: "%.2f (Полинг)", $0) } ?? "—")
                row("Радиус атома", element.atomicRadii?.best.map { String(format: "%.0f пм", $0) } ?? "—")
                row("Степени окисления", element.extra.oxidationStates)
                row("Электронные оболочки", element.shells.map(String.init).joined(separator: " · "))
            }
            section("КРИСТАЛЛИЧЕСКАЯ РЕШЁТКА") {
                HStack(spacing: 18) {
                    LatticeView(type: element.extra.lattice, color: accent)
                        .frame(width: 120, height: 120)
                    Text(element.extra.lattice.title)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                }
            }
            section("ТРЕНДЫ ПО АТОМНОМУ НОМЕРУ") {
                HStack(spacing: 14) {
                    Sparkline(title: "Т. кипения, K", values: allElements.map { ($0.number, $0.boil) }, current: element.number, color: accent)
                    Sparkline(title: "Плотность", values: allElements.map { ($0.number, $0.density) }, current: element.number, color: accent)
                    Sparkline(title: "Электроотриц.", values: allElements.map { ($0.number, $0.electronegativityPauling) }, current: element.number, color: accent)
                }
            }
        }
        .padding(.trailing, 40)
    }

    private var phaseTitle: String {
        switch element.phase?.lowercased() {
        case "solid": "Твёрдое"
        case "liquid": "Жидкое"
        case "gas": "Газ"
        default: element.phase ?? "—"
        }
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Rectangle().fill(accent).frame(width: 3, height: 14).shadow(color: accent, radius: 4)
                Text(title).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(accent)
                Rectangle().fill(accent.opacity(0.25)).frame(height: 1)
            }
            content()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.2), lineWidth: 1))
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(k).foregroundStyle(.white.opacity(0.55))
            Spacer(minLength: 16)
            Text(v).foregroundStyle(.white).multilineTextAlignment(.trailing).textSelection(.enabled)
        }
        .font(.system(size: 13, design: .monospaced))
    }
}

// MARK: - Модель Бора

struct BohrAtomView: View {
    let element: ChemicalElement
    @State private var scene: SCNScene?

    var body: some View {
        SceneView(scene: scene, options: [.allowsCameraControl, .autoenablesDefaultLighting])
            .onAppear { scene = Self.makeScene(element) }
    }

    static func makeScene(_ e: ChemicalElement) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = NSColor.clear
        let accent = e.elementCategory.nsColor

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera!.wantsHDR = true
        camera.camera!.bloomIntensity = 1.2
        camera.position = SCNVector3(0, 3, 15)
        camera.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(camera)

        // Ядро: протоны и нейтроны, упакованные в «шарик» по спирали Фибоначчи
        // с радиусом r ∝ ∛(i) — так плотность частиц внутри примерно постоянна.
        let nucleus = SCNNode()
        let neutrons = max(0, Int(e.atomicMass.rounded()) - e.number)
        let count = min(e.number + neutrons, 60)
        let golden = Float.pi * (3 - sqrt(5))
        let protonGeo = SCNSphere(radius: 0.22)
        protonGeo.firstMaterial?.diffuse.contents = NSColor.systemRed
        protonGeo.firstMaterial?.emission.contents = NSColor.systemRed.withAlphaComponent(0.4)
        let neutronGeo = SCNSphere(radius: 0.22)
        neutronGeo.firstMaterial?.diffuse.contents = NSColor(white: 0.8, alpha: 1)
        for i in 0..<count {
            let fi = Float(i)
            let r = 0.32 * cbrt(fi + 1)
            let y = 1 - 2 * (fi + 0.5) / Float(count)
            let rr = sqrt(max(0, 1 - y * y))
            let n = SCNNode(geometry: i % 2 == 0 ? protonGeo : neutronGeo)
            n.position = SCNVector3(cos(fi * golden) * rr * r, y * r, sin(fi * golden) * rr * r)
            nucleus.addChildNode(n)
        }
        nucleus.runAction(.repeatForever(.rotateBy(x: 0.5, y: 1, z: 0, duration: 6)))
        scene.rootNode.addChildNode(nucleus)

        // Оболочки: радиус растёт линейно, каждая наклонена по-своему для объёма.
        let electronGeo = SCNSphere(radius: 0.12)
        electronGeo.firstMaterial?.diffuse.contents = accent
        electronGeo.firstMaterial?.emission.contents = accent
        for (s, electrons) in e.shells.enumerated() {
            let radius = CGFloat(2.0 + Double(s) * 0.85)
            let orbit = SCNNode()
            orbit.eulerAngles = SCNVector3(CGFloat(s) * 0.35, 0, CGFloat(s) * 0.22)
            let torus = SCNTorus(ringRadius: radius, pipeRadius: 0.012)
            torus.firstMaterial?.diffuse.contents = accent.withAlphaComponent(0.4)
            torus.firstMaterial?.emission.contents = accent.withAlphaComponent(0.5)
            orbit.addChildNode(SCNNode(geometry: torus))

            // Электроны равномерно по окружности: угол αⱼ = 2πj / nₛ.
            let pivot = SCNNode()
            for j in 0..<electrons {
                let a = CGFloat(j) / CGFloat(electrons) * 2 * .pi
                let el = SCNNode(geometry: electronGeo)
                el.position = SCNVector3(cos(a) * radius, 0, sin(a) * radius)
                pivot.addChildNode(el)
            }
            // Внешние оболочки вращаются медленнее (как ~ r^1.5, по аналогии с законом Кеплера).
            let period = 2.5 * pow(Double(radius) / 2.0, 1.5)
            pivot.runAction(.repeatForever(.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: period)))
            orbit.addChildNode(pivot)
            scene.rootNode.addChildNode(orbit)
        }
        return scene
    }
}

// MARK: - Мини-схема решётки

struct LatticeView: View {
    let type: LatticeType
    let color: Color

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height)
            // Косоугольная (кабинетная) проекция куба: z-смещение = (0.35·a, 0.35·a).
            func p(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat) -> CGPoint {
                CGPoint(x: s * (0.15 + x * 0.55 + z * 0.25), y: s * (0.85 - y * 0.55 - z * 0.25))
            }
            var edges = Path()
            var atoms: [CGPoint] = []
            let hex = [LatticeType.hcp, .hexagonal].contains(type)
            if hex {
                // Шестигранная призма: вершины на окружности, угол 60°·k.
                func h(_ k: Int, _ y: CGFloat) -> CGPoint {
                    let a = CGFloat(k) * .pi / 3
                    return CGPoint(x: s * (0.5 + 0.38 * cos(a)), y: s * (0.5 + 0.16 * sin(a)) + (y == 0 ? s * 0.22 : -s * 0.22))
                }
                for y in [CGFloat(0), 1] {
                    for k in 0..<6 { edges.move(to: h(k, y)); edges.addLine(to: h(k + 1, y)); atoms.append(h(k, y)) }
                    atoms.append(CGPoint(x: s * 0.5, y: s * 0.5 + (y == 0 ? s * 0.22 : -s * 0.22)))
                }
                for k in 0..<6 { edges.move(to: h(k, 0)); edges.addLine(to: h(k, 1)) }
                if type == .hcp { for k in [0, 2, 4] { atoms.append(CGPoint(x: s * (0.5 + 0.2 * cos(CGFloat(k) * .pi / 3 + 0.5)), y: s * 0.5)) } }
            } else {
                let c: [CGFloat] = [0, 1]
                for x in c { for y in c { for z in c {
                    atoms.append(p(x, y, z))
                    if x == 0 { edges.move(to: p(0, y, z)); edges.addLine(to: p(1, y, z)) }
                    if y == 0 { edges.move(to: p(x, 0, z)); edges.addLine(to: p(x, 1, z)) }
                    if z == 0 { edges.move(to: p(x, y, 0)); edges.addLine(to: p(x, y, 1)) }
                } } }
                switch type {
                case .bcc: atoms.append(p(0.5, 0.5, 0.5))
                case .fcc: atoms += [p(0.5, 0.5, 0), p(0.5, 0.5, 1), p(0.5, 0, 0.5), p(0.5, 1, 0.5), p(0, 0.5, 0.5), p(1, 0.5, 0.5)]
                case .diamond: atoms += [p(0.5, 0.5, 0), p(0.5, 0, 0.5), p(0, 0.5, 0.5), p(0.25, 0.25, 0.25), p(0.75, 0.75, 0.25), p(0.75, 0.25, 0.75), p(0.25, 0.75, 0.75)]
                default: break
                }
            }
            ctx.stroke(edges, with: .color(color.opacity(0.6)), lineWidth: 1)
            for a in atoms {
                ctx.fill(Path(ellipseIn: CGRect(x: a.x - 5, y: a.y - 5, width: 10, height: 10)), with: .color(color))
            }
        }
        .shadow(color: color.opacity(0.8), radius: 6)
    }
}

// MARK: - Спарклайн

struct Sparkline: View {
    let title: String
    let values: [(Int, Double?)]
    let current: Int
    let color: Color

    var body: some View {
        let points = values.compactMap { n, v in v.map { (n, $0) } }
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 10, weight: .semibold, design: .monospaced)).foregroundStyle(.white.opacity(0.6))
            Chart {
                ForEach(points, id: \.0) { p in
                    LineMark(x: .value("Z", p.0), y: .value("v", p.1))
                        .foregroundStyle(color.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 1.2))
                }
                if let c = points.first(where: { $0.0 == current }) {
                    PointMark(x: .value("Z", c.0), y: .value("v", c.1))
                        .foregroundStyle(.white)
                        .symbolSize(40)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 60)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.03)))
    }
}

// MARK: - HUD-декор

struct HUDFrame: View {
    var color: Color
    var corner: CGFloat = 24

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height, l: CGFloat = 36
            ZStack {
                RoundedRectangle(cornerRadius: corner).stroke(color.opacity(0.3), lineWidth: 1)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: l)); p.addLine(to: .zero); p.addLine(to: CGPoint(x: l, y: 0))
                    p.move(to: CGPoint(x: w - l, y: 0)); p.addLine(to: CGPoint(x: w, y: 0)); p.addLine(to: CGPoint(x: w, y: l))
                    p.move(to: CGPoint(x: w, y: h - l)); p.addLine(to: CGPoint(x: w, y: h)); p.addLine(to: CGPoint(x: w - l, y: h))
                    p.move(to: CGPoint(x: l, y: h)); p.addLine(to: CGPoint(x: 0, y: h)); p.addLine(to: CGPoint(x: 0, y: h - l))
                }
                .stroke(color, lineWidth: 2.5)
                .shadow(color: color, radius: 6)
            }
        }
        .allowsHitTesting(false)
    }
}

struct ScanLines: View {
    var body: some View {
        Canvas { ctx, size in
            var y: CGFloat = 0
            while y < size.height {
                ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.white))
                y += 3
            }
        }
    }
}
