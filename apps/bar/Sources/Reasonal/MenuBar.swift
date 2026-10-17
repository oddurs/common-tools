import AppKit
import BarKit

/// Where things are in the menu bar. Points are global Cocoa coordinates. The window
/// server reports top-left-origin frames, so its windows are matched by x and by the
/// top edge of the screen they sit on.
enum MenuBar {
    static func screen(at p: NSPoint) -> NSScreen? {
        NSScreen.screens.first {
            ($0.frame.minX...$0.frame.maxX).contains(p.x) && ($0.frame.minY...$0.frame.maxY).contains(p.y)
        }
    }

    static func contains(_ p: NSPoint) -> Bool {
        guard let screen = screen(at: p) else { return false }
        return p.y >= screen.frame.maxY - height(of: screen)
    }

    /// Part of the bar holding neither the app's menus nor another app's status item. `own` is
    /// the caller's items, whose stretched divider covers exactly the empty space.
    static func isEmptySpace(_ p: NSPoint, own: OwnItems) -> Bool {
        guard let screen = screen(at: p), contains(p) else { return false }
        return model(of: screen, own: own).isEmptySpace(at: p.x)
    }

    /// Every status item in `screen`'s menu bar, and where it can be seen. Status item windows
    /// are listed whether or not the window server calls them on screen: on macOS 26 it calls
    /// none of them on screen.
    static func model(of screen: NSScreen, own: OwnItems) -> MenuBarModel {
        let windows = windows(onScreenOnly: false).filter { $0.layer == statusLayer }.map(\.item)
        return MenuBarModel(windows: windows, geometry: geometry(of: screen), own: own)
    }

    static func geometry(of screen: NSScreen) -> MenuBarGeometry {
        let frame = screen.frame
        var notch: ClosedRange<CGFloat>?
        if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            notch = (frame.minX + left.maxX)...(frame.minX + right.minX)
        }
        return MenuBarGeometry(
            minX: frame.minX, maxX: frame.maxX, top: topInWindowServer(of: screen), height: height(of: screen),
            notch: notch)
    }

    /// A Cocoa frame in window-server coordinates, for comparing with what the window server lists.
    static func windowServerFrame(_ frame: NSRect) -> CGRect {
        let top = NSScreen.screens.first?.frame.maxY ?? 0
        return CGRect(x: frame.minX, y: top - frame.maxY, width: frame.width, height: frame.height)
    }

    /// Whether the window server has a status item at `frame` (Cocoa coordinates) on `screen`.
    static func hasStatusItem(at frame: NSRect, on screen: NSScreen) -> Bool {
        let top = topInWindowServer(of: screen)
        return windows(onScreenOnly: false).contains {
            $0.layer == statusLayer && abs($0.frame.minY - top) < 1
                && abs($0.frame.minX - frame.minX) < 1 && abs($0.frame.width - frame.width) < 1
        }
    }

    /// A menu or popover from any menu bar item is showing.
    static var isMenuOpen: Bool {
        windows(onScreenOnly: true).contains { $0.layer > statusLayer && $0.layer < dragLayer }
    }

    private static let statusLayer = Int(CGWindowLevelForKey(.statusWindow))
    private static let dragLayer = Int(CGWindowLevelForKey(.draggingWindow))

    private static func height(of screen: NSScreen) -> CGFloat {
        // visibleFrame excludes the menu bar, which is taller on notched displays.
        max(NSStatusBar.system.thickness, screen.frame.maxY - screen.visibleFrame.maxY)
    }

    private static func topInWindowServer(of screen: NSScreen) -> CGFloat {
        (NSScreen.screens.first?.frame.maxY ?? 0) - screen.frame.maxY
    }

    private struct Window {
        let id: UInt32
        let layer: Int
        let frame: CGRect
        let ownerPID: Int32
        let ownerName: String

        var item: StatusItemWindow {
            StatusItemWindow(id: id, frame: frame, ownerPID: ownerPID, ownerName: ownerName)
        }
    }

    private static func windows(onScreenOnly: Bool) -> [Window] {
        let options: CGWindowListOption = onScreenOnly ? [.optionOnScreenOnly, .excludeDesktopElements] : [.optionAll]
        let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
        return list.compactMap { info in
            guard let layer = info[kCGWindowLayer as String] as? Int,
                let bounds = info[kCGWindowBounds as String] as? NSDictionary,
                let frame = CGRect(dictionaryRepresentation: bounds)
            else { return nil }
            return Window(
                id: info[kCGWindowNumber as String] as? UInt32 ?? 0, layer: layer, frame: frame,
                ownerPID: info[kCGWindowOwnerPID as String] as? Int32 ?? 0,
                ownerName: info[kCGWindowOwnerName as String] as? String ?? "")
        }
    }
}
