import Foundation

public struct SystemStatus: Equatable {
    public var cpu: Double
    public var thermal: ThermalLevel
    public var memory: MemoryPressure
    public var battery: Battery?
    public var idleSeconds: Double
    public var displaySleepBlocked: Bool
    public var memoryUsage: Double

    public init(
        cpu: Double = 0, thermal: ThermalLevel = .nominal, memory: MemoryPressure = .normal,
        battery: Battery? = nil, idleSeconds: Double = 0, displaySleepBlocked: Bool = false, memoryUsage: Double = 0
    ) {
        self.cpu = cpu
        self.thermal = thermal
        self.memory = memory
        self.battery = battery
        self.idleSeconds = idleSeconds
        self.displaySleepBlocked = displaySleepBlocked
        self.memoryUsage = memoryUsage
    }
}

public enum ThermalLevel: Int, Comparable {
    case nominal, fair, serious, critical

    public init(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .fair: self = .fair
        case .serious: self = .serious
        case .critical: self = .critical
        default: self = .nominal
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum MemoryPressure: Equatable {
    case normal, warning, critical

    public init(kernelLevel: Int32) {
        switch kernelLevel {
        case 2: self = .warning
        case 4: self = .critical
        default: self = .normal
        }
    }
}

public struct Battery: Equatable {
    public static let lowLevel = 0.15

    public var level: Double
    public var charging: Bool

    public init(level: Double, charging: Bool) {
        self.level = level
        self.charging = charging
    }

    public var isLow: Bool { level <= Self.lowLevel && !charging }
}

public struct MemoryPages: Equatable {
    public var appInternal: UInt64
    public var purgeable: UInt64
    public var wired: UInt64
    public var compressed: UInt64

    public init(appInternal: UInt64, purgeable: UInt64, wired: UInt64, compressed: UInt64) {
        self.appInternal = appInternal
        self.purgeable = purgeable
        self.wired = wired
        self.compressed = compressed
    }

    public func usage(pageSize: UInt64, totalBytes: UInt64) -> Double {
        guard totalBytes > 0 else { return 0 }
        let app = appInternal > purgeable ? appInternal - purgeable : 0
        let used = Double(app + wired + compressed) * Double(pageSize)
        return (used / Double(totalBytes)).clamped(to: 0...1)
    }
}

public struct CPUTicks: Equatable {
    public var user: UInt32
    public var system: UInt32
    public var idle: UInt32
    public var nice: UInt32

    public init(user: UInt32, system: UInt32, idle: UInt32, nice: UInt32) {
        self.user = user
        self.system = system
        self.idle = idle
        self.nice = nice
    }

    public func usage(since previous: CPUTicks) -> Double {
        let busy = Double(user &- previous.user) + Double(system &- previous.system) + Double(nice &- previous.nice)
        let total = busy + Double(idle &- previous.idle)
        return total > 0 ? busy / total : 0
    }

    public static func smooth(_ current: Double, toward sample: Double) -> Double {
        current * 0.6 + sample * 0.4
    }
}
