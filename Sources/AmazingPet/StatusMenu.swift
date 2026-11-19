import AppKit
import AmazingPetCore

final class StatusMenu: NSObject, NSMenuDelegate {
    let menu = NSMenu()

    private let controller: PetController
    private let settings: Settings
    private let statusItem = NSMenuItem()
    private let metricsItem = NSMenuItem()
    private let strokeItem = NSMenuItem(title: "", action: #selector(strokePet), keyEquivalent: "p")
    private let indicatorsItem = NSMenuItem(title: "", action: #selector(toggleIndicators), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "", action: #selector(toggleLogin), keyEquivalent: "")
    private var modeItems: [(item: NSMenuItem, mode: Mode)] = []
    private var languageItems: [(item: NSMenuItem, language: AppLanguage)] = []
    private var roamItems: [(item: NSMenuItem, minutes: Int)] = []
    private var permissionItems: [(item: NSMenuItem, permission: Permission)] = []
    private var builtSpecies: Species?
    private let onCustomize: () -> Void
    private let onLanguageChange: () -> Void

    init(
        controller: PetController, settings: Settings,
        onCustomize: @escaping () -> Void, onLanguageChange: @escaping () -> Void
    ) {
        self.controller = controller
        self.settings = settings
        self.onCustomize = onCustomize
        self.onLanguageChange = onLanguageChange
        super.init()
        menu.delegate = self
        build()
    }

    private func build() {
        menu.removeAllItems()
        modeItems = []
        languageItems = []
        roamItems = []
        permissionItems = []
        let species = settings.profile.look.species
        builtSpecies = species

        statusItem.isEnabled = false
        metricsItem.isEnabled = false
        menu.addItem(statusItem)
        menu.addItem(metricsItem)
        menu.addItem(.separator())
        strokeItem.target = self
        menu.addItem(strokeItem)
        menu.addItem(action(L10n.customize, #selector(customize), key: ","))
        menu.addItem(.separator())

        let header = NSMenuItem(title: L10n.toyHeader, action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        let modes = [Mode.auto] + species.menuToys.map(Mode.fixed)
        for mode in modes {
            let item = action(title(for: mode), #selector(selectMode(_:)))
            item.indentationLevel = 1
            item.tag = modeItems.count
            modeItems.append((item, mode))
            menu.addItem(item)
        }

        menu.addItem(.separator())
        indicatorsItem.title = L10n.indicators
        indicatorsItem.target = self
        loginItem.title = L10n.launchAtLogin
        loginItem.target = self
        menu.addItem(indicatorsItem)
        menu.addItem(roamMenuItem())
        menu.addItem(permissionsMenuItem())
        menu.addItem(loginItem)
        menu.addItem(languageMenuItem())
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: L10n.quit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private func roamMenuItem() -> NSMenuItem {
        let submenu = NSMenu()
        for minutes in [0, 1, 3, 5, 10] {
            let item = action(minutes == 0 ? L10n.roamOff : L10n.roamAfter(minutes: minutes), #selector(selectRoamDelay(_:)))
            item.tag = minutes
            roamItems.append((item, minutes))
            submenu.addItem(item)
        }
        submenu.addItem(.separator())
        submenu.addItem(action(L10n.roamNow, #selector(roamNow)))
        let item = NSMenuItem(title: L10n.roamMenu, action: nil, keyEquivalent: "")
        item.submenu = submenu
        return item
    }

    private func permissionsMenuItem() -> NSMenuItem {
        let submenu = NSMenu()
        for permission in Permission.allCases {
            let item = action(L10n.title(permission), #selector(requestPermission(_:)))
            item.tag = permissionItems.count
            permissionItems.append((item, permission))
            submenu.addItem(item)
        }
        let item = NSMenuItem(title: L10n.permissionsMenu, action: nil, keyEquivalent: "")
        item.submenu = submenu
        return item
    }

    private func languageMenuItem() -> NSMenuItem {
        let submenu = NSMenu()
        for language in AppLanguage.allCases {
            let item = action(L10n.title(language), #selector(selectLanguage(_:)))
            item.tag = languageItems.count
            languageItems.append((item, language))
            submenu.addItem(item)
        }
        let item = NSMenuItem(title: L10n.languageMenu, action: nil, keyEquivalent: "")
        item.submenu = submenu
        return item
    }

    private func action(_ title: String, _ selector: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: key)
        item.target = self
        return item
    }

    private func title(for mode: Mode) -> String {
        switch mode {
        case .auto: L10n.autoMode
        case .fixed(let activity): L10n.title(activity)
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        let species = settings.profile.look.species
        if species != builtSpecies { build() }
        let name = settings.profile.name
        statusItem.title = L10n.status(controller.activity, name: name)
        strokeItem.title = L10n.stroke(name)
        metricsItem.title = L10n.metrics(controller.status)
        let mode = settings.mode.resolved(for: species)
        for (item, itemMode) in modeItems { item.state = itemMode == mode ? .on : .off }
        for (item, language) in languageItems { item.state = language == settings.language ? .on : .off }
        for (item, minutes) in roamItems { item.state = minutes == settings.roamDelayMinutes ? .on : .off }
        for (item, permission) in permissionItems { item.state = permission.isGranted ? .on : .off }
        indicatorsItem.state = settings.indicatorsEnabled ? .on : .off
        loginItem.state = LoginItem.isEnabled ? .on : .off
    }

    @objc private func strokePet() {
        controller.stroke()
    }

    @objc private func customize() {
        onCustomize()
    }

    @objc private func selectMode(_ sender: NSMenuItem) {
        settings.mode = modeItems[sender.tag].mode
        controller.applySettings()
    }

    @objc private func selectLanguage(_ sender: NSMenuItem) {
        let language = languageItems[sender.tag].language
        settings.language = language
        L10n.language = language
        build()
        onLanguageChange()
    }

    @objc private func selectRoamDelay(_ sender: NSMenuItem) {
        settings.roamDelayMinutes = sender.tag
    }

    @objc private func requestPermission(_ sender: NSMenuItem) {
        permissionItems[sender.tag].permission.request()
    }

    @objc private func roamNow() {
        controller.roamNow()
    }

    @objc private func toggleIndicators() {
        settings.indicatorsEnabled.toggle()
        controller.applySettings()
    }

    @objc private func toggleLogin() {
        do {
            try LoginItem.setEnabled(!LoginItem.isEnabled)
        } catch {
            let alert = NSAlert()
            alert.messageText = L10n.loginErrorTitle
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }
}
