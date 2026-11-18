import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = Settings()
    private var statusItem: NSStatusItem!
    private var controller: PetController!
    private var statusMenu: StatusMenu!
    private var petBuilder: PetBuilderWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        L10n.language = settings.language
        statusItem = NSStatusBar.system.statusItem(withLength: PetView.menuBarSize.width + 8)
        let button = statusItem.button!
        button.setAccessibilityLabel(L10n.appName)
        let petView = PetView(frame: button.bounds)
        petView.autoresizingMask = [.width, .height]
        button.addSubview(petView)

        controller = PetController(view: petView, settings: settings)
        petBuilder = PetBuilderWindow(settings: settings) { [weak self] look in self?.controller.setLook(look) }
        statusMenu = StatusMenu(
            controller: controller, settings: settings,
            onCustomize: { [weak self] in self?.petBuilder.show() },
            onLanguageChange: { [weak self] in self?.petBuilder.reload() }
        )
        statusItem.menu = statusMenu.menu

        LoginItem.enableOnFirstInstall(settings)
        observeScreenSleep()
        controller.start()
        if !settings.didCreatePet { petBuilder.show() }
    }

    private func observeScreenSleep() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self, selector: #selector(screensDidSleep), name: NSWorkspace.screensDidSleepNotification, object: nil)
        center.addObserver(self, selector: #selector(screensDidWake), name: NSWorkspace.screensDidWakeNotification, object: nil)
    }

    @objc private func screensDidSleep() { controller.stop() }
    @objc private func screensDidWake() { controller.start() }
}
