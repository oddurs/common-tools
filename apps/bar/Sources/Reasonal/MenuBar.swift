import AppKit
import BarKit

/// Where things are in the menu bar. AppKit frames are global Cocoa coordinates; the window
/// server and Accessibility report top-left-origin frames, matched by x and by the top edge of
/// the screen they sit on.
enum MenuBar {
    /// Every status item in `screen`'s menu bar, and where it can be seen. Status item windows
    /// are listed whether or not the window server calls them on screen: on macOS 26 it calls
    /// none of them on screen.
    static func model(of screen: NSScreen, own: OwnItems) -> MenuBarModel {
        MenuBarModel(windows: statusItemWindows(), geometry: geometry(of: screen), own: own)
    }

    /// Every window on the status item layer, on any screen. Safe off the main thread.
    nonisolated static func statusItemWindows() -> [StatusItemWindow] {
        windows(onScreenOnly: false).filter { $0.layer == statusLayer }.map(\.item)
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

    /// The windows on screen now, to tell later which ones a press opened.
    static func onScreenWindowIDs() -> Set<UInt32> {
        Set(windows(onScreenOnly: true).map(\.id))
    }

    /// Whether a window that wasn't on screen `before` hangs from `screen`'s menu bar: a menu,
    /// or a panel or popover from `pid`, which may sit at any level.
    static func somethingOpened(since before: Set<UInt32>, by pid: Int32, on screen: NSScreen) -> Bool {
        let geometry = geometry(of: screen)
        return windows(onScreenOnly: true).contains {
            !before.contains($0.id) && geometry.hangsBelow($0.frame) && ($0.layer > 0 || $0.ownerPID == pid)
        }
    }

    private static let statusLayer = Int(CGWindowLevelForKey(.statusWindow))

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

/// What Accessibility says about each app's menu bar items. Needs the Accessibility permission;
/// without it every call finds nothing.
enum MenuBarExtras {
    struct App: Sendable {
        let pid: Int32
        let bundleID: String?
        let name: String
    }

    /// An app that doesn't answer within this long is skipped, so one hung app can't hold up a folder.
    private static let timeout: Float = 0.25

    /// Every app's status items, asking the apps side by side.
    nonisolated static func items(of apps: [App]) -> [AccessibleItem] {
        let results = Results(count: apps.count)
        DispatchQueue.concurrentPerform(iterations: apps.count) { index in
            results.set(index, items(of: apps[index]))
        }
        return results.all
    }

    /// Presses the item of `pid`'s at `frame` (window-server coordinates), as clicking it would.
    /// Returns false when the app has no item there or doesn't answer.
    nonisolated static func press(pid: Int32, at frame: CGRect) -> Bool {
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, timeout)
        guard
            let element = children(of: app).first(where: { child in
                let f = Self.frame(of: child)
                return f.width > 0 && f.midX >= frame.minX && f.midX <= frame.maxX
            })
        else { return false }
        let result = AXUIElementPerformAction(element, kAXPressAction as CFString)
        // An app that opens a menu may answer only once the menu closes; the press still happened.
        return result == .success || result == .cannotComplete
    }

    private nonisolated static func items(of app: App) -> [AccessibleItem] {
        let element = AXUIElementCreateApplication(app.pid)
        AXUIElementSetMessagingTimeout(element, timeout)
        return children(of: element).map { child in
            AccessibleItem(
                pid: app.pid, bundleID: app.bundleID, appName: app.name, frame: frame(of: child),
                title: string(child, kAXTitleAttribute), label: string(child, kAXDescriptionAttribute))
        }
    }

    private nonisolated static func children(of app: AXUIElement) -> [AXUIElement] {
        guard let bar = value(app, kAXExtrasMenuBarAttribute) else { return [] }
        // Checked, not forced: a hung app can hand back anything.
        guard CFGetTypeID(bar) == AXUIElementGetTypeID() else { return [] }
        return value(bar as! AXUIElement, kAXChildrenAttribute) as? [AXUIElement] ?? []
    }

    private nonisolated static func frame(of element: AXUIElement) -> CGRect {
        var origin = CGPoint.zero
        var size = CGSize.zero
        if let v = value(element, kAXPositionAttribute), CFGetTypeID(v) == AXValueGetTypeID() {
            AXValueGetValue(v as! AXValue, .cgPoint, &origin)
        }
        if let v = value(element, kAXSizeAttribute), CFGetTypeID(v) == AXValueGetTypeID() {
            AXValueGetValue(v as! AXValue, .cgSize, &size)
        }
        return CGRect(origin: origin, size: size)
    }

    private nonisolated static func string(_ element: AXUIElement, _ attribute: String) -> String? {
        value(element, attribute) as? String
    }

    private nonisolated static func value(_ element: AXUIElement, _ attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        return AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success ? value : nil
    }

    /// Collects each app's answer from the threads asking them.
    private final class Results: @unchecked Sendable {
        private var slots: [[AccessibleItem]]
        private let lock = NSLock()

        init(count: Int) { slots = Array(repeating: [], count: count) }

        func set(_ index: Int, _ items: [AccessibleItem]) {
            lock.withLock { slots[index] = items }
        }

        var all: [AccessibleItem] { lock.withLock { slots.flatMap { $0 } } }
    }
}
