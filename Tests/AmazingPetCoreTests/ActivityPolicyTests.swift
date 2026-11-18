import Testing
@testable import AmazingPetCore

struct ActivityPolicyTests {
    @Test(arguments: [(0.02, Activity.sleep), (0.10, .yarn), (0.30, .mouse), (0.80, .laser)])
    func toyFollowsCPULoad(cpu: Double, expected: Activity) {
        #expect(ActivityPolicy.toy(for: SystemStatus(cpu: cpu)) == expected)
    }

    @Test func idleUserMakesCatSleep() {
        let status = SystemStatus(cpu: 0.9, idleSeconds: ActivityPolicy.idleSleepSeconds + 1)
        #expect(ActivityPolicy.toy(for: status) == .sleep)
    }

    @Test func alertsHavePriorityOrder() {
        let all = SystemStatus(thermal: .critical, memory: .critical, battery: Battery(level: 0.05, charging: false))
        #expect(ActivityPolicy.alert(for: all) == .overheated)
        #expect(ActivityPolicy.alert(for: SystemStatus(memory: .warning, battery: all.battery)) == .memoryFull)
        #expect(ActivityPolicy.alert(for: SystemStatus(battery: all.battery)) == .hungry)
        #expect(ActivityPolicy.alert(for: SystemStatus(thermal: .fair)) == nil)
    }

    @Test func alertsOverrideModeWhenIndicatorsEnabled() {
        let hot = SystemStatus(cpu: 0.9, thermal: .serious)
        #expect(ActivityPolicy.activity(for: hot, mode: .fixed(.yarn), indicators: true) == .overheated)
        #expect(ActivityPolicy.activity(for: hot, mode: .fixed(.yarn), indicators: false) == .yarn)
        #expect(ActivityPolicy.activity(for: hot, mode: .auto, indicators: false) == .laser)
    }

    @Test func speedScalesWithCPUOnlyInAutoMode() {
        #expect(ActivityPolicy.speed(for: SystemStatus(cpu: 0), mode: .auto) == 0.8)
        #expect(ActivityPolicy.speed(for: SystemStatus(cpu: 5), mode: .auto) == 2.2)
        #expect(ActivityPolicy.speed(for: SystemStatus(cpu: 1), mode: .fixed(.laser)) == 1)
    }

    @Test func modeRoundTripsThroughRawValue() {
        #expect(Mode(rawValue: Mode.auto.rawValue) == .auto)
        #expect(Mode(rawValue: Mode.fixed(.mouse).rawValue) == .fixed(.mouse))
        #expect(Mode(rawValue: nil) == .auto)
        #expect(Mode(rawValue: "garbage") == .auto)
        #expect(Mode(rawValue: Activity.hungry.rawValue) == .auto)
    }
}

struct ActivityStabilizerTests {
    @Test func switchesOnlyAfterWantedActivityPersists() {
        var stabilizer = ActivityStabilizer(delay: 5)
        #expect(stabilizer.settle(.laser, current: .yarn, now: 0) == nil)
        #expect(stabilizer.settle(.laser, current: .yarn, now: 4) == nil)
        #expect(stabilizer.settle(.laser, current: .yarn, now: 5) == .laser)
    }

    @Test func restartsWhenWantedActivityChanges() {
        var stabilizer = ActivityStabilizer(delay: 5)
        _ = stabilizer.settle(.laser, current: .yarn, now: 0)
        #expect(stabilizer.settle(.mouse, current: .yarn, now: 4) == nil)
        #expect(stabilizer.settle(.mouse, current: .yarn, now: 8) == nil)
        #expect(stabilizer.settle(.mouse, current: .yarn, now: 9) == .mouse)
    }

    @Test func forgetsCandidateWhenBackToCurrent() {
        var stabilizer = ActivityStabilizer(delay: 5)
        _ = stabilizer.settle(.laser, current: .yarn, now: 0)
        #expect(stabilizer.settle(.yarn, current: .yarn, now: 3) == nil)
        #expect(stabilizer.settle(.laser, current: .yarn, now: 6) == nil)
    }

    @Test func resetClearsCandidate() {
        var stabilizer = ActivityStabilizer(delay: 5)
        _ = stabilizer.settle(.laser, current: .yarn, now: 0)
        stabilizer.reset()
        #expect(stabilizer.settle(.laser, current: .yarn, now: 6) == nil)
    }
}
