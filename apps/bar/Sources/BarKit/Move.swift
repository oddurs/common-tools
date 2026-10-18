import CoreGraphics

/// Moving an icon from a folder in beside the folder so its menu opens under it, and back to its
/// slot afterwards. macOS gives no API to move another app's status item; a ⌘-drag is how a person
/// does it, so that is what Common Bar plays, and it checks the window list after every drop.
/// Points are window-server coordinates, as `CGEvent` takes them.
public enum Move {
    /// How many drag events lie between pressing and letting go: enough that macOS follows the
    /// pointer from one slot to the next rather than seeing a jump.
    public static let steps = 12

    /// Where to press and where to let go to put `item` immediately left of `neighbour`. macOS
    /// inserts a dragged item on the side of the neighbour's middle the pointer is on, so the drop
    /// is in the neighbour's left quarter.
    public static func drag(_ item: CGRect, toJustLeftOf neighbour: CGRect, barMidY: CGFloat) -> (
        from: CGPoint, to: CGPoint
    ) {
        (CGPoint(x: item.midX, y: barMidY), CGPoint(x: neighbour.minX + neighbour.width / 4, y: barMidY))
    }

    /// The pointer's path from `from` to `to`, `steps` points evenly spaced, ending at `to`.
    public static func path(from: CGPoint, to: CGPoint, steps: Int = Move.steps) -> [CGPoint] {
        (1...max(steps, 1)).map { i in
            let t = CGFloat(i) / CGFloat(max(steps, 1))
            return CGPoint(x: from.x + (to.x - from.x) * t, y: from.y + (to.y - from.y) * t)
        }
    }

    /// How far from the icon a menu or popover may open and still be its own: a menu can open left
    /// of its icon near the screen's right edge, but not across the screen.
    public static let nearby: CGFloat = 240

    /// Whether what opened from an icon sits under it: on the screen, and overlapping the icon
    /// give or take `nearby`. One placed from a stale frame opens off-screen, or a popover pinned
    /// to the screen's edge far from the icon.
    public static func opened(_ window: CGRect, under icon: CGRect, screenMinX: CGFloat, screenMaxX: CGFloat) -> Bool {
        window.minX >= screenMinX - 1 && window.maxX <= screenMaxX + 1
            && window.maxX >= icon.minX - nearby && window.minX <= icon.maxX + nearby
    }

    /// Whether a drag can safely start or end on `frame`: under the notch or in the clear right of
    /// it. Left of the notch the frontmost app's menus sit on top, and a press there would land on
    /// one of them. Without a notch, where the menus end can't be seen, so only the right half of
    /// the bar is trusted.
    public static func reachable(_ frame: CGRect, in geometry: MenuBarGeometry) -> Bool {
        let start = geometry.notch?.lowerBound ?? (geometry.minX + geometry.maxX) / 2
        return frame.minX >= start && frame.maxX <= geometry.maxX
    }

    /// Whether `item` now sits immediately left of `neighbour`, give or take the point or two
    /// macOS rounds to.
    public static func landed(_ item: CGRect, justLeftOf neighbour: CGRect) -> Bool {
        abs(item.maxX - neighbour.minX) <= 2
    }
}

extension MenuBarModel {
    /// What is immediately right of `item` in the hidden section: the icon whose left edge meets
    /// its right edge, or nil when it is the one nearest the divider. Putting it back left of that
    /// puts it back in its slot.
    public func slot(of item: MenuBarItem) -> MenuBarItem? {
        let hidden = items.filter { $0.section == .hidden }
        guard let i = hidden.firstIndex(of: item), i + 1 < hidden.count else { return nil }
        return hidden[i + 1]
    }
}
