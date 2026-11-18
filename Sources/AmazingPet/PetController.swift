import AppKit
import AmazingPetCore

final class PetController {
    private static let sampleInterval = 2.0

    private let view: PetView
    private let settings: Settings
    private let simulation = PetSimulation()
    private let sampler = SystemSampler()
    private var stabilizer = ActivityStabilizer()
    private var frameTimer: Timer?
    private var sampleTimer: Timer?
    private var lastTick = CACurrentMediaTime()
    private lazy var roam = RoamController(settings: settings) { [weak self] in self?.roamDidFinish() }

    private(set) var status = SystemStatus()
    var activity: Activity { simulation.activity }

    init(view: PetView, settings: Settings) {
        self.view = view
        self.settings = settings
        simulation.look = settings.profile.look
    }

    func setLook(_ look: PetLook) {
        simulation.look = look
    }

    func start() {
        guard sampleTimer == nil else { return }
        status = sampler.sample(now: CACurrentMediaTime())
        applySettings()
        lastTick = CACurrentMediaTime()
        scheduleFrameTimer()
        sampleTimer = RepeatingTimer.make(interval: Self.sampleInterval) { [weak self] in self?.sample() }
    }

    func stop() {
        frameTimer?.invalidate()
        sampleTimer?.invalidate()
        frameTimer = nil
        sampleTimer = nil
        roam.stop()
        view.isHidden = false
    }

    func roamNow() {
        beginRoam()
    }

    private func beginRoam() {
        guard !roam.isRoaming else { return }
        frameTimer?.invalidate()
        frameTimer = nil
        let spawnX = view.window?.frame.midX
        view.isHidden = true
        roam.start(spawnX: spawnX)
    }

    private func roamDidFinish() {
        view.isHidden = false
        lastTick = CACurrentMediaTime()
        scheduleFrameTimer()
    }

    func stroke() {
        simulation.stroke()
    }

    func applySettings() {
        stabilizer.reset()
        simulation.speed = ActivityPolicy.speed(for: status, mode: settings.mode)
        switchTo(wantedActivity())
    }

    private func wantedActivity() -> Activity {
        ActivityPolicy.activity(for: status, mode: settings.mode, indicators: settings.indicatorsEnabled)
    }

    private func sample() {
        let now = CACurrentMediaTime()
        status = sampler.sample(now: now)
        simulation.speed = ActivityPolicy.speed(for: status, mode: settings.mode)
        if let next = stabilizer.settle(wantedActivity(), current: activity, now: now) {
            switchTo(next)
        }
        if !roam.isRoaming, AwayPolicy.shouldRoam(status, delayMinutes: settings.roamDelayMinutes) {
            beginRoam()
        }
    }

    private func switchTo(_ next: Activity) {
        guard next != activity else { return }
        simulation.setActivity(next)
        if frameTimer != nil { scheduleFrameTimer() }
    }

    private func scheduleFrameTimer() {
        frameTimer?.invalidate()
        frameTimer = RepeatingTimer.make(interval: 1 / activity.fps) { [weak self] in self?.tick() }
    }

    private func tick() {
        let now = CACurrentMediaTime()
        simulation.step(min(now - lastTick, 0.25))
        lastTick = now
        view.render(simulation.snapshot())
    }
}
