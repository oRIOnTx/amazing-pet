import CoreGraphics
import Darwin
import Foundation
import IOKit.ps
import IOKit.pwr_mgt

public enum UserIdle {
    public static var seconds: Double {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
    }
}

public final class SystemSampler {
    private static let batteryRefreshSeconds = 30.0

    private let host = mach_host_self()
    private var previousTicks: CPUTicks?
    private var cpu = 0.0
    private var battery: Battery?
    private var batteryCheckedAt = -Double.infinity

    public init() {
        previousTicks = readTicks()
    }

    public func sample(now: Double) -> SystemStatus {
        if let ticks = readTicks() {
            if let previous = previousTicks {
                cpu = CPUTicks.smooth(cpu, toward: ticks.usage(since: previous))
            }
            previousTicks = ticks
        }
        if now - batteryCheckedAt >= Self.batteryRefreshSeconds {
            battery = Self.readBattery()
            batteryCheckedAt = now
        }
        return SystemStatus(
            cpu: cpu,
            thermal: ThermalLevel(ProcessInfo.processInfo.thermalState),
            memory: MemoryPressure(kernelLevel: Self.readMemoryPressureLevel()),
            battery: battery,
            idleSeconds: UserIdle.seconds,
            displaySleepBlocked: Self.isDisplaySleepBlocked(),
            memoryUsage: readMemoryUsage()
        )
    }

    private func readTicks() -> CPUTicks? {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(host, HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        let t = info.cpu_ticks
        return CPUTicks(user: t.0, system: t.1, idle: t.2, nice: t.3)
    }

    private func readMemoryUsage() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        let pages = MemoryPages(
            appInternal: UInt64(stats.internal_page_count),
            purgeable: UInt64(stats.purgeable_count),
            wired: UInt64(stats.wire_count),
            compressed: UInt64(stats.compressor_page_count)
        )
        return pages.usage(pageSize: UInt64(vm_kernel_page_size), totalBytes: ProcessInfo.processInfo.physicalMemory)
    }

    private static func isDisplaySleepBlocked() -> Bool {
        var assertions: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsStatus(&assertions) == kIOReturnSuccess,
              let status = assertions?.takeRetainedValue() as? [String: Int]
        else { return false }
        return ["PreventUserIdleDisplaySleep", "NoDisplaySleepAssertion"].contains { (status[$0] ?? 0) > 0 }
    }

    private static func readMemoryPressureLevel() -> Int32 {
        var level: Int32 = 0
        var size = MemoryLayout<Int32>.size
        return sysctlbyname("kern.memorystatus_vm_pressure_level", &level, &size, nil, 0) == 0 ? level : 0
    }

    private static func readBattery() -> Battery? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return nil }
        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
                  let current = description[kIOPSCurrentCapacityKey] as? Int,
                  let max = description[kIOPSMaxCapacityKey] as? Int, max > 0
            else { continue }
            let onAC = description[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
            return Battery(level: Double(current) / Double(max), charging: onAC)
        }
        return nil
    }
}
