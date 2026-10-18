import AppKit
import BarKit
import CommonKit
import CommonUI
import os

/// The More folder's menu. It is the status item's own menu, so AppKit opens it on the press with
/// the item highlighted, as every menu bar extra does, and it is filled from rows worked out ahead
/// of time, off the main thread: opening it asks no app anything. Only the very first open, before
/// any rows exist, works them out on the spot.
@MainActor
final class FolderMenu: NSObject, NSMenuDelegate {
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
    }

    static let log = Logger(subsystem: "com.oddurs.reasonal", category: "folders")
    private static let askedForAccessKey = "askedForAccessibility"
    private static let family = Set(CommonTool.all.map(\.bundleIdentifier))

    let menu = NSMenu()
    private let inputs: () -> Inputs?
    private let choose: (UInt32) -> Void
    private let fillAppMenu: (NSMenu) -> Void
    private var snapshot: Snapshot?
    private var shown: [FolderEntry.Signature]?
    private var icons: [Int32: NSImage] = [:]
    private var isOpen = false
    private var refreshing = false
    private var refreshAgain = false
    private var timers: [Timer] = []

    /// `inputs` reads where things are; `choose` opens the icon with that window id; `fillAppMenu`
    /// fills the menu a right-click opens.
    init(
        inputs: @escaping () -> Inputs?, choose: @escaping (UInt32) -> Void,
        fillAppMenu: @escaping (NSMenu) -> Void
    ) {
        self.inputs = inputs
        self.choose = choose
        self.fillAppMenu = fillAppMenu
        super.init()
        menu.delegate = self
        menu.autoenablesItems = false
    }

    // MARK: Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        let event = NSApp.currentEvent
        menu.removeAllItems()
        shown = nil
        if event?.type == .rightMouseDown || event?.modifierFlags.contains(.control) == true {
            fillAppMenu(menu)
            return
        }
        let granted = MenuBarController.accessibility.isGranted
        // The first open, and the first after Accessibility is allowed, have no rows to show yet.
        if snapshot == nil || (granted && snapshot?.granted == false), let inputs = inputs() {
            let start = Date()
            snapshot = Self.snapshot(inputs, granted: granted)
            Self.log.notice("first open worked out its rows in \(Self.ms(since: start), privacy: .public) ms")
        }
        let start = Date()
        fill()
        Self.log.notice("filled the menu in \(Self.ms(since: start), privacy: .public) ms")
        refresh()
    }

    func menuWillOpen(_ menu: NSMenu) { isOpen = true }
    func menuDidClose(_ menu: NSMenu) { isOpen = false }

    private func fill() {
        menu.removeAllItems()
        guard let snapshot else { return }
        guard MenuBarController.accessibility.isGranted else {
            addPermissionItems(hiddenCount: snapshot.hiddenCount)
            shown = nil
            return
        }
        if snapshot.entries.isEmpty {
            menu.addItem(
                note(snapshot.hiddenCount == 0 ? "Every icon is in the menu bar." : "No app answered for its icons."))
        }
        for (index, group) in FolderEntry.grouped(snapshot.entries, family: Self.family).enumerated() {
            if index > 0 { menu.addItem(.separator()) }
            for entry in group {
                let row = NSMenuItem(title: entry.name, action: #selector(chosen(_:)), keyEquivalent: "")
                row.target = self
                row.representedObject = entry.id
                row.image = icon(for: entry.owner.pid)
                menu.addItem(row)
            }
        }
        shown = snapshot.entries.map(\.signature)
    }

    private func icon(for pid: Int32) -> NSImage? {
        if let icon = icons[pid] { return icon }
        guard let icon = NSRunningApplication(processIdentifier: pid)?.icon?.copy() as? NSImage else { return nil }
        icon.size = Metric.rowIcon
        icons[pid] = icon
        return icon
    }

    @objc private func chosen(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UInt32 else { return }
        // After the menu has closed, so it isn't taken for the icon's.
        DispatchQueue.main.async { [choose] in choose(id) }
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
        let pids = Set(next.entries.map(\.owner.pid))
        icons = icons.filter { pids.contains($0.key) }
        // Loaded now, so opening the menu never waits for an app's icon.
        for pid in pids { _ = icon(for: pid) }
        if isOpen, let shown, shown != next.entries.map(\.signature) {
            fill()
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

    /// Until Accessibility is allowed, the folder says why it's needed and how, instead of an
    /// empty list. It is asked here, the first time a folder opens, and never at launch.
    private func addPermissionItems(hiddenCount: Int) {
        let permission = MenuBarController.accessibility
        menu.addItem(note("Common Bar needs \(permission.name) access \(permission.reason)."))
        let asked = UserDefaults.standard.bool(forKey: Self.askedForAccessKey)
        let allow = NSMenuItem(
            title: asked ? "Open System Settings…" : "Allow \(permission.name)…", action: #selector(allowAccess),
            keyEquivalent: "")
        allow.target = self
        menu.addItem(allow)
        if asked {
            menu.addItem(.separator())
            menu.addItem(note("\(permission.staleSwitchNote(app: "Common Bar")) Reset and Ask Again clears it."))
            let reset = NSMenuItem(title: "Reset and Ask Again", action: #selector(resetAccess), keyEquivalent: "")
            reset.target = self
            menu.addItem(reset)
        }
        if hiddenCount > 0 {
            menu.addItem(.separator())
            menu.addItem(
                note(hiddenCount == 1 ? "1 icon is in this folder." : "\(hiddenCount) icons are in this folder."))
        }
    }

    /// A line of explanation in a menu: not choosable, and wrapped rather than one long row.
    private func note(_ text: String) -> NSMenuItem {
        let item = NSMenuItem()
        let label = NSTextField(wrappingLabelWithString: text)
        label.textColor = Tokens.Text.secondary.nsColor
        label.font = .menuFont(ofSize: NSFont.smallSystemFontSize)
        label.preferredMaxLayoutWidth = Tokens.Layout.menuPanelWidth - 2 * Tokens.Space.md
        let size = label.fittingSize
        let container = NSView(
            frame: NSRect(x: 0, y: 0, width: size.width + 2 * Tokens.Space.md, height: size.height + Tokens.Space.xs))
        label.frame = NSRect(x: Tokens.Space.md, y: Tokens.Space.xxs, width: size.width, height: size.height)
        container.addSubview(label)
        item.view = container
        item.isEnabled = false
        return item
    }

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
