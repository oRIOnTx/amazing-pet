struct SpeciesArt {
    let walk: [[String]]
    let run: [[String]]
    let rest: [String]

    var all: [[String]] { walk + run + [rest] }

    var climb: [[String]] { walk.map(Self.turnedUp) }
    var hang: [[String]] { walk.map { $0.reversed() } }

    static func turnedUp(_ rows: [String]) -> [String] {
        let grid = rows.map(Array.init)
        let width = grid.map(\.count).max() ?? 0
        return (0..<width).map { column in
            String(grid.map { row in column < row.count ? row[row.count - 1 - column] : Character(".") })
        }
    }

    static func quadruped(_ top: [String], rest: [String], legs: Character = "O") -> SpeciesArt {
        let paint = { (rows: [String]) in top + rows.map { $0.replacingOccurrences(of: "O", with: String(legs)) } }
        return SpeciesArt(
            walk: [Legs.walkA, Legs.walkB].map(paint),
            run: [Legs.runA, Legs.runB].map(paint),
            rest: rest
        )
    }

    private enum Legs {
        static let walkA = ["..KOK.....KOK...", "..KOK......KOK..", "..KKK......KKK.."]
        static let walkB = ["...KOK...KOK....", "...KOK..KOK.....", "...KKK..KKK....."]
        static let runA = [".KOK.......KOK..", "KOK.........KOK.", "KK...........KK."]
        static let runB = ["...KOK..KOK.....", "....KOKKOK......", ".....KK.KK......"]
    }

    private static let empty = "................"

    static let cat = quadruped([
        "..........K...K.",
        ".........KPK.KPK",
        ".K.......KOOOOOK",
        "KOK......KOEOEOK",
        "KOK......KWOPOWK",
        ".KOKKKKKKKKWWWK.",
        "..KODOOODOOOWWK.",
        "..KOODOOODOOWWK.",
        "..KKKKKKKKKKKK..",
    ], rest: [
        empty, empty, empty, empty,
        ".........K...K..",
        "........KPK.KPK.",
        "...KKKKKKOOOOOK.",
        "..KOODOOKOKOKOK.",
        ".KOOOOODKWOPOWK.",
        ".KODOOOOOKWWWK..",
        "KDOOOOOOOOOOODK.",
        ".KKKKKKKKKKKKKK.",
    ])

    static let dog = quadruped([
        "..........KKKK..",
        ".........KOOOOK.",
        "........KDOOOODK",
        ".K......KDEOOEDK",
        "KOK.....KDOKKODK",
        ".KOKKKKKKKWPPWK.",
        "..KOOOOOOODOWWK.",
        "..KODDOOOOOOWWK.",
        "..KKKKKKKKKKKK..",
    ], rest: [
        empty, empty, empty, empty,
        "..........KKKK..",
        ".........KOOOOK.",
        "...KKKKKKDOOOODK",
        "..KOODOOKDKOOKDK",
        ".KOOOOOOKDOKKODK",
        ".KODDOOOOKWPPWK.",
        "KOOOOOOOOOOWWWK.",
        ".KKKKKKKKKKKKKK.",
    ])

    static let fox = quadruped([
        "..........K...K.",
        ".........KDK.KDK",
        "KK.......KOOOOOK",
        "KWK......KOEOEOK",
        "KOOK.....KWWKWWK",
        "KOOOKKKKKKKWWWK.",
        ".KKOOOOOOOOOWWK.",
        "..KOOOOOOOOOWWK.",
        "..KKKKKKKKKKKK..",
    ], rest: [
        empty, empty, empty, empty,
        ".........K...K..",
        "........KDK.KDK.",
        "...KKKKKKOOOOOK.",
        "..KOOOOOKOKOKOK.",
        ".KOOOOOOKWWKWWK.",
        "KWOOOOOOOKWWWK..",
        "KWWOOOOOOOOOODK.",
        ".KKKKKKKKKKKKKK.",
    ], legs: "D")

    static let rabbit: SpeciesArt = {
        let body = [
            "..........K...K.",
            ".........KPK.KPK",
            ".........KPK.KPK",
            ".........KOOOOOK",
            ".........KOEOEOK",
            "......KKKKWOPOWK",
            ".....KOOOOKWWWK.",
            "...KKOOOOOOOWWK.",
            "..KWOOOOOOOOWWK.",
            "...KKKKKKKKKKK..",
        ]
        return SpeciesArt(
            walk: [
                body + ["...KOOK...KOK...", "...KKKK...KKK..."],
                body + ["....KOOK.KOK....", "....KKKK.KKK...."],
            ],
            run: [
                body + ["..KOOK......KOK.", ".KKKK.......KKK."],
                body + [".....KOOKKOK....", ".....KKKKKKK...."],
            ],
            rest: [
                empty, empty, empty,
                ".........K...K..",
                "........KPK.KPK.",
                "........KPK.KPK.",
                ".....KKKKOOOOOK.",
                "....KOOOKOKOKOK.",
                "...KOOOOKWOPOWK.",
                "..KWOOOOOKWWWK..",
                "..KWOOOOOOOOOOK.",
                "...KKKKKKKKKKK..",
            ]
        )
    }()

    static let hamster: SpeciesArt = {
        let body = [
            empty, empty, empty,
            ".........KPK.KPK",
            "....KKKKKKOOOOOK",
            "...KOOOOOKOEOEOK",
            "..KOOOOOOKWOPOWK",
            "..KOOOOOOOWWWWK.",
            "..KOOOOOOOOWWWK.",
            "..KWWWWWWWWWWK..",
        ]
        let walk = [
            body + ["...KOK....KOK...", "...KKK....KKK..."],
            body + ["....KOK..KOK....", "....KKK..KKK...."],
        ]
        return SpeciesArt(walk: walk, run: walk, rest: [
            empty, empty, empty, empty,
            ".........KPK.KPK",
            "....KKKKKKOOOOOK",
            "...KOOOOOKOKOKOK",
            "..KOOOOOOKWOPOWK",
            "..KOOOOOOOWWWWK.",
            "..KOOOOOOOOWWWK.",
            "..KWWWWWWWWWWK..",
            "...KKKKKKKKKK...",
        ])
    }()

    static let bird: SpeciesArt = {
        let body = [
            empty, empty,
            ".........KKKK...",
            "........KOOOOK..",
            "........KOOOEKAA",
            "..KK....KOOOOK..",
            "..KDKKKKKWOOOK..",
            "...KDDDDOWWOOK..",
            "....KDDDOWWWK...",
            ".....KKKKKKKK...",
        ]
        return SpeciesArt(
            walk: [
                body + [".......A..A.....", "......AA.AA....."],
                body + ["........A.A.....", ".......AA.AA...."],
            ],
            run: [
                [
                    empty,
                    "....KK..........",
                    "....KDK..KKKK...",
                    ".....KDKKOOOOK..",
                    "......KDKOOOEKAA",
                    "..KK...KKOOOOK..",
                    "..KDKKKKKWOOOK..",
                    "...KOOOOOWWOOK..",
                    "....KOOOOWWWK...",
                    ".....KKKKKKKK...",
                    empty, empty,
                ],
                [
                    empty, empty,
                    ".........KKKK...",
                    "........KOOOOK..",
                    "........KOOOEKAA",
                    "..KK....KOOOOK..",
                    "..KDKKKKKWOOOK..",
                    "...KOOOOOWWOOK..",
                    "....KDDDDWWWK...",
                    ".....KDDDKKKK...",
                    "......KDK.......",
                    ".......K........",
                ],
            ],
            rest: [
                empty, empty, empty, empty,
                ".........KKKK...",
                "........KOOOOK..",
                "........KOOOKKAA",
                "..KK....KOOOOK..",
                "..KDKKKKKWOOOK..",
                "...KDDDDOWWOOK..",
                "....KDDDOWWWK...",
                ".....KKKKKKKK...",
            ]
        )
    }()

    static let fish: SpeciesArt = {
        let swim = [
            [
                empty, empty,
                "......KKKK......",
                ".....KDDDDK.....",
                "KK..KOOOOOOKK...",
                "KDKKOOOOOOOOOK..",
                "KDDOOOOOOOOEOOK.",
                "KDDOOOOWWOOOOPK.",
                "KDKKOWWWWWWOOK..",
                "KK..KKOOOOOKK...",
                ".......KDK......",
                empty,
            ],
            [
                empty, empty,
                "......KKKK......",
                ".....KDDDDK.....",
                "....KOOOOOOKK...",
                "KK.KOOOOOOOOOK..",
                "KDKOOOOOOOOEOOK.",
                "KDKOOOOWWOOOOPK.",
                "KK.KOWWWWWWOOK..",
                "....KKOOOOOKK...",
                ".......KDK......",
                empty,
            ],
        ]
        return SpeciesArt(walk: swim, run: swim, rest: [
            empty, empty, empty, empty,
            "......KKKK......",
            ".....KDDDDK.....",
            "KK..KOOOOOOKK...",
            "KDKKOOOOOOOOOK..",
            "KDDOOOOOOOOKOOK.",
            "KDDOOOOWWOOOOPK.",
            "KDKKOWWWWWWOOK..",
            "KK..KKOOOOOKK...",
        ])
    }()

    static let turtle: SpeciesArt = {
        let shell = [
            empty, empty, empty, empty,
            "....KKKKKK......",
            "...KODDODDK.....",
            "..KODOODOODK.KK.",
            "..KDOODDOODKKWEK",
            ".KKKKKKKKKKKKWWK",
        ]
        let walk = [
            shell + ["..KWWKKKKKWWKKK.", "..KWWK....KWWK..", "..KKKK....KKKK.."],
            shell + ["...KWWKKKKWWKKK.", "...KWWK..KWWK...", "...KKKK..KKKK..."],
        ]
        return SpeciesArt(walk: walk, run: walk, rest: [
            empty, empty, empty, empty, empty,
            "....KKKKKK......",
            "...KODDODDK.....",
            "..KODOODOODK....",
            "..KDOODDOODKKK..",
            ".KKKKKKKKKKKKWK.",
            "..KWWKKKKKWWKK..",
            "..KKKK....KKKK..",
        ])
    }()
}
