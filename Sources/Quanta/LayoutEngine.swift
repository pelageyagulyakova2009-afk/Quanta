import SceneKit
import simd

enum LayoutMode: String, CaseIterable, Identifiable {
    case table = "Table", sphere = "Sphere", helix = "Helix", grid = "Grid"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .table: "tablecells"
        case .sphere: "globe"
        case .helix: "tornado"
        case .grid: "cube.transparent"
        }
    }
}

/// Целевое положение карточки в раскладке.
struct CardTransform: Sendable {
    var position: SIMD3<Float>
    var euler: SIMD3<Float> = .zero
}

/// Минимальная информация об элементе для расчётов в фоне (Sendable).
struct LayoutInput: Sendable {
    let number: Int
    let xpos: Int
    let ypos: Int
}

enum LayoutEngine {
    static let spacingX: Float = 1.15
    static let spacingY: Float = 1.40

    /// Расчёт выполняется вне главного потока.
    static func compute(_ mode: LayoutMode, inputs: [LayoutInput]) async -> [CardTransform] {
        await Task.detached(priority: .userInitiated) {
            switch mode {
            case .table: table(inputs)
            case .sphere: sphere(inputs)
            case .helix: helix(inputs)
            case .grid: grid(inputs)
            }
        }.value
    }

    // MARK: Table

    /// Классическая таблица: xpos ∈ [1…18], ypos ∈ [1…10] (9 и 10 — лантаноиды/актиноиды).
    /// Центрируем: x = (xpos − 9.5)·Δx, y = −(ypos − 5.5)·Δy. Ряды f-элементов
    /// дополнительно сдвигаем вниз на полкарточки, чтобы визуально отделить их.
    static func table(_ inputs: [LayoutInput]) -> [CardTransform] {
        inputs.map { e in
            let gap: Float = e.ypos >= 9 ? 0.5 : 0
            let x = (Float(e.xpos) - 9.5) * spacingX
            let y = -(Float(e.ypos) - 5.5) * spacingY - gap
            return CardTransform(position: [x, y, 0])
        }
    }

    // MARK: Helix

    /// Цилиндрическая спираль.
    /// θ = n · (2π / N) · витки — равномерный шаг угла на элемент;
    /// x = R·sin θ, z = R·cos θ — точка на окружности радиуса R;
    /// y = n·h − H/2 — линейный подъём вдоль оси, центрированный относительно нуля.
    /// Поворот карточки eulerAngles.y = θ разворачивает её «лицом» наружу от оси.
    static func helix(_ inputs: [LayoutInput]) -> [CardTransform] {
        let n = Float(inputs.count)
        let turns: Float = 4
        let radius: Float = 7
        let rise: Float = 0.11
        return inputs.map { e in
            let i = Float(e.number - 1)
            let theta = i * (2 * .pi / n) * turns
            let x = radius * sin(theta)
            let z = radius * cos(theta)
            let y = i * rise - n * rise / 2
            return CardTransform(position: [x, y, z], euler: [0, theta, 0])
        }
    }

    // MARK: Sphere

    /// Сфера Фибоначчи — квазиравномерное распределение N точек.
    /// yᵢ = 1 − 2(i + 0.5)/N — равномерные «широты» от +1 до −1 (равные площади поясов, теорема Архимеда);
    /// rᵢ = √(1 − yᵢ²) — радиус сечения сферы на этой высоте;
    /// φᵢ = i · π(3 − √5) — золотой угол (~137.5°), исключающий выравнивание точек в «меридианы».
    /// Ориентация задаётся SCNBillboardConstraint в SceneManager.
    static func sphere(_ inputs: [LayoutInput]) -> [CardTransform] {
        let n = Float(inputs.count)
        let radius: Float = 6.5
        let golden = Float.pi * (3 - sqrt(5))
        return inputs.map { e in
            let i = Float(e.number - 1)
            let y = 1 - 2 * (i + 0.5) / n
            let r = sqrt(max(0, 1 - y * y))
            let phi = i * golden
            return CardTransform(position: [cos(phi) * r * radius, y * radius, sin(phi) * r * radius])
        }
    }

    // MARK: Grid

    /// Свободное облако: детерминированные псевдослучайные точки внутри куба со стороной 2·half.
    /// Используется генератор SplitMix64 с фиксированным зерном — раскладка стабильна между переключениями.
    static func grid(_ inputs: [LayoutInput]) -> [CardTransform] {
        var rng = SplitMix64(seed: 0x51A7A)
        let half: Float = 7
        return inputs.map { _ in
            let p = SIMD3<Float>(rng.unit() * 2 - 1, rng.unit() * 2 - 1, rng.unit() * 2 - 1) * half
            let tilt = SIMD3<Float>(rng.unit() - 0.5, rng.unit() - 0.5, rng.unit() - 0.5) * 0.6
            return CardTransform(position: p, euler: tilt)
        }
    }

    /// Промежуточный «взрыв»: каждая карточка отлетает от центра по своему направлению,
    /// как частица при распаде. p' = p·k + случайный импульс.
    static func scatter(from current: [SIMD3<Float>]) -> [CardTransform] {
        var rng = SplitMix64(seed: UInt64(Date().timeIntervalSince1970))
        return current.map { p in
            let impulse = SIMD3<Float>(rng.unit() - 0.5, rng.unit() - 0.5, rng.unit() - 0.5) * 6
            return CardTransform(position: p * 1.6 + impulse,
                                 euler: SIMD3<Float>(rng.unit(), rng.unit(), rng.unit()) * .pi)
        }
    }

    // MARK: Анимация переходов

    /// Пружинная кривая: кубическая Безье с control point y > 1 даёт «перелёт» (overshoot)
    /// и мягкое возвращение, имитируя затухающую пружину.
    static let springTiming = CAMediaTimingFunction(controlPoints: 0.34, 1.36, 0.44, 1.0)

    /// Применяет трансформы к узлам. Задержка stagger = i·step создаёт «волну» перестроения.
    @MainActor
    static func apply(_ transforms: [CardTransform], to nodes: [SCNNode], duration: TimeInterval = 0.9,
                      stagger: TimeInterval = 0.012, timing: CAMediaTimingFunction = springTiming) {
        for (i, node) in nodes.enumerated() where i < transforms.count {
            let t = transforms[i]
            let move = SCNAction.group([
                .move(to: SCNVector3(t.position), duration: duration),
                .rotateTo(x: CGFloat(t.euler.x), y: CGFloat(t.euler.y), z: CGFloat(t.euler.z),
                          duration: duration, usesShortestUnitArc: true),
            ])
            move.timingFunction = { time in
                Float(timing.value(at: Double(time)))
            }
            node.removeAction(forKey: "layout")
            node.runAction(.sequence([.wait(duration: Double(i) * stagger), move]), forKey: "layout")
        }
    }
}

// MARK: - Утилиты

struct SplitMix64 {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func unit() -> Float { Float(next() >> 40) / Float(1 << 24) }
}

extension CAMediaTimingFunction {
    /// Значение кривой y(t). Решаем x(s) = t методом Ньютона, затем считаем y(s).
    func value(at t: Double) -> Double {
        var c1: [Float] = [0, 0], c2: [Float] = [0, 0]
        getControlPoint(at: 1, values: &c1)
        getControlPoint(at: 2, values: &c2)
        let (x1, y1, x2, y2) = (Double(c1[0]), Double(c1[1]), Double(c2[0]), Double(c2[1]))
        func bez(_ s: Double, _ a: Double, _ b: Double) -> Double {
            let u = 1 - s
            return 3 * u * u * s * a + 3 * u * s * s * b + s * s * s
        }
        func dbez(_ s: Double, _ a: Double, _ b: Double) -> Double {
            let u = 1 - s
            return 3 * u * u * a + 6 * u * s * (b - a) + 3 * s * s * (1 - b)
        }
        var s = t
        for _ in 0..<6 {
            let d = dbez(s, x1, x2)
            if abs(d) < 1e-6 { break }
            s -= (bez(s, x1, x2) - t) / d
            s = min(max(s, 0), 1)
        }
        return bez(s, y1, y2)
    }
}
