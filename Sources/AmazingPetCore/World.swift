public struct Platform: Equatable {
    public let y: Double
    public let minX: Double
    public let maxX: Double

    public init(y: Double, minX: Double, maxX: Double) {
        self.y = y
        self.minX = minX
        self.maxX = maxX
    }

    public var width: Double { maxX - minX }

    func contains(_ x: Double) -> Bool { x >= minX && x <= maxX }
}

public struct Box: Equatable {
    public let minX: Double
    public let minY: Double
    public let maxX: Double
    public let maxY: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        minX = x
        minY = y
        maxX = x + width
        maxY = y + height
    }
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
        let tops = occluders.compactMap { box -> Platform? in
            let y = box.minY.rounded(.down)
            let minX = max(0, box.minX)
            let maxX = min(stage.width, box.maxX)
            guard y > Pet.height + 2, y < stage.height, maxX - minX >= Pet.width else { return nil }
            return Platform(y: y, minX: minX, maxX: maxX)
        }
        return tops + [ground]
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

    func highestPerch(on stage: Stage) -> Platform {
        surfaces(on: stage).min { $0.y < $1.y }!
    }
}
