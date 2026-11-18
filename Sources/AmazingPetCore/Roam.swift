public enum AwayPolicy {
    public static let returnGrace = 0.5

    public static func shouldRoam(_ status: SystemStatus, delayMinutes: Int) -> Bool {
        guard delayMinutes > 0, !status.displaySleepBlocked else { return false }
        return status.idleSeconds >= Double(delayMinutes) * 60
    }

    public static func userReturned(idleSeconds: Double, roamingFor: Double) -> Bool {
        idleSeconds < roamingFor - returnGrace
    }
}

public struct RoamDirector {
    public static let napAfterIdle = 15.0 * 60
    static let gameLength = 35.0...70.0

    private let dice: Dice
    public private(set) var current: Activity
    private var switchAt: Double

    public init(dice: Dice = Dice(), now: Double = 0) {
        self.dice = dice
        current = .explore
        switchAt = now + dice(Self.gameLength)
    }

    public static func availableGames(in world: World, on stage: Stage) -> [Activity] {
        Activity.roamGames.filter { game in
            switch game {
            case .peekaboo: !world.hidingSpots(on: stage).isEmpty
            case .cursor: world.cursor != nil
            default: true
            }
        }
    }

    public mutating func update(now: Double, idleSeconds: Double, available: [Activity] = Activity.roamGames) -> Activity? {
        if idleSeconds >= Self.napAfterIdle {
            guard current != .perch else { return nil }
            current = .perch
            return current
        }
        guard now >= switchAt else { return nil }
        let others = available.filter { $0 != current }
        guard !others.isEmpty else { return nil }
        current = others[Int(dice(0...Double(others.count - 1)).rounded())]
        switchAt = now + dice(Self.gameLength)
        return current
    }
}
