import CoreGraphics
import Foundation

public enum EyeColor: String, CaseIterable {
    case dark, amber, green, blue

    var hex: UInt32 {
        switch self {
        case .dark: 0x1B120E
        case .amber: 0xF2B33D
        case .green: 0x5DBB63
        case .blue: 0x5AA9F0
        }
    }

    public var swatch: CGColor { Palette.color(hex) }
}

public struct PetLook: Hashable {
    public var species: Species {
        didSet { coat = species.coats.contains(coat) ? coat : species.coats[0] }
    }
    public var coat: Coat
    public var eyes: EyeColor

    public init(species: Species = .cat, coat: Coat? = nil, eyes: EyeColor = .dark) {
        self.species = species
        self.coat = coat.flatMap { species.coats.contains($0) ? $0 : nil } ?? species.coats[0]
        self.eyes = eyes
    }

    public static func random(using dice: Dice = Dice()) -> PetLook {
        let species = pick(Species.allCases, dice)
        return PetLook(species: species, coat: pick(species.coats, dice), eyes: pick(EyeColor.allCases, dice))
    }

    private static func pick<T>(_ options: [T], _ dice: Dice) -> T {
        options[min(Int(dice(0...Double(options.count))), options.count - 1)]
    }

    var colors: [Character: CGColor] {
        var hexes = species.palette(coat)
        hexes["E"] = eyes.hex
        return Palette.colors.merging(hexes.mapValues { Palette.color($0) }) { $1 }
    }
}

public struct PetProfile: Equatable {
    public static let maxNameLength = 12

    public var name: String
    public var look: PetLook

    public init(name: String, look: PetLook = PetLook()) {
        self.name = name
        self.look = look
    }

    public static func cleanName(_ raw: String, fallback: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : String(trimmed.prefix(maxNameLength))
    }
}
