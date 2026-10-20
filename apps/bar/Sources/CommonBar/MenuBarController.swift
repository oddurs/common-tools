import AppKit
import BarKit
import CommonKit
import CommonUI
import os

/// The folders, More and any the user adds, each its own status item, and a divider left of them
/// that stays stretched so every icon left of it is off-screen, all the time. Nothing is ever
/// revealed in the menu bar, so nothing lands under the notch and nothing reshuffles. Each folder
/// lists its icons; choosing one opens it under that folder (`Opener`).
@MainActor
final class MenuBarController: NSObject {
    private enum Metric {
        /// Long enough for macOS to finish moving the icons.
        static let settleDelay: TimeInterval = 0.6
    }

    static let accessibility = Permission.accessibility(reason: "to see which app each icon belongs to and open it")
    /// Whether a folder shows its name beside its symbol. On to start with.
    static let showsFolderNamesKey = "showsFolderNames"
    /// Whether an icon opened from a folder is moved in beside it first. On to start with.
    static let opensBesideFolderKey = "opensBesideFolder"

    private let divider: DividerItem
    private let store = FolderStore()
    /// Each folder's status item, by folder id.
    private var folders: [String: NSStatusItem] = [:]
    /// The window server's id for each of Common Bar's own items, found once AppKit agrees on where
    /// the item is. AppKit's frame lags behind a length change; this doesn't.
    private var windowIDs: [ObjectIdentifier: UInt32] = [:]
    private var folderMenu: FolderDropdown!
    private var opener: Opener!
    private var settleTimer: Timer?
    private var observers: [Any] = []
    private let settings = SettingsWindowHost(title: "Common Bar Settings")
    private let updates = UpdateCheck(tool: CommonTool.thisApp!)

    override init() {
        // Once, before anything observes the defaults: registering posts a change notification.
        UserDefaults.standard.register(defaults: [Self.showsFolderNamesKey: true, Self.opensBesideFolderKey: true])
        Self.seedPositions()
        divider = DividerItem(named: ItemName.divider)
        super.init()

        folderMenu = FolderDropdown(
            store: store, inputs: { [weak self] in self?.folderInputs },
            choose: { [weak self] entry, folderID in self?.open(entry, from: folderID) },
            edit: { [weak self] _ in self?.showSettings() },
            settings: { [weak self] in self?.showSettings() })
        opener = Opener(
            Opener.Context(
                divider: divider, own: { [weak self] in self?.ownItems ?? OwnItems(divider: nil) },
                screen: { [weak self] in self?.screen },
                folderFrame: { [weak self] id in self?.folders[id].flatMap { self?.windowServerFrame(of: $0) } }))
        store.onChange = { [weak self] old in self?.foldersChanged(from: old) }
        syncFolders(reorder: false)

        // The divider's right end moves as pinned icons come and go and as screens change, and a
        // folder can be ⌘-dragged, which rewrites its saved position.
        let center = NotificationCenter.default
        let workspace = NSWorkspace.shared.notificationCenter
        observers = [
            center.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) {
                [weak self] _ in
                MainActor.assumeIsolated {
                    self?.showFolderNames()
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
        // Once the divider has pushed the icons away, so the first open of a folder finds rows
        // waiting; again a little later, since at launch the divider may not be laid out by the first.
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

    // MARK: Folders

    /// Makes, removes, and refreshes folders' status items to match the store. `reorder` writes
    /// new positions and makes every folder again, which is how a status item moves.
    private func syncFolders(reorder: Bool) {
        let config = store.config
        let ids = config.folders.map(\.id)
        let more = Self.savedPosition(of: ItemName.toggle) ?? 0
        let positions = FolderPositions.positions(ids, more: more)
        for (id, item) in folders where reorder ? id != FolderConfig.moreID : !ids.contains(id) {
            NSStatusBar.system.removeStatusItem(item)
            windowIDs[ObjectIdentifier(item)] = nil
            folders[id] = nil
        }
        for folder in config.folders where folders[folder.id] == nil {
            let name = ItemName.folder(folder.id)
            if folder.id != FolderConfig.moreID, reorder || Self.savedPosition(of: name) == nil,
                let position = positions[folder.id]
            {
                UserDefaults.standard.set(position, forKey: Self.positionKey(name))
            }
            DividerItem.markVisible(name)
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.autosaveName = name
            item.button?.imagePosition = .imageLeading
            // Its dropdown opens on the press, as a menu bar extra's menu does.
            item.button?.target = self
            item.button?.action = #selector(folderPressed(_:))
            item.button?.sendAction(on: [.leftMouseDown, .rightMouseDown])
            item.button?.identifier = NSUserInterfaceItemIdentifier(folder.id)
            folders[folder.id] = item
        }
        for folder in config.folders {
            folders[folder.id]?.button?.image = NSImage(
                systemSymbolName: folder.symbol, accessibilityDescription: folder.name)
        }
        showFolderNames()
    }

    private func foldersChanged(from old: FolderConfig) {
        syncFolders(reorder: old.folders.map(\.id) != store.config.folders.map(\.id))
        folderMenu.refill()
        apply()
    }

    /// Each folder's name beside its symbol, unless Settings says not to.
    private func showFolderNames() {
        let names = UserDefaults.standard.bool(forKey: Self.showsFolderNamesKey)
        for folder in store.config.folders {
            let title = names ? folder.name : ""
            if folders[folder.id]?.button?.title != title { folders[folder.id]?.button?.title = title }
        }
    }

    // MARK: Layout

    /// Keeps everything left of the divider off-screen, unless an icon is out being opened.
    private func apply() {
        guard !opener.isBusy else { return }
        let positions = ItemPositions(
            toggle: Self.savedPosition(of: ItemName.toggle) ?? 0, divider: Self.savedPosition(of: ItemName.divider) ?? 1
        )
        let folderPositions = store.config.folders.compactMap { Self.savedPosition(of: ItemName.folder($0.id)) }
        if positions.dividerHides(folders: folderPositions) { divider.hide() } else { divider.takeDown() }
        scheduleSettle()
    }

    /// Once macOS has moved the icons, makes sure none was left on screen.
    private func scheduleSettle() {
        settleTimer?.invalidate()
        settleTimer = Timer.scheduledTimer(withTimeInterval: Metric.settleDelay, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, !self.opener.isBusy else { return }
                self.divider.keepClearingScreen()
            }
        }
    }

    /// Where the window server has one of Common Bar's items, found by its id once AppKit and the
    /// window server first agree on where it is.
    private func windowServerFrame(of item: NSStatusItem) -> CGRect? {
        let key = ObjectIdentifier(item)
        if let id = windowIDs[key], let frame = MenuBar.frames(of: [id])[id] { return frame }
        guard let window = item.button?.window, let screen = window.screen,
            let id = MenuBar.statusItemID(at: window.frame, on: screen)
        else { return nil }
        windowIDs[key] = id
        return MenuBar.frames(of: [id])[id]
    }

    /// Common Bar's items where the window server has them, so they aren't mistaken for another
    /// app's: on macOS 26 their windows carry no name Common Bar can read.
    private var ownItems: OwnItems {
        OwnItems(
            divider: windowServerFrame(of: divider.item),
            others: folders.values.compactMap { windowServerFrame(of: $0) })
    }

    private var screen: NSScreen? {
        folders[FolderConfig.moreID]?.button?.window?.screen ?? NSScreen.main
    }

    private var folderInputs: FolderDropdown.Inputs? {
        guard let screen else { return nil }
        let apps = NSWorkspace.shared.runningApplications.map {
            MenuBarExtras.App(pid: $0.processIdentifier, bundleID: $0.bundleIdentifier, name: $0.localizedName ?? "")
        }
        return FolderDropdown.Inputs(own: ownItems, geometry: MenuBar.geometry(of: screen), apps: apps)
    }

    /// A press on a folder: its dropdown, or with a right-click or ⌃-click, the app's own menu.
    @objc private func folderPressed(_ button: NSStatusBarButton) {
        guard let id = button.identifier?.rawValue else { return }
        let event = NSApp.currentEvent
        if event?.type == .rightMouseDown || event?.modifierFlags.contains(.control) == true {
            folderMenu.close()
            showAppMenu(below: button)
            return
        }
        folderMenu.toggle(id, below: button, pressedAt: event?.timestamp)
    }

    /// Settings… and Quit, as a real menu under the folder.
    private func showAppMenu(below button: NSStatusBarButton) {
        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(title: "Quit Common Bar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + Tokens.Space.xxs), in: button)
    }

    // MARK: Opening

    private func open(_ entry: FolderEntry, from folderID: String) {
        let beside = UserDefaults.standard.bool(forKey: Self.opensBesideFolderKey)
        opener.open(entry, from: beside ? folderID : nil, ui: folderMenu) { [weak self] in
            self?.apply()
            self?.folderMenu.refresh(after: [Metric.settleDelay])
        }
    }

    @objc func showSettings() {
        settings.show { SettingsView(store: store, updates: updates) }
    }
}

extension MenuBarController: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        LegacyIdentity.followLoginItem()
        Welcome.showIfNeeded(
            WelcomeInfo(line: "Keeps your menu bar tidy. The icons you rarely use wait in folders."))
        updates.start()
    }

    /// Opening the app again while it runs is how people look for its settings.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }
}
