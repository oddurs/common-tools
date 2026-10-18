import AppKit
import BarKit
import CommonKit
import CommonUI

/// Two status items, right to left: the More folder, and a divider left of it that stays stretched
/// so every icon left of it is off-screen, all the time. Nothing is ever revealed in the menu bar,
/// so nothing lands under the notch and nothing reshuffles. The folder lists those icons; choosing
/// one brings it on screen beside the notch just long enough to open it.
@MainActor
final class MenuBarController: NSObject {
    private enum Metric {
        /// Long enough for macOS to finish moving the icons.
        static let settleDelay: TimeInterval = 0.6
        static let pollInterval: TimeInterval = 0.05
        /// How long an icon may take to come on screen before opening it is given up.
        static let arrivalTimeout: TimeInterval = 1.5
    }

    static let accessibility = Permission.accessibility(reason: "to see which app each icon belongs to and open it")
    /// Whether a folder shows its name beside its symbol. On to start with.
    static let showsFolderNamesKey = "showsFolderNames"

    private let folder: NSStatusItem
    private let divider: DividerItem
    private var folderMenu: FolderMenu!
    private var settleTimer: Timer?
    private var opening: Opening?
    private var openTimer: Timer?
    private var observers: [Any] = []
    private let settings = SettingsWindowHost(title: "Common Bar Settings")
    private let updates = UpdateCheck(tool: CommonTool.thisApp!)

    override init() {
        // Once, before anything observes the defaults: registering posts a change notification.
        UserDefaults.standard.register(defaults: [Self.showsFolderNamesKey: true])
        Self.seedPositions()
        DividerItem.markVisible(ItemName.toggle)
        folder = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        divider = DividerItem(named: ItemName.divider)
        super.init()

        folder.autosaveName = ItemName.toggle
        folder.button?.image = NSImage(systemSymbolName: "ellipsis.circle", accessibilityDescription: "More")
        folder.button?.imagePosition = .imageLeading
        folderMenu = FolderMenu(
            inputs: { [weak self] in self?.folderInputs },
            choose: { [weak self] id in self?.open(id) },
            fillAppMenu: { [weak self] menu in self?.fillAppMenu(menu) })
        // The status item's own menu: AppKit opens it on the press, highlighted, with no click of ours.
        folder.menu = folderMenu.menu
        showFolderName()

        // The divider's right end moves as pinned icons come and go and as screens change, and the
        // folder can be ⌘-dragged, which rewrites its saved position.
        let center = NotificationCenter.default
        let workspace = NSWorkspace.shared.notificationCenter
        observers = [
            center.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) {
                [weak self] _ in
                MainActor.assumeIsolated {
                    self?.showFolderName()
                    self?.apply()
                }
            },
            center.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.apply()
                    self?.folderMenu.refresh(after: [Metric.settleDelay])
                }
            },
            workspace.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main) {
                [weak self] _ in
                MainActor.assumeIsolated {
                    self?.scheduleSettle()
                    self?.folderMenu.appsChanged()
                }
            },
            workspace.addObserver(
                forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.scheduleSettle()
                    self?.folderMenu.appsChanged()
                }
            },
        ]

        apply()
        // Once the divider has pushed the icons away, so the first open of More finds rows waiting;
        // again a little later, since at launch the divider may not be laid out by the first.
        folderMenu.refresh(after: [Metric.settleDelay, 3])
    }

    private static func positionKey(_ name: String) -> String {
        "NSStatusItem Preferred Position \(name)"
    }

    private static func savedPosition(of name: String) -> Double? {
        UserDefaults.standard.object(forKey: positionKey(name)) == nil
            ? nil : UserDefaults.standard.double(forKey: positionKey(name))
    }

    /// Writes a starting position for each item macOS hasn't saved one for yet.
    private static func seedPositions() {
        let seeded = ItemPositions.seeded(
            toggle: savedPosition(of: ItemName.toggle), divider: savedPosition(of: ItemName.divider))
        for (name, position) in [(ItemName.toggle, seeded.toggle), (ItemName.divider, seeded.divider)]
        where savedPosition(of: name) == nil {
            UserDefaults.standard.set(position, forKey: positionKey(name))
        }
    }

    private static var positions: ItemPositions {
        ItemPositions(
            toggle: savedPosition(of: ItemName.toggle) ?? 0, divider: savedPosition(of: ItemName.divider) ?? 1)
    }

    // MARK: Layout

    /// Keeps everything left of the divider off-screen, unless an icon is out being opened.
    private func apply() {
        guard opening == nil else { return }
        if Self.positions.dividerHides { divider.hide() } else { divider.takeDown() }
        scheduleSettle()
    }

    /// Once macOS has moved the icons, makes sure none was left on screen.
    private func scheduleSettle() {
        settleTimer?.invalidate()
        settleTimer = Timer.scheduledTimer(withTimeInterval: Metric.settleDelay, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.opening == nil else { return }
                self.divider.keepClearingScreen()
            }
        }
    }

    /// Common Bar's items where the window server has them, so they aren't mistaken for another
    /// app's: on macOS 26 their windows carry no name Common Bar can read.
    private var ownItems: OwnItems {
        OwnItems(
            divider: divider.frame.map(MenuBar.windowServerFrame),
            others: [folder.button?.window?.frame].compactMap { $0.map(MenuBar.windowServerFrame) })
    }

    private var screen: NSScreen? { folder.button?.window?.screen ?? NSScreen.main }

    // MARK: Folder

    private var folderInputs: FolderMenu.Inputs? {
        guard let screen else { return nil }
        let apps = NSWorkspace.shared.runningApplications.map {
            MenuBarExtras.App(pid: $0.processIdentifier, bundleID: $0.bundleIdentifier, name: $0.localizedName ?? "")
        }
        return FolderMenu.Inputs(own: ownItems, geometry: MenuBar.geometry(of: screen), apps: apps)
    }

    /// The folder's name beside its symbol, unless Settings says not to.
    private func showFolderName() {
        let title = UserDefaults.standard.bool(forKey: Self.showsFolderNamesKey) ? "More" : ""
        if folder.button?.title != title { folder.button?.title = title }
    }

    /// The menu a right-click or ⌃-click on the folder opens.
    private func fillAppMenu(_ menu: NSMenu) {
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(title: "Quit Common Bar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    // MARK: Opening

    /// An icon brought on screen to be opened, until what it opened closes.
    private struct Opening {
        let target: UInt32
        let started: Date
        var pressed: (pid: Int32, before: Set<UInt32>, watch: OpenWatch)?
    }

    private func open(_ id: UInt32) {
        guard opening == nil, let screen, let end = divider.frame.map(MenuBar.windowServerFrame)?.maxX else { return }
        let model = MenuBar.model(of: screen, own: ownItems)
        guard let target = model.items.first(where: { $0.id == id }),
            let blockEnd = model.blockEnd(toOpen: target, dividerEnd: end, padding: DividerItem.Metric.padding)
        else {
            NSSound.beep()
            return
        }
        opening = Opening(target: id, started: Date())
        divider.show(
            length: DividerLayout.length(showingUpTo: blockEnd, dividerEnd: end, padding: DividerItem.Metric.padding))
        let timer = Timer(timeInterval: Metric.pollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.stepOpening() }
        }
        RunLoop.main.add(timer, forMode: .common)
        openTimer = timer
    }

    private func stepOpening() {
        guard opening == nil || !followOpening() else { return }
        openTimer?.invalidate()
        openTimer = nil
        opening = nil
        apply()
        folderMenu.refresh(after: [Metric.settleDelay])
    }

    /// One step of opening an icon: wait for it to arrive on screen, press it, then wait for its
    /// menu or popover to close. Returns false when done.
    private func followOpening() -> Bool {
        guard var opening, let screen else { return false }
        let now = Date()
        if var pressed = opening.pressed {
            let open = MenuBar.somethingOpened(since: pressed.before, by: pressed.pid, on: screen)
            let phase = pressed.watch.update(somethingOpen: open, now: now)
            opening.pressed = pressed
            self.opening = opening
            return phase != .done
        }

        let model = MenuBar.model(of: screen, own: ownItems)
        // Pressed only once all of it is on screen: a menu opened off-screen can't be seen and
        // still takes the keyboard.
        guard let target = model.items.first(where: { $0.id == opening.target }),
            target.window.frame.minX >= model.geometry.minX, target.window.frame.maxX <= model.geometry.maxX
        else {
            return now.timeIntervalSince(opening.started) < Metric.arrivalTimeout
        }
        // Asked again: Accessibility's frames moved with the icon.
        guard
            let owner = model.folderEntries(Self.accessibleItems(), ownPID: Self.ownPID)
                .first(where: { $0.id == target.id })?.owner
        else { return false }
        let before = MenuBar.onScreenWindowIDs()
        guard MenuBarExtras.press(pid: owner.pid, at: target.window.frame) else { return false }
        opening.pressed = (owner.pid, before, OpenWatch(started: now))
        self.opening = opening
        return true
    }

    private static let ownPID = ProcessInfo.processInfo.processIdentifier

    /// Every running app's menu bar items, as Accessibility describes them.
    private static func accessibleItems() -> [AccessibleItem] {
        let apps = NSWorkspace.shared.runningApplications.map {
            MenuBarExtras.App(pid: $0.processIdentifier, bundleID: $0.bundleIdentifier, name: $0.localizedName ?? "")
        }
        return MenuBarExtras.items(of: apps)
    }

    @objc func showSettings() {
        settings.show { SettingsView(updates: updates) }
    }
}

extension MenuBarController: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Welcome.showIfNeeded(
            WelcomeInfo(line: "Keeps your menu bar tidy. The icons you rarely use wait in the More folder."))
        updates.start()
    }

    /// Opening the app again while it runs is how people look for its settings.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }
}
