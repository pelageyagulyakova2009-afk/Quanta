import AppKit
import SwiftUI

// MARK: - Модель элемента

struct AtomicRadii: Codable, Hashable {
    let empirical: [Double]?
    let calculated: [Double]?
    let covalent_single: [Double]?
    let metallic: [Double]?

    var best: Double? { empirical?.first ?? calculated?.first ?? metallic?.first ?? covalent_single?.first }
}

struct ChemicalElement: Codable, Identifiable, Hashable {
    let name: String
    let number: Int
    let symbol: String
    let atomicMass: Double
    let category: String
    let period: Int
    let group: Int
    let xpos: Int
    let ypos: Int
    let phase: String?
    let density: Double?
    let melt: Double?
    let boil: Double?
    let discoveredBy: String?
    let summary: String?
    let shells: [Int]
    let electronConfiguration: String?
    let electronConfigurationSemantic: String?
    let electronegativityPauling: Double?
    let atomicRadii: AtomicRadii?
    let block: String?

    var id: Int { number }

    enum CodingKeys: String, CodingKey {
        case name, number, symbol, category, period, group, xpos, ypos, phase, density, melt, boil, summary, shells, block
        case atomicMass = "atomic_mass"
        case discoveredBy = "discovered_by"
        case electronConfiguration = "electron_configuration"
        case electronConfigurationSemantic = "electron_configuration_semantic"
        case electronegativityPauling = "electronegativity_pauling"
        case atomicRadii = "atomic_radii"
    }

    var elementCategory: ElementCategory { ElementCategory(raw: category, group: group, number: number) }
    var extra: ElementExtras { ElementExtras.forNumber(number) }
}

private struct ElementsFile: Codable { let elements: [ChemicalElement] }

// MARK: - Категории и неоновые цвета

enum ElementCategory: String, CaseIterable {
    case alkaliMetal, alkalineEarth, transitionMetal, postTransition, metalloid
    case nonmetal, halogen, nobleGas, lanthanide, actinide, unknown

    init(raw: String, group: Int, number: Int) {
        let r = raw.lowercased()
        if group == 17 && number != 117 { self = .halogen; return }
        if r.contains("unknown") { self = .unknown }
        else if r.contains("alkali metal") { self = .alkaliMetal }
        else if r.contains("alkaline") { self = .alkalineEarth }
        else if r.contains("post-transition") { self = .postTransition }
        else if r.contains("transition") { self = .transitionMetal }
        else if r.contains("metalloid") { self = .metalloid }
        else if r.contains("noble") { self = .nobleGas }
        else if r.contains("lanthanide") { self = .lanthanide }
        else if r.contains("actinide") { self = .actinide }
        else if r.contains("nonmetal") { self = .nonmetal }
        else { self = .unknown }
    }

    var title: String {
        switch self {
        case .alkaliMetal: "Щелочной металл"
        case .alkalineEarth: "Щёлочноземельный металл"
        case .transitionMetal: "Переходный металл"
        case .postTransition: "Постпереходный металл"
        case .metalloid: "Полуметалл"
        case .nonmetal: "Неметалл"
        case .halogen: "Галоген"
        case .nobleGas: "Благородный газ"
        case .lanthanide: "Лантаноид"
        case .actinide: "Актиноид"
        case .unknown: "Неизвестно"
        }
    }

    var nsColor: NSColor {
        switch self {
        case .alkaliMetal: NSColor(red: 0.20, green: 1.00, blue: 0.45, alpha: 1)
        case .alkalineEarth: NSColor(red: 1.00, green: 0.85, blue: 0.20, alpha: 1)
        case .transitionMetal: NSColor(red: 0.20, green: 0.60, blue: 1.00, alpha: 1)
        case .postTransition: NSColor(red: 0.30, green: 0.95, blue: 0.95, alpha: 1)
        case .metalloid: NSColor(red: 0.95, green: 0.55, blue: 0.15, alpha: 1)
        case .nonmetal: NSColor(red: 0.55, green: 1.00, blue: 0.85, alpha: 1)
        case .halogen: NSColor(red: 1.00, green: 0.20, blue: 0.30, alpha: 1)
        case .nobleGas: NSColor(red: 0.72, green: 0.35, blue: 1.00, alpha: 1)
        case .lanthanide: NSColor(red: 1.00, green: 0.35, blue: 0.80, alpha: 1)
        case .actinide: NSColor(red: 1.00, green: 0.50, blue: 0.50, alpha: 1)
        case .unknown: NSColor(red: 0.65, green: 0.65, blue: 0.70, alpha: 1)
        }
    }

    var color: Color { Color(nsColor: nsColor) }
}

// MARK: - Дополнительные данные (их нет в исходном JSON)

enum LatticeType: Character {
    case fcc = "c", bcc = "b", hcp = "h", diamond = "d", orthorhombic = "o"
    case rhombohedral = "r", hexagonal = "x", monoclinic = "m", tetragonal = "t", simpleCubic = "s", unknown = "-"

    var title: String {
        switch self {
        case .fcc: "ГЦК (гранецентрированная кубическая)"
        case .bcc: "ОЦК (объёмноцентрированная кубическая)"
        case .hcp: "ГПУ (гексагональная плотноупакованная)"
        case .diamond: "Алмазная кубическая"
        case .orthorhombic: "Ромбическая"
        case .rhombohedral: "Ромбоэдрическая"
        case .hexagonal: "Гексагональная"
        case .monoclinic: "Моноклинная"
        case .tetragonal: "Тетрагональная"
        case .simpleCubic: "Простая кубическая"
        case .unknown: "Неизвестна"
        }
    }
}

struct ElementExtras {
    let year: String
    let oxidationStates: String
    let lattice: LatticeType

    // Годы открытия; 0 — известен с древности.
    private static let years: [Int] = [
        1766, 1868, 1817, 1798, 1808, 0, 1772, 1774, 1886, 1898, 1807, 1755, 1825, 1824, 1669, 0, 1774, 1894,
        1807, 1808, 1879, 1791, 1801, 1797, 1774, 0, 1735, 1751, 0, 1746, 1875, 1886, 1250, 1817, 1826, 1898,
        1861, 1790, 1794, 1789, 1801, 1778, 1937, 1844, 1804, 1802, 0, 1817, 1863, 0, 0, 1782, 1811, 1898,
        1860, 1808, 1839, 1803, 1885, 1885, 1945, 1879, 1901, 1880, 1843, 1886, 1878, 1843, 1879, 1878, 1907,
        1923, 1802, 1783, 1925, 1803, 1803, 1735, 0, 0, 1861, 0, 1753, 1898, 1940, 1899,
        1939, 1898, 1899, 1829, 1913, 1789, 1940, 1940, 1944, 1944, 1949, 1950, 1952, 1952, 1955, 1966, 1961,
        1964, 1967, 1974, 1981, 1984, 1982, 1994, 1994, 1996, 2004, 1999, 2003, 2000, 2010, 2002,
    ]

    private static let oxidation: [String] = [
        "+1, −1", "0", "+1", "+2", "+3", "+4, +2, −4", "−3, +3, +5", "−2", "−1", "0",
        "+1", "+2", "+3", "+4, −4", "+5, +3, −3", "+6, +4, −2", "−1, +1, +5, +7", "0",
        "+1", "+2", "+3", "+4", "+5", "+3, +6", "+2, +4, +7", "+2, +3", "+2, +3", "+2", "+1, +2", "+2",
        "+3", "+4, −4", "+5, +3, −3", "+6, +4, −2", "−1, +1, +5", "+2",
        "+1", "+2", "+3", "+4", "+5", "+4, +6", "+4, +7", "+3, +4", "+3", "+2, +4", "+1", "+2",
        "+3", "+2, +4", "+3, +5, −3", "+6, +4, −2", "−1, +1, +5, +7", "+2, +4, +6",
        "+1", "+2", "+3", "+3, +4", "+3", "+3", "+3", "+3", "+2, +3", "+3", "+3", "+3", "+3", "+3", "+3", "+2, +3", "+3",
        "+4", "+5", "+4, +6", "+4, +7", "+4", "+3, +4", "+2, +4", "+1, +3", "+1, +2",
        "+1, +3", "+2, +4", "+3", "+2, +4", "−1, +1", "+2",
        "+1", "+2", "+3", "+4", "+5", "+6", "+5", "+4", "+3", "+3", "+3", "+3", "+3", "+3", "+3", "+2", "+3",
        "+4", "+5", "+6", "+7", "+8",
    ]

    private static let lattices = Array(
        "hhbhrxxmmcbhcdoooocbchhbbbbhcchodrxocbchhbbhhccchttrxocbbxcxxxrbhhhhhhchhbbhhcccrhcrs-cbbctoomxxxxc"
    )

    static func forNumber(_ n: Int) -> ElementExtras {
        let i = n - 1
        let y = i < years.count ? years[i] : -1
        let yearText = y == 0 ? "Древность" : (y < 0 ? "—" : String(y))
        let ox = i < oxidation.count ? oxidation[i] : "—"
        let lat = i < lattices.count ? (LatticeType(rawValue: lattices[i]) ?? .unknown) : .unknown
        return ElementExtras(year: yearText, oxidationStates: ox, lattice: lat)
    }
}

// MARK: - Хранилище с кэшем

@MainActor
final class ElementStore: ObservableObject {
    static let shared = ElementStore()
    static let remoteURL = URL(string: "https://raw.githubusercontent.com/Bowserinator/Periodic-Table-JSON/master/PeriodicTableJSON.json")!

    @Published private(set) var elements: [ChemicalElement] = []

    nonisolated private static var cacheURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("Quanta", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("elements.json")
    }

    private init() {
        // Синхронная загрузка: кэш → ресурс бандла. Виджет стартует мгновенно, без сети.
        elements = Self.decode(try? Data(contentsOf: Self.cacheURL))
            ?? Self.decode(Bundle.module.url(forResource: "PeriodicTableJSON", withExtension: "json").flatMap { try? Data(contentsOf: $0) })
            ?? []
        refreshInBackground()
    }

    nonisolated static func decode(_ data: Data?) -> [ChemicalElement]? {
        guard let data, let file = try? JSONDecoder().decode(ElementsFile.self, from: data), file.elements.count >= 118 else { return nil }
        return file.elements.sorted { $0.number < $1.number }
    }

    private func refreshInBackground() {
        Task.detached(priority: .background) {
            guard let (data, _) = try? await URLSession.shared.data(from: Self.remoteURL),
                  Self.decode(data) != nil else { return }
            try? data.write(to: Self.cacheURL, options: .atomic)
        }
    }

    func element(_ number: Int) -> ChemicalElement? {
        elements.indices.contains(number - 1) ? elements[number - 1] : nil
    }
}
