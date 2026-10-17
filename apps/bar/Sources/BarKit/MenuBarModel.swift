import CoreGraphics

/// A status item's window as the window server lists it, which needs no permission. Frames are
/// global with the origin at the top left, as the window server reports them.
///
/// On macOS 26 every status item's window belongs to Control Center, so `ownerPID` and
/// `ownerName` are Control Center's whichever app made the item, and only Screen Recording reveals
/// a window's name. On earlier versions they are the owning app's.
public struct StatusItemWindow: Equatable, Sendable {
    public var id: UInt32
    public var frame: CGRect
    public var ownerPID: Int32
    public var ownerName: String

    public init(id: UInt32, frame: CGRect, ownerPID: Int32, ownerName: String) {
        self.id = id
        self.frame = frame
        self.ownerPID = ownerPID
        self.ownerName = ownerName
    }
}

/// The parts of one screen's menu bar that decide whether an icon in it can be seen.
public struct MenuBarGeometry: Equatable, Sendable {
    /// The screen's left and right edges.
    public var minX: CGFloat
    public var maxX: CGFloat
    /// The screen's top edge in window-server coordinates, where its status items sit.
    public var top: CGFloat
    public var height: CGFloat
    /// The camera housing, if the screen has one.
    public var notch: ClosedRange<CGFloat>?

    public init(minX: CGFloat, maxX: CGFloat, top: CGFloat = 0, height: CGFloat, notch: ClosedRange<CGFloat>? = nil) {
        self.minX = minX
        self.maxX = maxX
        self.top = top
        self.height = height
        self.notch = notch
    }

    /// Where an icon can be seen from. On a notched screen the frontmost app's menus fill the bar
    /// left of the notch, so only the part right of it is the icons'. Without a notch there is no
    /// way to see where another app's menus end short of Accessibility, so the whole bar counts.
    public var usableMinX: CGFloat { notch?.upperBound ?? minX }

    public func visibility(of frame: CGRect) -> Visibility {
        if frame.maxX <= minX || frame.minX >= maxX { return .offScreen }
        if let notch, frame.minX < notch.upperBound && frame.maxX > notch.lowerBound { return .underNotch }
        if frame.minX < usableMinX { return .behindAppMenus }
        return .visible
    }

    /// Whether a window sits in this menu bar's row: the status item layer also holds the
    /// panels that open from items, which hang below it.
    func holds(_ frame: CGRect) -> Bool {
        abs(frame.minY - top) < 1 && frame.width > 0 && frame.height > 0 && frame.height <= height + 1
    }
}

/// Whether an icon can be seen. An icon is visible only when all of it is; one that is partly
/// under the notch can't be relied on to be clicked.
public enum Visibility: Equatable, Sendable {
    case visible
    case underNotch
    case behindAppMenus
    case offScreen

    /// On screen, but where it can't be seen.
    public var isStranded: Bool { self == .underNotch || self == .behindAppMenus }
}

/// Which side of Common Bar's divider an icon is on.
public enum Section: Equatable, Sendable {
    /// Right of the divider: always showing.
    case shown
    /// Left of it: off-screen while the bar is collapsed.
    case hidden
}

public struct MenuBarItem: Equatable, Sendable, Identifiable {
    public var window: StatusItemWindow
    public var visibility: Visibility
    public var section: Section

    public var id: UInt32 { window.id }
}

/// Common Bar's own items, as frames in window-server coordinates. Their windows have no name
/// Common Bar can read on macOS 26, so they are recognised by where they are.
public struct OwnItems: Equatable, Sendable {
    /// The divider every hidden icon is left of.
    public var divider: CGRect?
    /// The chevron, the always-hidden divider, and the spacers.
    public var others: [CGRect]

    public init(divider: CGRect?, others: [CGRect] = []) {
        self.divider = divider
        self.others = others
    }

    func contains(_ frame: CGRect) -> Bool {
        ([divider].compactMap { $0 } + others).contains {
            abs($0.minX - frame.minX) < 1 && abs($0.width - frame.width) < 1
        }
    }
}

/// Every other app's status item in one screen's menu bar, left to right, with where it can be
/// seen and which section it is in. Built from window bounds alone, so it needs no permission.
public struct MenuBarModel: Equatable, Sendable {
    public let geometry: MenuBarGeometry
    public let items: [MenuBarItem]

    public init(windows: [StatusItemWindow], geometry: MenuBarGeometry, own: OwnItems) {
        self.geometry = geometry
        items =
            windows
            .filter { geometry.holds($0.frame) && !own.contains($0.frame) }
            .sorted { $0.frame.minX < $1.frame.minX }
            .map { window in
                let hidden = own.divider.map { window.frame.midX < $0.midX } ?? false
                return MenuBarItem(
                    window: window, visibility: geometry.visibility(of: window.frame),
                    section: hidden ? .hidden : .shown)
            }
    }

    /// Icons on screen that can't be seen right now.
    public var stranded: [MenuBarItem] { items.filter { $0.visibility.isStranded } }

    /// Whether `x` in this menu bar holds neither another app's icon nor the app's menus, so
    /// resting the pointer or clicking there can reveal. Common Bar's own items don't count: a
    /// stretched divider covers exactly the space that is empty.
    public func isEmptySpace(at x: CGFloat) -> Bool {
        // Without a notch, the app's menus can't be seen, so only the right half is trusted.
        let start = geometry.notch?.upperBound ?? (geometry.minX + geometry.maxX) / 2
        guard x >= start, x < geometry.maxX else { return false }
        return !items.contains { $0.window.frame.minX <= x && x < $0.window.frame.maxX }
    }
}
