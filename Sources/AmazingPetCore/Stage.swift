public struct Stage: Equatable {
    public static let menuBar = Stage(width: 44, height: 12)

    public let width: Double
    public let height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    public static func roam(width: Double, height: Double) -> Stage {
        Stage(width: width.rounded(.down), height: height.rounded(.down))
    }

    var ground: Double { height - Pet.height }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
