import AppKit
import AmazingPetCore

final class RoamController {
    private static let pixel: CGFloat = 4
    private static let fps = 15.0
    private static let scanInterval = 1.0

    private let settings: Settings
    private let onFinish: () -> Void
    private var window: NSWindow?
    private var view: PetView?
    private var simulation: PetSimulation?
    private var stage = Stage.menuBar
    private var director = RoamDirector()
    private var timer: Timer?
    private var startedAt = 0.0
    private var lastTick = 0.0
    private var lastScan = 0.0
    private var windowRects: [CGRect] = []

    var isRoaming: Bool { window != nil }

    init(settings: Settings, onFinish: @escaping () -> Void) {
        self.settings = settings
        self.onFinish = onFinish
    }

    func start(spawnX: CGFloat?) {
        guard !isRoaming, let screen = NSScreen.screens.first else { return }
        let area = screen.visibleFrame
        stage = Stage.roam(width: area.width / Self.pixel, height: area.height / Self.pixel)
        let size = NSSize(width: stage.width * Self.pixel, height: stage.height * Self.pixel)
        let frame = NSRect(x: area.minX, y: area.maxY - size.height, width: size.width, height: size.height)
        let view = PetView(frame: NSRect(origin: .zero, size: size), stage: stage, pixel: Self.pixel)
        let window = Self.makeWindow(frame: frame)
        window.contentView = view

        let now = CACurrentMediaTime()
        director = RoamDirector(now: now)
        let simulation = PetSimulation(stage: stage, activity: director.current, look: settings.profile.look)
        simulation.drop(atCenter: ((spawnX ?? frame.midX) - frame.minX) / Self.pixel)
        self.simulation = simulation
        self.window = window
        self.view = view
        startedAt = now
        lastTick = now
        scan(now: now)
        tick()
        window.orderFrontRegardless()
        timer = RepeatingTimer.make(interval: 1 / Self.fps) { [weak self] in self?.tick() }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        window?.orderOut(nil)
        window = nil
        view = nil
        simulation = nil
    }

    private func tick() {
        guard let simulation, let view else { return }
        let now = CACurrentMediaTime()
        let idle = UserIdle.seconds
        if AwayPolicy.userReturned(idleSeconds: idle, roamingFor: now - startedAt) {
            stop()
            onFinish()
            return
        }
        if now - lastScan >= Self.scanInterval { scan(now: now) }
        let available = RoamDirector.availableGames(in: simulation.world, on: stage, species: simulation.look.species)
        if let next = director.update(now: now, idleSeconds: idle, available: available) { simulation.setActivity(next) }
        simulation.step(min(now - lastTick, 0.25))
        lastTick = now
        view.setOcclusion(Array(windowRects.prefix(simulation.hidingWindows)))
        view.render(simulation.snapshot())
    }

    private func scan(now: Double) {
        guard let window, let simulation, let view else { return }
        lastScan = now
        let result = WindowScanner.scan(overlay: window.frame, stage: stage, pixel: Self.pixel)
        simulation.world = result.world
        windowRects = result.maskRects
        view.setOcclusion(Array(windowRects.prefix(simulation.hidingWindows)))
    }

    private static func makeWindow(frame: NSRect) -> NSWindow {
        let window = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        return window
    }
}
