import Foundation

/// The status items' autosave names. macOS saves each item's position under its name,
/// so these never change.
public enum ItemName {
    /// The More folder. It was the chevron, and keeps the chevron's name so it stays where the
    /// chevron was.
    public static let toggle = "toggle"
    public static let divider = "divider"
}

/// Each status item's saved distance from the right edge of the menu bar; larger is
/// further left. macOS records it as items move, so it is known before they are laid out.
public struct ItemPositions: Equatable, Sendable {
    public var toggle: Double
    public var divider: Double

    public init(toggle: Double, divider: Double) {
        self.toggle = toggle
        self.divider = divider
    }

    /// Fills in positions macOS hasn't saved yet. Without one, a new item lands at the far
    /// left, which on a crowded notched display is behind the notch. The divider starts just
    /// left of the folder, wherever the user has since moved that.
    public static func seeded(toggle: Double?, divider: Double?) -> ItemPositions {
        let toggle = toggle ?? 0
        return ItemPositions(toggle: toggle, divider: divider ?? toggle + 1)
    }

    /// Everything left of the divider is kept off-screen, so it must sit left of the folder:
    /// stretched right of it, it would push the folder and the pinned icons off-screen too.
    public var dividerHides: Bool { divider > toggle }
}

/// How far the divider stretches to keep every icon left of it off-screen.
public enum DividerLayout {
    /// The stretch before AppKit and the window server agree on where the divider is.
    public static let stretchedLength: CGFloat = 10_000

    /// Until everything left of the divider is past the screen's left edge, with room to spare.
    /// Reaching only past the notch instead would leave icons on screen behind it, where
    /// macOS's overflow rules reshuffle the bar. `dividerEnd` is the divider's right edge and
    /// `padding` what macOS adds to its length.
    public static func reach(dividerEnd: CGFloat, screenMinX: CGFloat, padding: CGFloat) -> CGFloat {
        min(max(dividerEnd - screenMinX - padding + offscreenMargin, 0), stretchedLength)
    }

    static let offscreenMargin: CGFloat = 64

    /// Whether a stretched divider whose window starts at `windowMinX` has every icon left of it
    /// off-screen. Its reach is measured when it stretches, and the divider's right end moves
    /// when pinned icons come and go, so a reach that was enough then can leave icons on screen
    /// behind the app's menus or the notch.
    public static func clearsScreen(windowMinX: CGFloat, screenMinX: CGFloat) -> Bool {
        windowMinX <= screenMinX
    }

    /// The length that puts the right end of the icons left of the divider at `blockEnd`,
    /// for a divider ending at `dividerEnd`. Never negative: the divider can't pull icons right.
    public static func length(showingUpTo blockEnd: CGFloat, dividerEnd: CGFloat, padding: CGFloat) -> CGFloat {
        max(dividerEnd - padding - blockEnd, 0)
    }
}
