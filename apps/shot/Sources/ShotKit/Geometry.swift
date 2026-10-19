import CoreGraphics

/// The arithmetic between a drag on screen and the pixels it selects. AppKit measures a screen in points
/// from its bottom-left corner; a captured image counts pixels from its top-left one.
public enum Geometry {
    /// A drag shorter than this on either side is a click, not a selection.
    public static let minimumDrag: CGFloat = 4

    /// The rectangle a drag from `start` to `end` spans, kept inside `bounds`, whichever way it went.
    public static func selection(from start: CGPoint, to end: CGPoint, within bounds: CGRect) -> CGRect {
        let rect = CGRect(
            x: min(start.x, end.x), y: min(start.y, end.y), width: abs(end.x - start.x), height: abs(end.y - start.y))
        let clipped = rect.intersection(bounds)
        return clipped.isNull ? .zero : clipped
    }

    public static func isClick(_ selection: CGRect) -> Bool {
        selection.width < minimumDrag || selection.height < minimumDrag
    }

    /// `rect` with each edge moved to the nearest device pixel at `scale`, so what the overlay outlines is
    /// exactly what is captured: on a 2× display an edge can sit on a half point, on a 1× one it can't.
    public static func snapped(_ rect: CGRect, scale: CGFloat) -> CGRect {
        guard scale > 0 else { return rect }
        func snap(_ value: CGFloat) -> CGFloat { (value * scale).rounded() / scale }
        let minX = snap(rect.minX)
        let minY = snap(rect.minY)
        return CGRect(x: minX, y: minY, width: snap(rect.maxX) - minX, height: snap(rect.maxY) - minY)
    }

    /// The pixels of an image of the whole view that `rect`, in the view's points, covers. Edges round
    /// outward, so a selection never loses a partly covered pixel, and the result stays inside the image.
    public static func pixels(of rect: CGRect, viewSize: CGSize, imageWidth: Int, imageHeight: Int) -> CGRect {
        guard viewSize.width > 0, viewSize.height > 0 else { return .zero }
        let scaleX = CGFloat(imageWidth) / viewSize.width
        let scaleY = CGFloat(imageHeight) / viewSize.height
        let flipped = CGRect(
            x: rect.minX * scaleX, y: (viewSize.height - rect.maxY) * scaleY, width: rect.width * scaleX,
            height: rect.height * scaleY)
        // A hair of tolerance, so 0.1 × 3 landing on 0.30000000000000004 doesn't grow the rect by a pixel.
        let minX = (flipped.minX + 1e-6).rounded(.down)
        let minY = (flipped.minY + 1e-6).rounded(.down)
        let maxX = (flipped.maxX - 1e-6).rounded(.up)
        let maxY = (flipped.maxY - 1e-6).rounded(.up)
        let image = CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)
        let result = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY).intersection(image)
        return result.isNull ? .zero : result
    }

    /// A rectangle in global display coordinates, which Core Graphics measures down from the top-left
    /// corner of the main display, as it sits in a view covering the display at `displayBounds`.
    public static func local(_ rect: CGRect, displayBounds: CGRect) -> CGRect {
        CGRect(
            x: rect.minX - displayBounds.minX, y: displayBounds.maxY - rect.maxY, width: rect.width,
            height: rect.height)
    }

    /// The inverse of `local` for a point: from a view covering the display to global display coordinates.
    public static func global(_ point: CGPoint, displayBounds: CGRect) -> CGPoint {
        CGPoint(x: displayBounds.minX + point.x, y: displayBounds.maxY - point.y)
    }
}

/// An on-screen window as the window server lists it, front to back.
public struct WindowFrame: Equatable, Sendable {
    public let id: UInt32
    /// Global display coordinates: points down from the top-left corner of the main display.
    public let frame: CGRect
    /// The process that owns it, which names the app a shot of it came from.
    public let owner: Int32

    public init(id: UInt32, frame: CGRect, owner: Int32 = 0) {
        self.id = id
        self.frame = frame
        self.owner = owner
    }

    /// The frontmost window under `point`, both in global display coordinates. `windows` is front to back.
    public static func topmost(at point: CGPoint, in windows: [WindowFrame]) -> WindowFrame? {
        windows.first { $0.frame.contains(point) }
    }
}
