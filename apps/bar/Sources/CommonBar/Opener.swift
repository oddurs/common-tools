import AppKit
import BarKit
import os

/// Opens an icon from a folder so its menu appears under that folder, where the folder's own menu
/// was: the icon comes on screen, is ⌘-dragged in beside the folder, pressed, and once what it
/// opened has closed, dragged back into its slot and hidden again. If a drag doesn't land where it
/// should, the icon is pressed wherever it is on screen instead, and left wherever it ends up
/// rather than dragged about blindly. Every step is logged:
///
///     log show --last 5m --predicate 'subsystem == "com.oddurs.commonbar" AND category == "open"'
@MainActor
final class Opener {
    struct Context {
        let divider: DividerItem
        /// Common Bar's own items, from the window server, so they never lag a move.
        let own: () -> OwnItems
        let screen: () -> NSScreen?
        /// The folder's status item, from the window server.
        let folderFrame: (String) -> CGRect?
    }

    private enum Metric {
        static let arrival: TimeInterval = 1.5
        static let landing: TimeInterval = 1.0
        static let poll: TimeInterval = 0.05
        static let watchPoll: TimeInterval = 0.1
    }

    static let log = Logger(subsystem: "com.oddurs.commonbar", category: "open")
    private let context: Context
    private(set) var isBusy = false
    /// The dropdown the icon was chosen in, while it is being opened.
    private weak var ui: OpeningUI?

    /// Says in the dropdown that the icon couldn't be opened, as well as in the log.
    private func fail(_ entry: FolderEntry, _ why: String) {
        Self.log.error("\(entry.name, privacy: .public): \(why, privacy: .public)")
        ui?.failed(entry.id, "Couldn't open \(entry.name)")
    }

    init(_ context: Context) {
        self.context = context
    }

    /// Opens `entry`, moving it in beside the folder with `folderID` first, or where it lands on
    /// screen when that is nil.
    func open(_ entry: FolderEntry, from folderID: String?, ui: OpeningUI?, done: @escaping () -> Void) {
        guard !isBusy else {
            Self.log.notice("busy with another icon; \(entry.name, privacy: .public) not opened")
            return
        }
        isBusy = true
        self.ui = ui
        ui?.opening(entry.id)
        Task {
            await run(entry, from: folderID)
            context.divider.hide()
            isBusy = false
            self.ui = nil
            done()
        }
    }

    private func run(_ entry: FolderEntry, from folderID: String?) async {
        let name = entry.name
        Self.log.notice(
            "opening \(name, privacy: .public) (window \(entry.id, privacy: .public)) \(folderID.map { "beside folder \($0)" } ?? "where it lands", privacy: .public)"
        )
        guard let screen = context.screen(), let dividerEnd = context.own().divider?.maxX else {
            fail(entry, "no screen or divider")
            return
        }
        // Found now, while the icon is at rest where Accessibility thinks it is; the element stays
        // the icon's through every move, while Accessibility's idea of its position lags.
        let model = MenuBar.model(of: screen, own: context.own())
        guard let target = model.items.first(where: { $0.id == entry.id }) else {
            fail(entry, "no longer in the menu bar")
            return
        }
        guard let element = MenuBarExtras.element(pid: entry.owner.pid, at: target.window.frame) else {
            fail(entry, "Accessibility has no item at \(target.window.frame.minX)")
            return
        }
        let slot = model.slot(of: target)?.id

        // On screen first: a press off-screen opens a menu nobody can see that still takes the keyboard.
        // To be moved, it must come where a drag can start, so the divider goes all the way down and
        // the icon lands as far right as it can; one too far down the folder for that opens in place.
        let geometry = MenuBar.geometry(of: screen)
        let between = model.items.filter { $0.section == .hidden && $0.window.frame.minX > target.window.frame.minX }
            .reduce(0) { $0 + $1.window.frame.width }
        let rightmost = dividerEnd - DividerItem.Metric.padding
        let landing = CGRect(
            x: rightmost - between - target.window.frame.width, y: 0, width: target.window.frame.width, height: 1)
        let movable = folderID != nil && Move.reachable(landing, in: geometry)
        if let folderID, !movable {
            Self.log.notice(
                "\(name, privacy: .public) would land at \(landing.minX, privacy: .public), behind the app's menus: too far down the folder to move; copying its menu under the folder"
            )
            if await openCopy(of: entry, element: element, under: folderID, screen: screen) { return }
            Self.log.notice("\(name, privacy: .public) has no menu to copy; opening it in place")
        }
        guard
            let blockEnd = movable
                ? rightmost
                : model.blockEnd(toOpen: target, dividerEnd: dividerEnd, padding: DividerItem.Metric.padding)
        else {
            fail(entry, "can't reach the screen")
            return
        }
        context.divider.show(
            length: DividerLayout.length(
                showingUpTo: blockEnd, dividerEnd: dividerEnd, padding: DividerItem.Metric.padding))
        guard let arrived = await frame(of: entry.id, within: Metric.arrival, where: { Self.onScreen($0, screen) })
        else {
            fail(entry, "never came on screen")
            return
        }
        Self.log.notice("\(name, privacy: .public) on screen at \(arrived.minX, privacy: .public)")

        let barMidY = geometry.top + geometry.height / 2
        var moved = false
        if movable, let folderID, let folder = context.folderFrame(folderID), Move.reachable(arrived, in: geometry) {
            let drag = Move.drag(arrived, toJustLeftOf: folder, barMidY: barMidY)
            // The dropdown stays up through the drag, and gives way when the icon's own menu appears.
            ui?.holdOpen(true)
            await MenuBarDrag.perform(from: drag.from, to: drag.to)
            let landed = await frame(of: entry.id, within: Metric.landing) { frame in
                self.context.folderFrame(folderID).map { Move.landed(frame, justLeftOf: $0) } ?? false
            }
            moved = landed != nil
            Self.log.notice(
                "\(name, privacy: .public) \(moved ? "moved beside the folder" : "didn't land beside the folder; opening it where it is", privacy: .public)"
            )
        }
        // Beside the folder it is right of the divider, so it stays in sight while the rest hide.
        if moved { context.divider.hide() }

        let before = MenuBar.onScreenWindowIDs()
        if let error = await press(
            element, name: name, pid: entry.owner.pid, icon: entry.id, since: before, screen: screen)
        {
            fail(entry, "pressing failed: \(error.rawValue)")
        } else {
            Self.log.notice("pressed \(name, privacy: .public)")
            ui?.handOff()
            var watch = OpenWatch(started: Date())
            var seen = false
            while true {
                let open = MenuBar.somethingOpened(since: before, by: entry.owner.pid, on: screen)
                seen = seen || open
                if watch.update(somethingOpen: open, now: Date()) == .done { break }
                try? await Task.sleep(for: .seconds(Metric.watchPoll))
            }
            Self.log.notice(
                "\(name, privacy: .public) closed; a menu or panel was \(seen ? "seen" : "never seen", privacy: .public)"
            )
        }

        // A drag that missed can still have dropped the icon right of the divider, where it would
        // stay in sight for good; it goes back left of the divider like one that was moved.
        let strayed =
            !moved
            && (MenuBar.frames(of: [entry.id])[entry.id].map { frame in
                context.own().divider.map { frame.minX >= $0.maxX - 1 } ?? false
            } ?? false)
        if strayed { Self.log.notice("\(name, privacy: .public) was dropped in sight by a missed drag") }
        if moved || strayed {
            await putBack(entry, name: name, slot: moved ? slot : nil, screen: screen, barMidY: barMidY)
        }
    }

    /// For an icon too far down a folder to move: reads its menu unseen, turns the dropdown into a
    /// copy of it, and presses the chosen item in the real menu, opened unseen again. Returns false when
    /// the icon has no menu that can be copied, having closed whatever it showed instead.
    private func openCopy(
        of entry: FolderEntry, element: MenuBarExtras.Element, under folderID: String, screen: NSScreen
    ) async -> Bool {
        let name = entry.name
        let pid = entry.owner.pid
        let before = MenuBar.onScreenWindowIDs()
        guard let ui else { return false }
        guard let nodes = await MenuBarExtras.readMenu(element), MenuCopy.copyable(nodes) else {
            await MenuBarExtras.close(element) { !MenuBar.opened(since: before, by: pid).isEmpty }
            return false
        }
        Self.log.notice(
            "read \(nodes.count, privacy: .public) items from \(name, privacy: .public)'s menu; showing them under the folder"
        )
        guard let path = await ui.showCopy(nodes, for: entry.id) else {
            Self.log.notice("\(name, privacy: .public)'s copied menu closed with nothing chosen")
            return true
        }
        ui.opening(entry.id)
        let found = await MenuBarExtras.choose(path, in: element)
        if found {
            ui.handOff()
        } else {
            ui.failed(entry.id, "Couldn't find \(path.steps.last?.title ?? "it") in \(name)")
        }
        Self.log.notice(
            "\(name, privacy: .public): \(found ? "chose" : "couldn't find", privacy: .public) \(path.steps.map(\.title).joined(separator: " › "), privacy: .public) in the real menu"
        )
        return true
    }

    /// Presses the icon. The app that owns it places its menu or popover from its own idea of where
    /// the icon is, which lags behind a move until the app next hears from it: the first press of a
    /// moved icon can open a menu where the icon used to be, off-screen, or a popover pinned to the
    /// screen's edge. Then that is closed at once (cancelled, or toggled shut by a second press if
    /// it won't cancel) and the icon pressed again, by which time the app knows where it is.
    private func press(
        _ element: MenuBarExtras.Element, name: String, pid: Int32, icon iconID: UInt32, since before: Set<UInt32>,
        screen: NSScreen
    ) async -> AXError? {
        if let error = await Task.detached(operation: { MenuBarExtras.press(element) }).value { return error }
        let end = Date().addingTimeInterval(Metric.landing)
        while Date() < end {
            let opened = MenuBar.opened(since: before, by: pid)
            if let first = opened.first, let icon = MenuBar.frames(of: [iconID])[iconID] {
                let placed = opened.contains {
                    Move.opened($0, under: icon, screenMinX: screen.frame.minX, screenMaxX: screen.frame.maxX)
                }
                guard !placed else { return nil }
                Self.log.notice(
                    "\(name, privacy: .public) opened at \(first.minX, privacy: .public), away from its icon at \(icon.minX, privacy: .public); closing it and pressing again"
                )
                await Task.detached { MenuBarExtras.cancelMenu(of: element) }.value
                try? await Task.sleep(for: .seconds(Metric.poll * 2))
                if !MenuBar.opened(since: before, by: pid).isEmpty {
                    // A popover doesn't cancel; pressing its icon again closes it, once it has
                    // finished animating away.
                    _ = await Task.detached(operation: { MenuBarExtras.press(element) }).value
                    let gone = Date().addingTimeInterval(Metric.landing)
                    while Date() < gone, !MenuBar.opened(since: before, by: pid).isEmpty {
                        try? await Task.sleep(for: .seconds(Metric.poll))
                    }
                }
                return await Task.detached(operation: { MenuBarExtras.press(element) }).value
            }
            try? await Task.sleep(for: .seconds(Metric.poll))
        }
        return nil
    }

    /// Drags the icon back left of the icon that was right of it, where it came from. With the
    /// divider all the way down that icon comes as far right as it can; if it still lands behind the
    /// app's menus, where a drop isn't safe, or the drop misses, the icon goes left of the divider
    /// instead: off-screen again, nearer the folder than it was.
    private func putBack(_ entry: FolderEntry, name: String, slot: UInt32?, screen: NSScreen, barMidY: CGFloat) async {
        let geometry = MenuBar.geometry(of: screen)
        context.divider.show(length: 0)
        var neighbour: (id: UInt32?, frame: CGRect)?
        if let slot, let frame = await frame(of: slot, within: Metric.arrival, where: { Self.onScreen($0, screen) }),
            Move.reachable(frame, in: geometry)
        {
            neighbour = (slot, frame)
        } else {
            try? await Task.sleep(for: .seconds(Metric.poll * 4))
            if let divider = context.own().divider { neighbour = (nil, divider) }
        }
        if await drop(entry, name: name, leftOf: neighbour, barMidY: barMidY) { return }
        if neighbour?.id != nil, let divider = context.own().divider {
            Self.log.notice("\(name, privacy: .public) didn't land in its slot; putting it left of the divider")
            if await drop(entry, name: name, leftOf: (nil, divider), barMidY: barMidY) { return }
        }
        Self.log.error("\(name, privacy: .public) couldn't be put back; it stays beside the folder")
    }

    /// Drags the icon to just left of `neighbour` (another icon by id, or the divider) and says
    /// whether the window list shows it there.
    private func drop(
        _ entry: FolderEntry, name: String, leftOf neighbour: (id: UInt32?, frame: CGRect)?, barMidY: CGFloat
    ) async -> Bool {
        guard let neighbour, let current = MenuBar.frames(of: [entry.id])[entry.id] else { return false }
        let drag = Move.drag(current, toJustLeftOf: neighbour.frame, barMidY: barMidY)
        await MenuBarDrag.perform(from: drag.from, to: drag.to)
        let back = await frame(of: entry.id, within: Metric.landing) { frame in
            let right = neighbour.id.flatMap { MenuBar.frames(of: [$0])[$0] } ?? self.context.own().divider
            return right.map { Move.landed(frame, justLeftOf: $0) } ?? false
        }
        Self.log.notice(
            "\(name, privacy: .public) \(back != nil ? "put back" : "missed", privacy: .public) left of \(neighbour.id.map { "window \($0)" } ?? "the divider", privacy: .public)"
        )
        return back != nil
    }

    /// The window's frame once `condition` holds, polling until `timeout`.
    private func frame(of id: UInt32, within timeout: TimeInterval, where condition: (CGRect) -> Bool) async -> CGRect?
    {
        let end = Date().addingTimeInterval(timeout)
        while Date() < end {
            if let frame = MenuBar.frames(of: [id])[id], condition(frame) { return frame }
            try? await Task.sleep(for: .seconds(Metric.poll))
        }
        return nil
    }

    private static func onScreen(_ frame: CGRect, _ screen: NSScreen) -> Bool {
        frame.minX >= screen.frame.minX && frame.maxX <= screen.frame.maxX
    }
}
