import AppKit
import BarKit

/// Reading an icon's menu through Accessibility, and choosing an item in it, without the menu ever
/// being seen: pressed where the icon is, off-screen, the menu opens off-screen too. Used for an
/// icon too far down a folder to be moved beside it.
extension MenuBarExtras {
    private static let menuWait: TimeInterval = 0.8
    private static let menuPoll: useconds_t = 20_000

    /// Opens the icon's menu where the icon is, reads it, and closes it. Nil when no menu opened
    /// in time: the icon shows a panel or popover instead, or nothing.
    nonisolated static func readMenu(_ item: Element) async -> [MenuNode]? {
        // The app may answer the press only once its menu closes, so it isn't waited for.
        Task.detached { _ = press(item) }
        guard let menu = await waitForMenu(of: item) else { return nil }
        let nodes = self.nodes(of: menu.element)
        AXUIElementPerformAction(menu.element, kAXCancelAction as CFString)
        return nodes
    }

    /// Opens the icon's menu unseen again and presses the item at `path` in it. Returns whether it
    /// found the item.
    nonisolated static func choose(_ path: MenuPath, in item: Element) async -> Bool {
        Task.detached { _ = press(item) }
        guard var menu = await waitForMenu(of: item)?.element else { return false }
        for (depth, step) in path.steps.enumerated() {
            let rows = value(menu, kAXChildrenAttribute) as? [AXUIElement] ?? []
            guard let i = MenuPath.find(step, in: rows.map { string($0, kAXTitleAttribute) ?? "" }) else {
                AXUIElementPerformAction(menu, kAXCancelAction as CFString)
                return false
            }
            let row = rows[i]
            if depth == path.steps.count - 1 {
                AXUIElementPerformAction(row, kAXPressAction as CFString)
                return true
            }
            // A submenu's items can be read without opening it, but pressed only once it is open.
            AXUIElementPerformAction(row, kAXPressAction as CFString)
            guard let sub = (value(row, kAXChildrenAttribute) as? [AXUIElement])?.first else {
                AXUIElementPerformAction(menu, kAXCancelAction as CFString)
                return false
            }
            menu = sub
        }
        return false
    }

    /// Closes whatever the icon has open: a menu, a Control Center panel, or a popover, which only
    /// a second press closes.
    nonisolated static func close(_ item: Element, stillOpen: @Sendable () -> Bool) async {
        if let menu = (value(item.element, kAXChildrenAttribute) as? [AXUIElement])?.first {
            AXUIElementPerformAction(menu, kAXCancelAction as CFString)
        }
        AXUIElementPerformAction(item.element, kAXCancelAction as CFString)
        usleep(menuPoll * 5)
        if stillOpen() { _ = press(item) }
    }

    private nonisolated static func waitForMenu(of item: Element) async -> Element? {
        let end = Date().addingTimeInterval(menuWait)
        while Date() < end {
            if let menu = (value(item.element, kAXChildrenAttribute) as? [AXUIElement])?.first,
                string(menu, kAXRoleAttribute) == kAXMenuRole as String
            {
                return Element(element: menu)
            }
            usleep(menuPoll)
        }
        return nil
    }

    private nonisolated static func nodes(of menu: AXUIElement) -> [MenuNode] {
        (value(menu, kAXChildrenAttribute) as? [AXUIElement] ?? []).map { row in
            let title = string(row, kAXTitleAttribute) ?? ""
            let children = value(row, kAXChildrenAttribute) as? [AXUIElement] ?? []
            let submenu = children.first { string($0, kAXRoleAttribute) == kAXMenuRole as String }
            return MenuNode(
                title: title, enabled: value(row, kAXEnabledAttribute) as? Bool ?? true,
                checked: !(string(row, kAXMenuItemMarkCharAttribute) ?? "").isEmpty,
                key: string(row, kAXMenuItemCmdCharAttribute) ?? "",
                children: submenu.map(nodes(of:)) ?? [],
                // A separator has no title and nothing inside; an untitled item with views inside is
                // a custom view.
                isSeparator: title.isEmpty && children.isEmpty)
        }
    }
}
