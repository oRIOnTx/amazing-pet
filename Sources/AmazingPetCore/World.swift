public struct Platform: Equatable {
    public let y: Double
    public let minX: Double
    public let maxX: Double
    public let window: Box?

    public init(y: Double, minX: Double, maxX: Double, window: Box? = nil) {
        self.y = y
        self.minX = minX
        self.maxX = maxX
        self.window = window
    }

    public var width: Double { maxX - minX }

    func contains(_ x: Double) -> Bool { x >= minX && x <= maxX }
}

public struct Box: Equatable {
    public let minX: Double
    public let minY: Double
    public let maxX: Double
    public let maxY: Double
    public let id: Int
    public let kind: WindowKind

    public init(x: Double, y: Double, width: Double, height: Double, id: Int = 0, kind: WindowKind = .other) {
        minX = x
        minY = y
        maxX = x + width
        maxY = y + height
        self.id = id
        self.kind = kind
    }

    func overlaps(x: ClosedRange<Double>, y: ClosedRange<Double>) -> Bool {
        minX < x.upperBound && maxX > x.lowerBound && minY < y.upperBound && maxY > y.lowerBound
    }
}

struct Wall: Equatable {
    let x: Double
    let faceRight: Bool
    let top: Platform
    let base: Double

    var climbX: Double { faceRight ? x - Pet.climbWidth : x }
    var standCenter: Double { faceRight ? x - Pet.width / 2 : x + Pet.width / 2 }
}

struct Ledge: Equatable {
    let top: Platform
    let right: Bool

    var edge: Double { right ? top.maxX : top.minX }
    var outward: Double { right ? 1 : -1 }
}

public struct World: Equatable {
    public static let minimumWindowSize = (width: 30.0, height: 20.0)
    public static let maximumScreenShare = 0.7

    public var occluders: [Box]
    public var cursor: (x: Double, y: Double)?

    public init(occluders: [Box] = [], cursor: (x: Double, y: Double)? = nil) {
        self.occluders = occluders
        self.cursor = cursor
    }

    public static func isOccluder(_ box: Box, on stage: Stage) -> Bool {
        let width = box.maxX - box.minX
        let height = box.maxY - box.minY
        guard width >= minimumWindowSize.width, height >= minimumWindowSize.height else { return false }
        return width * height < stage.width * stage.height * maximumScreenShare
    }

    public static func == (lhs: World, rhs: World) -> Bool {
        lhs.occluders == rhs.occluders && lhs.cursor?.x == rhs.cursor?.x && lhs.cursor?.y == rhs.cursor?.y
    }

    func surfaces(on stage: Stage) -> [Platform] {
        let ground = Platform(y: stage.height, minX: 0, maxX: stage.width)
        let tops = occluders.enumerated().flatMap { index, box -> [Platform] in
            let y = box.minY.rounded(.down)
            guard y > Pet.height + 2, y < stage.height else { return [] }
            let covers = occluders[..<index]
                .filter { $0.minY < y && $0.maxY > y - Pet.height }
                .map { ($0.minX, $0.maxX) }
            return Self.subtract(covers, from: (max(0, box.minX), min(stage.width, box.maxX)))
                .filter { $0.1 - $0.0 >= Pet.width }
                .map { Platform(y: y, minX: $0.0, maxX: $0.1, window: box) }
        }
        return tops + [ground]
    }

    static func subtract(_ cuts: [(Double, Double)], from span: (Double, Double)) -> [(Double, Double)] {
        cuts.reduce([span]) { pieces, cut in
            pieces.flatMap { piece -> [(Double, Double)] in
                guard cut.1 > piece.0, cut.0 < piece.1 else { return [piece] }
                return [(piece.0, cut.0), (cut.1, piece.1)].filter { $0.1 > $0.0 }
            }
        }
    }

    func depth(of box: Box) -> Int? {
        occluders.firstIndex(of: box)
    }

    func isClear(x: ClosedRange<Double>, y: ClosedRange<Double>, inFrontOf box: Box) -> Bool {
        guard let index = depth(of: box) else { return false }
        return !occluders[..<index].contains { $0.overlaps(x: x, y: y) }
    }

    func surface(at feet: Double, x: Double, on stage: Stage) -> Platform? {
        surfaces(on: stage).first { abs($0.y - feet) < 0.01 && $0.contains(x) }
    }

    func landing(from oldFeet: Double, to newFeet: Double, x: Double, on stage: Stage) -> Double? {
        surfaces(on: stage)
            .filter { $0.y >= oldFeet - 0.01 && $0.y <= newFeet && $0.contains(x) }
            .map(\.y)
            .min()
    }

    func surface(under point: (x: Double, y: Double), on stage: Stage) -> Platform {
        surfaces(on: stage).filter { $0.y >= point.y && $0.contains(point.x) }.min { $0.y < $1.y }
            ?? surfaces(on: stage).last!
    }

    public func hidingSpots(on stage: Stage) -> [Platform] {
        surfaces(on: stage).flatMap { surface in
            occluders.compactMap { box -> Platform? in
                guard box.minY <= surface.y - Pet.height + 2, box.maxY >= surface.y - 2 else { return nil }
                let minX = max(surface.minX, box.minX)
                let maxX = min(surface.maxX, box.maxX)
                guard maxX - minX >= Pet.width + 4 else { return nil }
                return Platform(y: surface.y, minX: minX, maxX: maxX)
            }
        }
    }

    func windowTops(on stage: Stage, minWidth: Double = Pet.width + 4) -> [Platform] {
        surfaces(on: stage).filter { $0.y < stage.height && $0.width >= minWidth }
    }

    func ledges(on stage: Stage, room: Double, minWidth: Double = Pet.width + 4) -> [Ledge] {
        windowTops(on: stage, minWidth: minWidth).flatMap { top -> [Ledge] in
            guard let box = top.window else { return [] }
            return [Ledge(top: top, right: false), Ledge(top: top, right: true)].filter { ledge in
                ledge.right
                    ? abs(top.maxX - box.maxX) < 0.5 && top.maxX + room <= stage.width
                    : abs(top.minX - box.minX) < 0.5 && top.minX - room >= 0
            }
        }
    }

    func walls(on stage: Stage) -> [Wall] {
        windowTops(on: stage).flatMap { top -> [Wall] in
            guard let box = top.window else { return [] }
            return [Wall(x: box.minX, faceRight: true, top: top, base: 0), Wall(x: box.maxX, faceRight: false, top: top, base: 0)]
                .compactMap { wall in
                    guard abs(wall.x - (wall.faceRight ? top.minX : top.maxX)) < 0.5,
                          wall.standCenter >= Pet.width / 2, wall.standCenter <= stage.width - Pet.width / 2
                    else { return nil }
                    let base = surface(under: (wall.standCenter, top.y + 1), on: stage)
                    guard base.contains(wall.standCenter), base.y - top.y >= Pet.height + 4, box.maxY >= base.y - 6,
                          isClear(x: wall.climbX...(wall.climbX + Pet.climbWidth), y: (top.y - Pet.height)...base.y, inFrontOf: box)
                    else { return nil }
                    return Wall(x: wall.x, faceRight: wall.faceRight, top: top, base: base.y)
                }
        }
    }

    func highestPerch(on stage: Stage) -> Platform {
        surfaces(on: stage).min { $0.y < $1.y }!
    }
}
