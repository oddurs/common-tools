import AppKit

extension CommonTool {
    /// Where the app's menu bar icon starts, as macOS saves it: points from the right edge of the
    /// menu bar. The family in order, close to the system's own icons and well right of Common
    /// Bar's divider, so a newly installed app is never hidden behind it.
    public var startingPosition: Double {
        Double(100 + 40 * (Self.all.firstIndex { $0.id == id } ?? 0))
    }
}

extension NSStatusBar {
    /// A status item that appears beside the system's icons the first time the app runs, instead
    /// of at the far left, where macOS puts a new item and where Common Bar, the notch or the
    /// app's menus would hide it. After that, macOS keeps it wherever the user moves it.
    ///
    /// - Parameter autosaveName: the name macOS saves the position under; never change it.
    @MainActor
    public func commonItem(autosaveName: String, length: CGFloat) -> NSStatusItem {
        if let tool = CommonTool.thisApp {
            StatusItemPosition.seed(autosaveName, at: tool.startingPosition)
        }
        let item = statusItem(withLength: length)
        item.autosaveName = autosaveName
        return item
    }
}

enum StatusItemPosition {
    /// The saved position must exist before the item is named, or macOS ignores it; a position the
    /// user has made by moving the icon is never overwritten.
    static func seed(_ autosaveName: String, at position: Double, in defaults: UserDefaults = .standard) {
        let key = "NSStatusItem Preferred Position \(autosaveName)"
        if defaults.object(forKey: key) == nil { defaults.set(position, forKey: key) }
    }
}
