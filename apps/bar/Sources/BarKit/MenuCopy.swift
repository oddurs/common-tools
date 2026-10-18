/// An icon's menu as Accessibility reads it, so Common Bar can show it under the folder when the
/// icon itself can't be brought there. Choosing an item finds the same item in the real menu by
/// its path and presses it.
public struct MenuNode: Equatable, Sendable {
    public var title: String
    public var enabled: Bool
    public var checked: Bool
    /// The key of its shortcut, as `AXMenuItemCmdChar` gives it: "P" for ⌘P.
    public var key: String
    public var children: [MenuNode]
    /// A line between groups. An untitled item that isn't one is a custom view, which can't be copied.
    public var isSeparator: Bool

    public init(
        title: String, enabled: Bool = true, checked: Bool = false, key: String = "", children: [MenuNode] = [],
        isSeparator: Bool = false
    ) {
        self.title = title
        self.enabled = enabled
        self.checked = checked
        self.key = key
        self.children = children
        self.isSeparator = isSeparator
    }

    public static let separator = MenuNode(title: "", enabled: false, isSeparator: true)
}

/// Where an item sits: its index among its menu's children at each level, separators counted,
/// with its title to check it is still the same item.
public struct MenuPath: Equatable, Sendable {
    public var steps: [(index: Int, title: String)]

    public init(_ steps: [(index: Int, title: String)]) {
        self.steps = steps
    }

    public static func == (a: MenuPath, b: MenuPath) -> Bool {
        a.steps.map(\.index) == b.steps.map(\.index) && a.steps.map(\.title) == b.steps.map(\.title)
    }

    /// The index of the next step's item in `titles`, one menu's children: where it was, if it
    /// still has the same title there, or else the first item with that title. A menu that
    /// rebuilt itself in between can have moved it.
    public static func find(_ step: (index: Int, title: String), in titles: [String]) -> Int? {
        if step.index < titles.count, titles[step.index] == step.title { return step.index }
        return titles.firstIndex(of: step.title)
    }
}

public enum MenuCopy {
    /// Whether a menu read through Accessibility can stand in for the real one: it has an item
    /// with a title. Menus built of custom views read as untitled items and can't be copied.
    public static func copyable(_ nodes: [MenuNode]) -> Bool {
        nodes.contains { !$0.title.isEmpty }
    }

    /// The menu as Common Bar shows it: untitled items that aren't separators left out, and no
    /// separator at either end or next to another.
    public static func tidy(_ nodes: [(node: MenuNode, index: Int)]) -> [(node: MenuNode, index: Int)] {
        var result: [(node: MenuNode, index: Int)] = []
        for entry in nodes {
            if entry.node.isSeparator {
                if let last = result.last, !last.node.isSeparator { result.append(entry) }
            } else if !entry.node.title.isEmpty {
                result.append(entry)
            }
        }
        while result.last?.node.isSeparator == true { result.removeLast() }
        return result
    }
}
