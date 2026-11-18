import Foundation
import Testing
@testable import AmazingPetCore

struct SystemStatusTests {
    @Test func cpuUsageIsBusyShareOfTicks() {
        let previous = CPUTicks(user: 100, system: 50, idle: 800, nice: 50)
        let current = CPUTicks(user: 130, system: 60, idle: 850, nice: 60)
        #expect(current.usage(since: previous) == 0.5)
    }

    @Test func cpuUsageIsZeroWithoutNewTicks() {
        let ticks = CPUTicks(user: 1, system: 1, idle: 1, nice: 1)
        #expect(ticks.usage(since: ticks) == 0)
    }

    @Test func cpuUsageSurvivesCounterWraparound() {
        let previous = CPUTicks(user: .max - 9, system: 0, idle: 0, nice: 0)
        let current = CPUTicks(user: 10, system: 0, idle: 20, nice: 0)
        #expect(current.usage(since: previous) == 0.5)
    }

    @Test func smoothingMovesPartwayToSample() {
        #expect(CPUTicks.smooth(0, toward: 1) == 0.4)
        #expect(CPUTicks.smooth(0.5, toward: 0.5) == 0.5)
    }

    @Test(arguments: [(Int32(1), MemoryPressure.normal), (2, .warning), (4, .critical), (0, .normal), (99, .normal)])
    func memoryPressureFromKernelLevel(level: Int32, expected: MemoryPressure) {
        #expect(MemoryPressure(kernelLevel: level) == expected)
    }

    @Test func thermalLevelMapsProcessInfoState() {
        #expect(ThermalLevel(.nominal) == .nominal)
        #expect(ThermalLevel(.fair) == .fair)
        #expect(ThermalLevel(.serious) == .serious)
        #expect(ThermalLevel(.critical) == .critical)
        #expect(ThermalLevel.fair < .serious)
    }

    @Test func batteryIsLowOnlyWhenDischargingBelowThreshold() {
        #expect(Battery(level: 0.10, charging: false).isLow)
        #expect(Battery(level: 0.15, charging: false).isLow)
        #expect(!Battery(level: 0.10, charging: true).isLow)
        #expect(!Battery(level: 0.50, charging: false).isLow)
    }
}
