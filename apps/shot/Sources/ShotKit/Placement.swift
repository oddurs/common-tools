import CoreGraphics

/// Where the overlay's floating pieces go: the size pill by the selection, and the loupe by the pointer.
/// All in a display's points, up from its bottom-left corner. Each piece stays on its own display, clear
/// of the notch and of the other piece, so neither ever hides behind the camera housing or the edge.
public enum Placement {
    /// Between a piece and what it labels.
    public static let gap: CGFloat = 8
    /// Between a piece and the edge of the display.
    public static let margin: CGFloat = 6
    /// Between the pointer and the loupe, so the loupe never sits under the crosshair.
    public static let loupeOffset: CGFloat = 24

    /// The size pill for `selection`: below its bottom-right corner, right-aligned, where the eye already is
    /// at the end of a drag. Near the bottom of the display it moves inside that corner, when the
    /// selection has room for it, and otherwise above the selection.
    public static func pill(
        size: CGSize, for selection: CGRect, in bounds: CGRect, avoiding obstacles: [CGRect] = []
    ) -> CGRect {
        let right = selection.maxX - size.width
        var candidates = [CGPoint(x: right, y: selection.minY - gap - size.height)]
        if selection.width >= size.width + 2 * gap, selection.height >= size.height + 2 * gap {
            candidates.append(CGPoint(x: right - gap, y: selection.minY + gap))
        }
        candidates.append(CGPoint(x: right, y: selection.maxY + gap))
        return best(candidates.map { CGRect(origin: $0, size: size) }, in: bounds, avoiding: obstacles)
    }

    /// The loupe, a `side`-point square: below and to the right of the pointer, flipping left, up, or both
    /// at the display's edges, and away from `obstacles`.
    public static func loupe(
        side: CGFloat, at pointer: CGPoint, in bounds: CGRect, avoiding obstacles: [CGRect] = []
    ) -> CGRect {
        let near = loupeOffset
        let far = loupeOffset + side
        let origins = [
            CGPoint(x: pointer.x + near, y: pointer.y - far), CGPoint(x: pointer.x - far, y: pointer.y - far),
            CGPoint(x: pointer.x + near, y: pointer.y + near), CGPoint(x: pointer.x - far, y: pointer.y + near),
        ]
        return best(
            origins.map { CGRect(origin: $0, size: CGSize(width: side, height: side)) }, in: bounds,
            avoiding: obstacles)
    }

    /// The first candidate wholly on the display and clear of every obstacle; failing that, the first
    /// that is clear once pulled onto the display; failing that, the first pulled onto it. Whole points,
    /// so a piece's edges and text land on the pixel grid.
    static func best(_ candidates: [CGRect], in bounds: CGRect, avoiding obstacles: [CGRect]) -> CGRect {
        let inside = bounds.insetBy(dx: margin, dy: margin)
        func clear(_ rect: CGRect) -> Bool { !obstacles.contains { $0.intersects(rect) } }
        // A candidate that hits an obstacle can also step past it: below it, or to either side.
        let around = candidates.flatMap { rect in
            obstacles.filter { $0.intersects(rect) }.flatMap { obstacle in
                [
                    CGRect(origin: CGPoint(x: rect.minX, y: obstacle.minY - gap - rect.height), size: rect.size),
                    CGRect(origin: CGPoint(x: obstacle.minX - gap - rect.width, y: rect.minY), size: rect.size),
                    CGRect(origin: CGPoint(x: obstacle.maxX + gap, y: rect.minY), size: rect.size),
                ]
            }
        }
        let candidates = candidates + around
        let chosen =
            candidates.first { inside.contains($0) && clear($0) }
            ?? candidates.map { clamped($0, to: inside) }.first(where: clear)
            ?? clamped(candidates[0], to: inside)
        return CGRect(
            x: chosen.minX.rounded(), y: chosen.minY.rounded(), width: chosen.width, height: chosen.height)
    }

    static func clamped(_ rect: CGRect, to bounds: CGRect) -> CGRect {
        var rect = rect
        rect.origin.x = min(max(rect.minX, bounds.minX), bounds.maxX - rect.width)
        rect.origin.y = min(max(rect.minY, bounds.minY), bounds.maxY - rect.height)
        return rect
    }
}
