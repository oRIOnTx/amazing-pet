import Foundation

public enum Mode: Equatable {
    case auto
    case fixed(Activity)

    public init(rawValue: String?) {
        if let raw = rawValue, let activity = Activity(rawValue: raw), Activity.toys.contains(activity) {
            self = .fixed(activity)
        } else {
            self = .auto
        }
    }

    public var rawValue: String {
        switch self {
        case .auto: "auto"
        case .fixed(let activity): activity.rawValue
        }
    }
}

public enum ActivityPolicy {
    public static let idleSleepSeconds = 180.0

    public static func activity(for status: SystemStatus, mode: Mode, indicators: Bool) -> Activity {
        if indicators, let alert = alert(for: status) { return alert }
        if case .fixed(let activity) = mode { return activity }
        return toy(for: status)
    }

    public static func alert(for status: SystemStatus) -> Activity? {
        if status.thermal >= .serious { return .overheated }
        if status.memory == .critical { return .memoryFull }
        if status.memory == .warning { return .memoryTight }
        if status.battery?.isLow == true { return .hungry }
        return nil
    }

    public static func toy(for status: SystemStatus) -> Activity {
        if status.idleSeconds > idleSleepSeconds || status.cpu < 0.04 { return .sleep }
        if status.cpu < 0.20 { return .yarn }
        if status.cpu < 0.50 { return .mouse }
        return .laser
    }

    public static func speed(for status: SystemStatus, mode: Mode) -> Double {
        mode == .auto ? 0.8 + status.cpu.clamped(to: 0...1) * 1.4 : 1
    }
}

public struct ActivityStabilizer {
    public let delay: Double
    private var candidate: Activity?
    private var since = 0.0

    public init(delay: Double = 5) {
        self.delay = delay
    }

    public mutating func settle(_ wanted: Activity, current: Activity, now: Double) -> Activity? {
        guard wanted != current else {
            candidate = nil
            return nil
        }
        guard wanted == candidate else {
            candidate = wanted
            since = now
            return nil
        }
        guard now - since >= delay else { return nil }
        candidate = nil
        return wanted
    }

    public mutating func reset() { candidate = nil }
}
