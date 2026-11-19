public enum Species: String, CaseIterable {
    case cat, dog, fox, rabbit, hamster, bird, fish, turtle

    var art: SpeciesArt {
        switch self {
        case .cat: .cat
        case .dog: .dog
        case .fox: .fox
        case .rabbit: .rabbit
        case .hamster: .hamster
        case .bird: .bird
        case .fish: .fish
        case .turtle: .turtle
        }
    }

    public var pace: Double {
        switch self {
        case .turtle: 0.45
        case .hamster: 0.9
        case .cat, .fish: 1
        case .dog, .bird: 1.1
        case .rabbit, .fox: 1.2
        }
    }

    var headOffset: Double { 12 }

    var home: Home { self == .fish ? .aquarium : .house }

    public var coats: [Coat] { palettes.map(\.coat) }

    func palette(_ coat: Coat) -> [Character: UInt32] {
        (palettes.first { $0.coat == coat } ?? palettes[0]).colors
    }

    private var palettes: [(coat: Coat, colors: [Character: UInt32])] {
        switch self {
        case .cat: [
            (.ginger, ["O": 0xF4A04A, "D": 0xCF6B1F, "W": 0xFFF1DC, "P": 0xFF8FA3]),
            (.gray, ["O": 0xA7AFBA, "D": 0x7C8592, "W": 0xF2F4F7, "P": 0xFF9FB2]),
            (.black, ["O": 0x4A4A5A, "D": 0x34343F, "W": 0xEDEDED, "P": 0xFF8FA3]),
            (.white, ["O": 0xF7F4EE, "D": 0xDCD6CC, "W": 0xFFFFFF, "P": 0xFFA3B5]),
            (.siamese, ["O": 0xF3E3C6, "D": 0x8A6248, "W": 0xFFF8EA, "P": 0x6E4A36]),
            (.calico, ["O": 0xFBF5EC, "D": 0xE58A3A, "W": 0xFFFFFF, "P": 0xFF8FA3]),
        ]
        case .dog: [
            (.golden, ["O": 0xE8B04B, "D": 0xB97A26, "W": 0xFFF1DC, "P": 0xFF7F99]),
            (.brown, ["O": 0x8B5A3C, "D": 0x5E3A24, "W": 0xE9D3BC, "P": 0xFF7F99]),
            (.black, ["O": 0x3E3E48, "D": 0x26262E, "W": 0xD8D8D8, "P": 0xFF7F99]),
            (.white, ["O": 0xF5F2EC, "D": 0xD9D2C5, "W": 0xFFFFFF, "P": 0xFF7F99]),
            (.spotted, ["O": 0xFAFAFA, "D": 0x2E2E36, "W": 0xFFFFFF, "P": 0xFF7F99]),
            (.gray, ["O": 0x9EA6B0, "D": 0x6F7883, "W": 0xEEF0F3, "P": 0xFF7F99]),
        ]
        case .fox: [
            (.ginger, ["O": 0xEE7A2E, "D": 0x3A2620, "W": 0xFFF4E6, "P": 0xFF8FA3]),
            (.gray, ["O": 0x8E96A3, "D": 0x3A3A44, "W": 0xF2F2F2, "P": 0xFF8FA3]),
            (.white, ["O": 0xF4F6FA, "D": 0xB8C2D0, "W": 0xFFFFFF, "P": 0xFF8FA3]),
        ]
        case .rabbit: [
            (.white, ["O": 0xF8F6F2, "D": 0xD8D2C8, "W": 0xFFFFFF, "P": 0xFFA3B5]),
            (.gray, ["O": 0xA3A9B3, "D": 0x7A818C, "W": 0xEFF1F4, "P": 0xFFA3B5]),
            (.brown, ["O": 0xA87452, "D": 0x7C5236, "W": 0xF2E2D2, "P": 0xFFA3B5]),
            (.black, ["O": 0x45454F, "D": 0x2C2C34, "W": 0xE8E8E8, "P": 0xFFA3B5]),
        ]
        case .hamster: [
            (.golden, ["O": 0xF0B05A, "D": 0xC98536, "W": 0xFFF4E2, "P": 0xFF9FB2]),
            (.white, ["O": 0xF7F3EC, "D": 0xDCD4C6, "W": 0xFFFFFF, "P": 0xFF9FB2]),
            (.gray, ["O": 0xA9AEB6, "D": 0x7E848E, "W": 0xF1F2F4, "P": 0xFF9FB2]),
        ]
        case .bird: [
            (.blue, ["O": 0x4D8FE8, "D": 0x2F5FB0, "W": 0xDDEBFF, "P": 0xF6A623]),
            (.yellow, ["O": 0xF7D23A, "D": 0xD0A21C, "W": 0xFFF6C8, "P": 0xF6A623]),
            (.green, ["O": 0x5DBB63, "D": 0x3A8A40, "W": 0xDDF5D0, "P": 0xF6A623]),
            (.red, ["O": 0xE5483B, "D": 0xA92E25, "W": 0xFFD8D2, "P": 0xF6A623]),
            (.gray, ["O": 0x9EA6B0, "D": 0x6F7883, "W": 0xE3E6EA, "P": 0xF6A623]),
        ]
        case .fish: [
            (.ginger, ["O": 0xF79A2E, "D": 0xE0601A, "W": 0xFFE2B8, "P": 0xFF8FA3]),
            (.blue, ["O": 0x4DA3F0, "D": 0x2A6CC0, "W": 0xD8EEFF, "P": 0xFF8FA3]),
            (.yellow, ["O": 0xF7D23A, "D": 0xE5A21C, "W": 0xFFF6C8, "P": 0xFF8FA3]),
            (.red, ["O": 0xE5483B, "D": 0xA92E25, "W": 0xFFD8D2, "P": 0xFF8FA3]),
        ]
        case .turtle: [
            (.green, ["O": 0x6BBF59, "D": 0x3E8A3A, "W": 0xB7E07A, "P": 0xFF8FA3]),
            (.brown, ["O": 0xB07B4F, "D": 0x7A5232, "W": 0xA9D37A, "P": 0xFF8FA3]),
            (.golden, ["O": 0xE0B050, "D": 0xA87A2A, "W": 0xB7E07A, "P": 0xFF8FA3]),
        ]
        }
    }
}

public enum Coat: String, CaseIterable {
    case ginger, golden, brown, gray, black, white, siamese, calico, spotted, blue, yellow, green, red
}

public final class PetSprites {
    public let walk: [Sprite]
    public let run: [Sprite]
    public let rest: Sprite
    public let climb: [Sprite]
    public let dangle: [Sprite]
    public let pace: Double
    public let home: Home
    let headOffset: Double

    public init(look: PetLook = PetLook()) {
        let art = look.species.art
        let colors = look.colors
        walk = art.walk.map { Sprite($0, colors: colors) }
        run = art.run.map { Sprite($0, colors: colors) }
        rest = Sprite(art.rest, colors: colors)
        climb = art.climb.map { Sprite($0, colors: colors) }
        dangle = [
            Sprite(["KOK.KOK.", "KOK.KOK.", "KKK.KKK."], colors: colors),
            Sprite(["KOK.KOK.", ".KOK.KOK", ".KKK.KKK"], colors: colors),
        ]
        pace = look.species.pace
        home = look.species.home
        headOffset = look.species.headOffset
    }

    public var all: [Sprite] { walk + run + [rest] }
}
