import CoreGraphics

public final class Sprite {
    let rows: [String]
    public let width: Int
    public let height: Int
    public let right: CGImage
    public let left: CGImage

    public init(_ rows: [String], colors: [Character: CGColor] = Palette.colors) {
        self.rows = rows
        height = rows.count
        width = rows.map(\.count).max() ?? 0
        right = Sprite.render(rows, colors: colors, width: width, mirrored: false)
        left = Sprite.render(rows, colors: colors, width: width, mirrored: true)
    }

    public func image(facingRight: Bool) -> CGImage { facingRight ? right : left }

    private static func render(_ rows: [String], colors: [Character: CGColor], width: Int, mirrored: Bool) -> CGImage {
        let height = rows.count
        let ctx = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        for (r, row) in rows.enumerated() {
            for (c, ch) in row.enumerated() {
                guard let color = colors[ch] else { continue }
                ctx.setFillColor(color)
                ctx.fill(CGRect(x: mirrored ? width - 1 - c : c, y: height - 1 - r, width: 1, height: 1))
            }
        }
        return ctx.makeImage()!
    }
}

public enum Palette {
    public static let transparent: Character = "."

    public static func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
        CGColor(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }

    public static let colors: [Character: CGColor] = [
        "K": color(0x2A1C17),
        "E": color(0x1B120E),
        "O": color(0xF4A04A),
        "D": color(0xCF6B1F),
        "W": color(0xFFF1DC),
        "P": color(0xFF8FA3),
        "Y": color(0xD45FD6),
        "y": color(0xF5B4F2),
        "L": color(0x8E2F9E),
        "G": color(0x9AA1A9),
        "g": color(0xD3D8DE),
        "R": color(0xFF2D2D),
        "r": color(0xFF2D2D, 0.35),
        "B": color(0x6FA8FF),
        "S": color(0x8FD8FF),
        "H": color(0xFF4F78),
        "C": color(0xC8945A),
        "c": color(0x9C6A36),
        "T": color(0xEBD6A8),
        "b": color(0x4F86E8),
        "F": color(0x7FC8FF),
        "A": color(0xF6A623),
        "U": color(0x7FD6FF),
        "u": color(0xFFB3E6),
        "a": color(0x6FB8FF, 0.3),
        "v": color(0x5DBB63),
    ]
}

public enum Sprites {
    public static let defaultPet = PetSprites()

    public static let yarn = [
        Sprite([".LLLL.", "LyYLYL", "LYLYyL", "LLYyYL", "LYyYLL", ".LLLL."]),
        Sprite([".LLLL.", "LLYyYL", "LYyYLL", "LyYLYL", "LYLYyL", ".LLLL."]),
    ]

    public static let toyMouse = [
        Sprite(["....KK..", "...KPGK.", "KKKGGGEP", "...KgKK."]),
        Sprite(["....KK..", "...KPGK.", ".KKGGGEP", "K..KKgK."]),
    ]

    public static let laser = [
        Sprite([".r.", "rRr", ".r."]),
        Sprite(["rrr", "rRr", "rrr"]),
    ]

    public static let thermometer = [
        Sprite([".KK.", "KWWK", "KWWK", "KWWK", "KWWK", "KRWK", "KRRK", "KRRK", "KRRK", ".KK."]),
        Sprite([".KK.", "KWWK", "KRWK", "KRWK", "KRWK", "KRRK", "KRRK", "KRRK", "KRRK", ".KK."]),
    ]

    public static let house = Sprite([
        "......KKKKKKKK......",
        "...KKKccccccccKKK...",
        "KKKccccccccccccccKKK",
        "KKKKKKKKKKKKKKKKKKKK",
        ".KCCCCCCK........KCK",
        ".KCCCCCCK........KCK",
        ".KccccccK........KcK",
        ".KCCCCCCK........KCK",
        ".KCCCCCCK........KCK",
        ".KccccccK........KcK",
        ".KCCCCCCK........KCK",
        ".KKKKKKKK........KKK",
    ])

    public static let aquarium = Sprite([
        "g..................g",
        "g..................g",
        "gSSSSSSSSSSSSSSSSSSg",
        "gaaaaaaaaaaaaaaaaaag",
        "gaaaaaaaaaaaaaaaaaag",
        "gaaaaaaaaaaaaaaaaaag",
        "gaavaaaaaaaaaaaaaaag",
        "gavaaaaaaaaaaaaaaaag",
        "gaavaaaaaaaaaaaavaag",
        "gavaaaaaaaaaaaaavaag",
        "gaavaaaaaaaaaaaaavag",
        "KKKKKKKKKKKKKKKKKKKK",
    ])

    public static let bowl = Sprite(["KKKKKKKK", "KbbbbbbK", ".KKKKKK."])

    public static let zzz = Sprite(["BBB", ".B.", "BBB"])
    public static let heart = Sprite([".H.H.", "HHHHH", ".HHH.", "..H.."])
    public static let sweat = Sprite([".S.", "SSS", ".S."])
    public static let exclamation = Sprite(["R", "R", ".", "R"])
    public static let butterfly = [
        Sprite(["UU.uu", "UUKuu", ".UKu.", "..K.."]),
        Sprite([".U.u.", ".UKu.", "..K..", "..K.."]),
    ]
    public static let fish = Sprite([".FFF.F", "FEFFFF", ".FFF.F"])
    public static let pot = Sprite([".v.v.", "..v..", "KcccK", "KCCCK", "KCCCK", ".KKK."])
    public static let shards = Sprite(["..v.v..", "cK.vKCc"])
    public static let bubble = Sprite([".S.", "S.S", ".S."])

    public static let all: [Sprite] =
        defaultPet.all + yarn + toyMouse + laser + thermometer
        + butterfly + [house, aquarium, bowl, zzz, heart, sweat, exclamation, fish, bubble, pot, shards]
}
