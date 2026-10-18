import CoreGraphics
import Foundation

/// A status item as Accessibility describes it: one child of an app's `AXExtrasMenuBar`. Only
/// Accessibility says which app made an item on macOS 26, where every item's window belongs to
/// Control Center.
public struct AccessibleItem: Equatable, Sendable {
    public var pid: Int32
    public var bundleID: String?
    public var appName: String
    /// Window-server coordinates, as Accessibility reports them.
    public var frame: CGRect
    public var title: String?
    /// `AXDescription`: "Wi‑Fi, connected, 3 bars", "Glyph 2".
    public var label: String?

    public init(
        pid: Int32, bundleID: String?, appName: String, frame: CGRect, title: String? = nil, label: String? = nil
    ) {
        self.pid = pid
        self.bundleID = bundleID
        self.appName = appName
        self.frame = frame
        self.title = title
        self.label = label
    }
}

/// One row in a folder: an icon in the menu bar, the app it belongs to, and what to call it.
public struct FolderEntry: Equatable, Sendable, Identifiable {
    public var item: MenuBarItem
    public var owner: AccessibleItem
    public var name: String

    public var id: UInt32 { item.id }
}

extension MenuBarModel {
    /// The icons left of the divider, left to right, each paired with what Accessibility says
    /// about it. They are matched by where both say the icon is: Accessibility's frame sits
    /// inside the window's, a few points in. Icons Accessibility doesn't know, and `ownPID`'s
    /// own items, are left out.
    public func folderEntries(_ accessible: [AccessibleItem], ownPID: Int32) -> [FolderEntry] {
        var unmatched = accessible.filter { $0.pid != ownPID && $0.frame.width > 0 && $0.frame.height > 0 }
        var pairs: [(MenuBarItem, AccessibleItem)] = []
        for item in items where item.section == .hidden {
            let window = item.window.frame
            guard
                let index = unmatched.firstIndex(where: {
                    $0.frame.midX >= window.minX && $0.frame.midX <= window.maxX
                })
            else { continue }
            pairs.append((item, unmatched.remove(at: index)))
        }
        return pairs.map { item, owner in
            let siblings = pairs.map(\.1).filter { $0.pid == owner.pid }
            return FolderEntry(item: item, owner: owner, name: Self.name(of: owner, among: siblings))
        }
    }

    /// An app's name, unless that isn't enough. macOS's own items (Wi‑Fi, Battery, Now Playing)
    /// all belong to Control Center or another agent, so they go by the first part of their
    /// label. An app with several icons tells them apart by each one's title or label, or by
    /// number.
    public static func name(of owner: AccessibleItem, among siblings: [AccessibleItem]) -> String {
        let own = [owner.label, owner.title].compactMap { $0?.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty && $0 != owner.appName }
        if owner.bundleID?.hasPrefix("com.apple.") == true, let own {
            return String(own.split(separator: ",").first ?? Substring(own))
        }
        guard siblings.count > 1 else { return owner.appName }
        if let own { return "\(owner.appName): \(own)" }
        let number = (siblings.firstIndex(of: owner) ?? 0) + 1
        return "\(owner.appName) \(number)"
    }

    /// Where the right end of the icons left of the divider has to be for `target` to be opened.
    /// A menu opened from an icon off-screen opens off-screen, where it can't be seen but still
    /// takes the keyboard, so the icon must be on screen first. It goes as far right as it can
    /// while the icons between it and the divider stay where they can't be seen, under the notch
    /// or the app's menus, so the one nearest the divider shows beside the notch; without that
    /// room, just far enough that all of it is on screen.
    /// Nil when even taking the divider down to nothing leaves it off-screen.
    public func blockEnd(toOpen target: MenuBarItem, dividerEnd: CGFloat, padding: CGFloat) -> CGFloat? {
        let hidden = items.filter { $0.section == .hidden }
        guard let index = hidden.firstIndex(of: target) else { return nil }
        let between = hidden[(index + 1)...].reduce(0) { $0 + $1.window.frame.width }
        let width = target.window.frame.width
        let onScreen = geometry.minX + between + width
        // With nothing between it and the divider, the icon itself can show, right of the notch.
        let end = max(onScreen, geometry.usableMinX + (between == 0 ? width : 0))
        guard end <= dividerEnd - padding else {
            return onScreen <= dividerEnd - padding ? dividerEnd - padding : nil
        }
        return end
    }
}

/// Watches an icon opened from a folder until what it opened has closed, so the icon can go back
/// off-screen. Some icons open nothing (they toggle something), so a press that opens nothing in
/// a moment counts as done.
public struct OpenWatch: Sendable {
    public static let appearTimeout: TimeInterval = 1.5
    /// A menu briefly closes as the pointer moves between items in it.
    public static let closeGrace: TimeInterval = 0.3

    public enum Phase: Equatable, Sendable {
        case waiting
        case open
        case done
    }

    private let started: Date
    private var seenOpen = false
    private var closedSince: Date?

    public init(started: Date) {
        self.started = started
    }

    /// `somethingOpen` means a menu or panel that wasn't there before the press hangs below the
    /// menu bar.
    public mutating func update(somethingOpen: Bool, now: Date) -> Phase {
        if somethingOpen {
            seenOpen = true
            closedSince = nil
            return .open
        }
        guard seenOpen else {
            return now.timeIntervalSince(started) >= Self.appearTimeout ? .done : .waiting
        }
        let since = closedSince ?? now
        closedSince = since
        return now.timeIntervalSince(since) >= Self.closeGrace ? .done : .open
    }
}
