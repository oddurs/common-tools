import AppKit
import BarKit
import CommonKit
import CommonUI
import os

/// Every folder's dropdown: Common UI's `MenuPanelHost` under the folder, drawing `FolderPanel`. It is
/// filled from rows worked out ahead of time, off the main thread, so opening asks no app anything;
/// only the very first open, before any rows exist, works them out on the spot. `FolderStore` says
/// which folder each icon is in. Why a panel and not a menu is in `docs/design.md`.
@MainActor
final class FolderDropdown: NSObject {
    /// What a folder knows about the icons left of the divider.
    struct Snapshot: Sendable {
        let entries: [FolderEntry]
        let hiddenCount: Int
        /// Worked out with Accessibility allowed. Without it there are no rows, only a count.
        let granted: Bool
    }

    /// Where Common Bar's own items and the menu bar are, read on the main thread for a refresh.
    struct Inputs: Sendable {
        let own: OwnItems
        let geometry: MenuBarGeometry
        let apps: [MenuBarExtras.App]
    }

    private enum Metric {
        static let rowIcon = NSSize(width: 16, height: 16)
        /// Apps put their icons in the menu bar a moment after they launch, some a few seconds after.
        static let afterLaunch: [TimeInterval] = [1, 4]
        /// How long a row says it couldn't open its icon.
        static let failureShown: TimeInterval = 2.5
    }

    static let log = Logger(subsystem: "com.oddurs.commonbar", category: "folders")
    private static let askedForAccessKey = "askedForAccessibility"
    private static let family = Set(CommonTool.all.map(\.bundleIdentifier))

    let model = FolderPanelModel()
    private let host = MenuPanelHost()
    private let store: FolderStore
    private let inputs: () -> Inputs?
    private let choose: (FolderEntry, String) -> Void
    private var snapshot: Snapshot?
    /// The folder whose dropdown is open.
    private(set) var openFolder: String?
    /// The folder opened last, most likely the next.
    private var lastFolder = FolderConfig.moreID
    private var icons: [Int32: NSImage] = [:]
    private var refreshing = false
    private var refreshAgain = false
    private var timers: [Timer] = []

    /// `inputs` reads where things are; `choose` opens an icon from a folder; `edit` opens the folder
    /// manager on a folder; `settings` opens Settings.
    init(
        store: FolderStore, inputs: @escaping () -> Inputs?, choose: @escaping (FolderEntry, String) -> Void,
        edit: @escaping (String) -> Void, settings: @escaping () -> Void
    ) {
        self.store = store
        self.inputs = inputs
        self.choose = choose
        super.init()
        model.icons = { [weak self] pid in self?.icon(for: pid) }
        model.onOpen = { [weak self] row in self?.open(row) }
        model.onEdit = { [weak self] in
            guard let self, let folder = self.openFolder else { return }
            self.close()
            edit(folder)
        }
        model.onSettings = { [weak self] in
            self?.close()
            settings()
        }
        model.onAllow = { [weak self] in self?.allowAccess() }
        model.onReset = { [weak self] in self?.resetAccess() }
        // Built now, so even the first open only orders in a window that is ready.
        host.prepare { FolderPanel(model: model) }
        host.onClose = { [weak self] in
            self?.openFolder = nil
            self?.model.closed()
        }
    }

    /// The rows the last refresh found.
    var entries: [FolderEntry] { snapshot?.entries ?? [] }

    var isOpen: Bool { host.isShown }

    // MARK: Opening the dropdown

    /// Opens the folder's dropdown under its button, or closes it if it is already open, as a second
    /// click on a menu does. `opened` is when the press arrived (`NSEvent.timestamp`), for the log.
    func toggle(_ folderID: String, below button: NSStatusBarButton, pressedAt opened: TimeInterval? = nil) {
        if openFolder == folderID {
            close()
            return
        }
        let work = Date()
        let granted = MenuBarController.accessibility.isGranted
        // The first open, and the first after Accessibility is allowed, have no rows to show yet.
        if snapshot == nil || (granted && snapshot?.granted == false), let inputs = inputs() {
            let start = Date()
            snapshot = Self.snapshot(inputs, granted: granted)
            store.entries = snapshot?.entries ?? []
            Self.log.notice("first open worked out its rows in \(Self.ms(since: start), privacy: .public) ms")
        }
        fill(folderID)
        let filled = Self.ms(since: work)
        model.opened += 1
        openFolder = folderID
        lastFolder = folderID
        if !host.reopen(below: button) { host.show(below: button) { FolderPanel(model: model) } }
        Self.log.notice(
            "opened \(folderID, privacy: .public): \(Self.ms(since: work), privacy: .public) ms of main-thread work (\(filled, privacy: .public) filling), \(self.model.rows.count, privacy: .public) rows"
        )
        if let opened {
            let shown = (ProcessInfo.processInfo.systemUptime - opened) * 1000
            Self.log.notice(
                "opened \(folderID, privacy: .public) \(String(format: "%.1f", shown), privacy: .public) ms after the press"
            )
        }
        refresh()
    }

    func close() {
        host.close()
    }

    /// Fills the model for a folder from the last refresh: its rows in their groups, or why there are none.
    private func fill(_ folderID: String) {
        guard let snapshot else { return }
        // Only what changed is set: every set redraws the panel, which an open should never wait for.
        let name = store.config.folder(folderID)?.name ?? "More"
        if model.folderName != name { model.folderName = name }
        guard MenuBarController.accessibility.isGranted else {
            if !model.rows.isEmpty { model.rows = [] }
            let notice = FolderPanelModel.Notice.permission(
                asked: UserDefaults.standard.bool(forKey: Self.askedForAccessKey), waiting: snapshot.hiddenCount)
            if model.notice != notice { model.notice = notice }
            return
        }
        let entries = store.config.contents(of: snapshot.entries)[folderID] ?? []
        let rows = FolderEntry.grouped(entries, family: Self.family).flatMap { group in
            group.map { entry in
                FolderPanelModel.Row(
                    id: entry.id, name: entry.name, status: Dropdown.status(of: entry.owner),
                    symbol: entry.owner.bundleID?.hasPrefix("com.apple.") == true
                        ? Dropdown.symbol(identifier: entry.owner.identifier, name: entry.name) : nil,
                    pid: entry.owner.pid, group: FolderGroup(bundleID: entry.owner.bundleID, family: Self.family))
            }
        }
        // Unchanged rows aren't replaced, so an open dropdown doesn't redraw under the pointer.
        if model.rows != rows { model.rows = rows }
        let notice: FolderPanelModel.Notice? =
            rows.isEmpty ? .empty(Self.emptyMessage(folderID, snapshot: snapshot)) : nil
        if model.notice != notice { model.notice = notice }
        var selection = model.selection
        selection.settle(count: model.targetCount, filtering: !model.query.isEmpty)
        if selection != model.selection { model.selection = selection }
    }

    private static func emptyMessage(_ folderID: String, snapshot: Snapshot) -> String {
        if folderID != FolderConfig.moreID { return "Nothing in this folder yet. Choose its icons in Settings." }
        if snapshot.hiddenCount == 0 { return "Every icon is in the menu bar." }
        return snapshot.entries.isEmpty ? "No app answered for its icons." : "Every icon is in another folder."
    }

    /// Fills the open dropdown again, as a change of folders needs.
    func refill() {
        if let openFolder { fill(openFolder) }
    }

    private func open(_ row: FolderPanelModel.Row) {
        guard let folder = openFolder, let entry = snapshot?.entries.first(where: { $0.id == row.id }) else { return }
        choose(entry, folder)
    }

    private func icon(for pid: Int32) -> NSImage? {
        if let icon = icons[pid] { return icon }
        guard let icon = NSRunningApplication(processIdentifier: pid)?.icon?.copy() as? NSImage else { return nil }
        icon.size = Metric.rowIcon
        icons[pid] = icon
        return icon
    }

    // MARK: Refreshing

    /// Works out the rows again off the main thread. An open menu changes only if a row did.
    func refresh() {
        guard !refreshing else {
            refreshAgain = true
            return
        }
        guard let inputs = inputs() else { return }
        refreshing = true
        let granted = MenuBarController.accessibility.isGranted
        let start = Date()
        DispatchQueue.global(qos: .userInitiated).async {
            let next = Self.snapshot(inputs, granted: granted)
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self.refreshed(next, started: start) }
            }
        }
    }

    private func refreshed(_ next: Snapshot, started: Date) {
        refreshing = false
        Self.log.notice(
            "refreshed \(next.entries.count, privacy: .public) rows in \(Self.ms(since: started), privacy: .public) ms")
        snapshot = next
        store.entries = next.entries
        let pids = Set(next.entries.map(\.owner.pid))
        icons = icons.filter { pids.contains($0.key) }
        // Loaded now, so opening the menu never waits for an app's icon.
        for pid in pids { _ = icon(for: pid) }
        if let openFolder {
            if model.copy == nil { fill(openFolder) }
        } else {
            // Ready for the next open: the folder opened last, its rows built while nobody waits.
            fill(lastFolder)
            host.settle()
        }
        if refreshAgain {
            refreshAgain = false
            refresh()
        }
    }

    /// Refreshes after each delay, replacing any refresh already waiting: an app launching puts its
    /// icon in the menu bar a little later, and several launching at once need one refresh.
    func refresh(after delays: [TimeInterval]) {
        timers.forEach { $0.invalidate() }
        timers = delays.map { delay in
            Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            }
        }
    }

    func appsChanged() { refresh(after: Metric.afterLaunch) }

    private nonisolated static func snapshot(_ inputs: Inputs, granted: Bool) -> Snapshot {
        let model = MenuBarModel(
            windows: MenuBar.statusItemWindows(), geometry: inputs.geometry, own: inputs.own)
        let hidden = model.items.filter { $0.section == .hidden }.count
        guard granted else { return Snapshot(entries: [], hiddenCount: hidden, granted: false) }
        let entries = model.folderEntries(
            MenuBarExtras.items(of: inputs.apps), ownPID: ProcessInfo.processInfo.processIdentifier)
        return Snapshot(entries: entries, hiddenCount: hidden, granted: true)
    }

    private nonisolated static func ms(since start: Date) -> String {
        String(format: "%.1f", Date().timeIntervalSince(start) * 1000)
    }

    // MARK: Permission

    @objc private func allowAccess() {
        let permission = MenuBarController.accessibility
        if UserDefaults.standard.bool(forKey: Self.askedForAccessKey) {
            NSWorkspace.shared.open(permission.settingsURL)
        } else {
            UserDefaults.standard.set(true, forKey: Self.askedForAccessKey)
            permission.request()
        }
    }

    /// Clears a record left by an earlier copy, whose switch shows on but doesn't apply to this one.
    @objc private func resetAccess() {
        do {
            try MenuBarController.accessibility.resetAndRequest()
        } catch {
            NSApp.activate()
            NSAlert(error: error).runModal()
        }
    }
}

/// How opening an icon shows in its dropdown, so the handoff is continuous: the dropdown stays up
/// while the icon is brought in, gives way as the icon's own menu appears, turns into a copy of the
/// menu in place when the icon can't be brought, and says so in the row when it fails.
@MainActor
protocol OpeningUI: AnyObject {
    func opening(_ id: UInt32)
    /// While true, the clicks Common Bar plays to move an icon don't close the dropdown.
    func holdOpen(_ hold: Bool)
    /// Turns the dropdown into a copy of the icon's menu and returns the item chosen, or nil.
    func showCopy(_ nodes: [MenuNode], for id: UInt32) async -> MenuPath?
    /// The icon's own menu or panel is up: the dropdown gives way.
    func handOff()
    func failed(_ id: UInt32, _ message: String)
}

extension FolderDropdown: OpeningUI {
    func opening(_ id: UInt32) {
        model.failure = nil
        model.busy = id
    }

    func holdOpen(_ hold: Bool) {
        host.holdsOpen = hold
    }

    func showCopy(_ nodes: [MenuNode], for id: UInt32) async -> MenuPath? {
        guard host.isShown, let row = model.rows.first(where: { $0.id == id }) else { return nil }
        return await model.showCopy(nodes, of: row)
    }

    func handOff() {
        host.holdsOpen = false
        close()
    }

    func failed(_ id: UInt32, _ message: String) {
        host.holdsOpen = false
        model.busy = nil
        guard host.isShown else { return }
        model.failure = (id, message)
        Timer.scheduledTimer(withTimeInterval: Metric.failureShown, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                if self?.model.failure?.id == id { self?.model.failure = nil }
            }
        }
    }
}
