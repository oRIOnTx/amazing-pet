public struct Stage: Equatable {
    public static let menuBar = Stage(width: 44, height: 12)

    public let width: Double
    public let height: Double
    public let floor: Double

    public init(width: Double, height: Double, floor: Double? = nil) {
        self.width = width
        self.height = height
        self.floor = min(floor ?? height, height)
    }

    public static func roam(width: Double, height: Double, floor: Double? = nil) -> Stage {
        Stage(width: width.rounded(.down), height: height.rounded(.down), floor: floor?.rounded(.down))
    }

    var ground: Double { floor - Pet.height }

    var travelBoost: Double { (width / Stage.menuBar.width).squareRoot().clamped(to: 1...2) }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
