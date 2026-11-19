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
        "k": color(0x2A1C17, 0.55),
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

    public static let basket = Sprite([
        "....................",
        "....................",
        "......cccccccc......",
        ".....c........c.....",
        "....c..........c....",
        "...c............c...",
        "..c..............c..",
        "..c..............c..",
        ".c................c.",
        "KKcKcKcKcKcKcKcKcKKK",
        "KCcCcCcCcCcCcCcCcCcK",
        ".KKKKKKKKKKKKKKKKKK.",
    ])

    public static let kennel = Sprite([
        "......RRRRRRRR......",
        "...RRRHHHHHHHHRRR...",
        "RRRHHHHHHHHHHHHHHRRR",
        "KKKKKKKKKKKKKKKKKKKK",
        ".KCCCCCCK........KCK",
        ".KCCCCCCK........KCK",
        ".KccccccK........KcK",
        ".KCCWWCCK........KCK",
        ".KCCWWCCK........KCK",
        ".KccccccK........KcK",
        ".KCCCCCCK........KCK",
        ".KKKKKKKK........KKK",
    ])

    public static let den = Sprite([
        "....................",
        "....................",
        "....................",
        "....................",
        "....................",
        "..vvvvvv............",
        ".vccccccv.........vv",
        "cccCccccc........vcc",
        "cccccccccK......KcCc",
        "cccccCcccKKKKKKKKccc",
        "ccCcccccccccCccccCcc",
        "ccccccccCccccccccccc",
    ])

    public static let burrow = Sprite([
        "....................",
        "..v.v...............",
        "...v................",
        "..AAA...............",
        "..AAA...............",
        "..AAAvvv............",
        ".vvAvvvvv.........vv",
        "vvvAvvvvv........vvv",
        "vvvvvvvvvK......Kvvv",
        "vvvvvvvvvKKKKKKKKvvv",
        "vvvvvvvvvvvvvvvvvvvv",
        "vvvvvvvvvvvvvvvvvvvv",
    ])

    public static let cage = Sprite([
        "...GGGGGGGGGGGGGG...",
        ".GG......GG......GG.",
        "G..G..G..G..G..G..GG",
        "G..G..G..G..G..G..GG",
        "G.KKK.G..G..G..G..GG",
        "GK.g.KG..G..G..G..GG",
        "GKgggKG..G..G..G..GG",
        "GK.g.KG..G..G..G..GG",
        "G.KKK.G..G..G..G..GG",
        "G..G..G..G..G..G..GG",
        "bbbbbbbbbbbbbbbbbbbb",
        "KKKKKKKKKKKKKKKKKKKK",
    ])

    public static let birdhouse = Sprite([
        ".........RR.........",
        ".......RRHHRR.......",
        ".....RRHHHHHHRR.....",
        "...RRHHHHHHHHHHRR...",
        ".RRRRRRRRRRRRRRRRRR.",
        "..KTTTTTK......KTK..",
        "..KTbbTTK......KTK..",
        "..KTbbTTK......KTK..",
        "..KTTTTTK......KTK..",
        "..KTTTTTTK....KTTKcc",
        "..KTTTTTTTKKKKTTTK..",
        "..KKKKKKKKKKKKKKKK..",
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

    public static let rocks = Sprite([
        "....................",
        "....................",
        "....vv..............",
        ".vvvv.v.............",
        ".vKKKKv.............",
        ".KGGGGK.............",
        "KGggGGGK............",
        "KGGGGgGGK.........KK",
        "KGgGGGgGK........KGG",
        "KGGGGGgGGK.......GgG",
        "KGGGGGGGGK.......GGG",
        "BBBBSBBBBBBBBSBBBBSB",
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

    public static let bone = [
        Sprite([".K....K.", "KWKKKKWK", "KWWWWWWK", "KWKKKKWK", ".K....K."]),
        Sprite([".K......", "KWKKK...", "KWWWWK..", "KWKKK...", ".K......"]),
        Sprite(["........", "........", "........", "..W..W..", ".W..W..."]),
    ]
    public static let carrot = [
        Sprite([".....v.v", ".AAAAAv.", "AAAAAAA.", ".AAAA..."]),
        Sprite([".....v.v", "...AAAv.", "..AAAAA.", "...AA..."]),
        Sprite([".....v.v", "......v.", "........", "........"]),
    ]
    public static let seeds = [
        Sprite(["..K.K..", ".KgKgK.", "KgKKKgK"]),
        Sprite([".......", "..K.K..", ".KgKgK."]),
        Sprite([".......", ".......", "..K...."]),
    ]
    public static let grain = [
        Sprite(["..A.A..", ".AAAAA.", "AAAAAAA"]),
        Sprite([".......", "...A...", ".AA.AA."]),
        Sprite([".......", ".......", "..A...."]),
    ]
    public static let lettuce = [
        Sprite([".vvvv..", "vvWvvv.", "vvvvWvv", ".vvvvv."]),
        Sprite([".......", "..vvv..", ".vvWvv.", "..vvvv."]),
        Sprite([".......", ".......", "...v...", "..vv..."]),
    ]
    public static let strawberry = [
        Sprite(["v.v.v", ".vvv.", "RRTRR", "RRRTR", ".RRR."]),
        Sprite([".....", ".vvv.", "RRTR.", "RRR..", ".R..."]),
        Sprite([".....", ".....", ".....", ".v.v.", "....."]),
    ]
    public static let flakes = [
        Sprite(["AA.", ".AA"]),
        Sprite([".A.", "A.."]),
        Sprite(["...", ".A."]),
    ]
    public static let ball = Sprite([".RR.", "RRWR", "RRRR", ".RR."])
    public static let leaf = [
        Sprite(["...AA", ".AAAA", "AAAA.", "K...."]),
        Sprite(["AA...", "AAAA.", ".AAAA", "....K"]),
    ]
    public static let sniff = Sprite(["g.g", ".g."])
    public static let dust = Sprite(["g......g", ".g....g."])
    public static let bits = Sprite([".v..vvv", "vv..v.v", ".v..v.v", ".v..v.v", "vvv.vvv"])
    public static let note = Sprite(["..bb", "..bb", "..b.", "bbb.", "bb.."])
    public static let speech = Sprite([".KKKKK.", "KWWWWWK", "KWKWKWK", "KWWWWWK", ".KK...."])
    public static let question = Sprite(["bbb", "..b", ".b.", "...", ".b."])
    public static let bite = Sprite(["k.k.k.k", ".k.k.k."])
    public static let crumb = Sprite(["gW", "Wg"])
    public static let star = Sprite([".A.", "AAA", ".A."])
    public static let hamsterBall = Sprite([".....SSSSSSSS.....", "...SSS......SSS...", "..SSWW........SS..", ".S.W............S.", "SS..............SS", "S................S", "S................S", "SS..............SS", ".S..............S.", "..SS..........SS..", "...SSS......SSS...", ".....SSSSSSSS....."])
    public static let wheel = [
        Sprite([".....KGGKKGGK.....", "...GGK......KGG...", "..KK..........KK..", ".G..............G.", "KG..............GK", "K................K", "G................G", "GK..............KG", ".K..............K.", "..GG..........GG..", "...KKG......GKK...", ".....GKKGGKKG....."]),
        Sprite([".....GKKGGKKG.....", "...KKG......GKK...", "..GG..........GG..", ".K..............K.", "GK..............KG", "G................G", "K................K", "KG..............GK", ".G..............G.", "..KK..........KK..", "...GGK......KGG...", ".....KGGKKGGK....."]),
    ]

    public static let homes = [basket, kennel, den, burrow, cage, birdhouse, aquarium, rocks]

    public static let all: [Sprite] =
        defaultPet.all + yarn + toyMouse + laser + thermometer
        + butterfly + homes + [bowl, zzz, heart, sweat, exclamation, fish, bubble, pot, shards]
        + bone + carrot + seeds + grain + lettuce + strawberry + flakes + leaf + wheel
        + [ball, sniff, dust, star, hamsterBall, bits, note, speech, question, crumb, bite]
}
