import AppKit
import BarKit

/// The divider that keeps every icon left of it off-screen by stretching, without ever being
/// removed or hidden with `isVisible`. On Tahoe either of those is how the system records a user
/// taking an item out of the menu bar: it writes `VisibleCC = 0` and forgets the item's saved
/// position. The technique is the one Ice and Thaw use.
@MainActor
final class DividerItem {
    enum Metric {
        /// A zero-length item can stay a synthetic window with no window-server window; one
        /// point makes a real one before the intended length is applied.
        static let creationLength: CGFloat = 1
        /// The width left when taken down to nothing. Zero would let the window vanish.
        static let collapsedWidth: CGFloat = 1
        /// What macOS adds to an item's length while its padding constraint is on, measured on Tahoe.
        static let padding: CGFloat = 16
    }

    private enum State: Equatable {
        case hiding
        case down
        case showing(CGFloat)
    }

    let item: NSStatusItem
    /// Holds the button's width to macOS's padding. With it off, the item can be narrower
    /// than an empty item, which is what leaves no gap.
    private let paddingConstraint: NSLayoutConstraint?
    private var state: State?

    init(named name: String) {
        DividerItem.markVisible(name)
        item = NSStatusBar.system.statusItem(withLength: Metric.creationLength)
        item.autosaveName = name
        if let button = item.button, let content = button.window?.contentView {
            let container = button.superview
            paddingConstraint = content.constraintsAffectingLayout(for: .horizontal)
                .first { $0.secondItem === container }
            button.isEnabled = false
            button.appearsDisabled = true
            button.alphaValue = 0
            button.setAccessibilityElement(false)
        } else {
            paddingConstraint = nil
        }
    }

    /// Seeds the item as shown, before it is created, so a missing key can't start it hidden.
    static func markVisible(_ name: String) {
        let defaults = UserDefaults.standard
        for key in ["NSStatusItem Visible \(name)", "NSStatusItem VisibleCC \(name)"]
        where defaults.object(forKey: key) == nil {
            defaults.set(true, forKey: key)
        }
    }

    /// Where the item is, in Cocoa coordinates, once AppKit has laid it out.
    var frame: NSRect? { item.button?.window?.frame }

    /// Stretches until every icon left of it is off-screen.
    func hide() {
        guard state != .hiding else { return }
        // Measured before stretching, while the item still sits where it ends.
        let length = reach
        state = .hiding
        paddingConstraint?.isActive = true
        setLength(length)
    }

    /// Takes up no room and hides nothing: for a divider dragged right of the folder, where
    /// stretching would push the folder and the pinned icons off-screen.
    func takeDown() {
        guard state != .down else { return }
        state = .down
        paddingConstraint?.isActive = false
        setLength(0)
        if let window = item.button?.window, window.frame.width != Metric.collapsedWidth {
            window.setContentSize(NSSize(width: Metric.collapsedWidth, height: window.frame.height))
        }
    }

    /// Stretches only `length`, bringing the nearest icons left of it on screen to open one.
    func show(length: CGFloat) {
        guard state != .showing(length) else { return }
        state = .showing(length)
        paddingConstraint?.isActive = true
        setLength(length)
    }

    /// Stretches further if the window server shows icons left of this divider still on screen:
    /// its right end has moved since its reach was measured. Only ever lengthens, so it can't
    /// undo itself.
    func keepClearingScreen() {
        guard state == .hiding, let window = item.button?.window, let screen = window.screen,
            MenuBar.hasStatusItem(at: window.frame, on: screen),
            !DividerLayout.clearsScreen(windowMinX: window.frame.minX, screenMinX: screen.frame.minX)
        else { return }
        let length = reach
        if length > item.length { setLength(length) }
    }

    /// See `DividerLayout.reach`. The full stretch until AppKit's frame for the item agrees
    /// with where the window server has it.
    private var reach: CGFloat {
        guard let window = item.button?.window, let screen = window.screen,
            MenuBar.hasStatusItem(at: window.frame, on: screen)
        else { return DividerLayout.stretchedLength }
        return DividerLayout.reach(
            dividerEnd: window.frame.maxX, screenMinX: screen.frame.minX, padding: Metric.padding)
    }

    /// Writes only what changed: every status item update on Tahoe is a Control Center round
    /// trip, and repeating them leaks system resources.
    private func setLength(_ length: CGFloat) {
        if item.length != length { item.length = length }
    }
}
