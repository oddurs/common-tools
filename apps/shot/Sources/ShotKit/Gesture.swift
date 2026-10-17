import CoreGraphics

/// What a press and release on the overlay means.
public enum Gesture: Equatable, Sendable {
    case area(CGRect)
    case window
    /// Neither: a drag shrunk back to a click, or a click with no window under it. The overlay stays up.
    case nothing

    /// A drag picks its area; a click picks the highlighted window. A drag shrunk back to a click picks
    /// nothing, since neither was meant.
    public static func from(selection: CGRect, dragged: Bool, overWindow: Bool) -> Gesture {
        if !Geometry.isClick(selection) { return .area(selection) }
        return !dragged && overWindow ? .window : .nothing
    }
}
