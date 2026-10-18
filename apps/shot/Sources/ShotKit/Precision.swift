import CoreGraphics

/// The keyboard and the edges, for landing a selection exactly: arrows move the pointer by a device
/// pixel, Space moves the whole selection, and a drag's corners settle on the edges of what's on
/// screen. All in a display's points, up from its bottom-left corner.
public enum Precision {
    /// How close a corner must come to an edge to settle on it: near enough to help, far enough from
    /// the next pixel over that a deliberate one-off is still easy with the arrows, which never snap.
    public static let snapDistance: CGFloat = 5

    public enum Arrow: Sendable {
        case left, right, up, down
    }

    /// Where an arrow key puts the pointer: one device pixel over, or ten with ⇧, on the pixel grid and
    /// on the display. The display's far edges count, since a selection can end there.
    public static func nudge(
        _ point: CGPoint, _ arrow: Arrow, large: Bool, scale: CGFloat, within bounds: CGRect
    ) -> CGPoint {
        let step = (large ? 10 : 1) / scale
        var moved = CGPoint(x: (point.x * scale).rounded() / scale, y: (point.y * scale).rounded() / scale)
        switch arrow {
        case .left: moved.x -= step
        case .right: moved.x += step
        case .up: moved.y += step
        case .down: moved.y -= step
        }
        return CGPoint(
            x: min(max(moved.x, bounds.minX), bounds.maxX), y: min(max(moved.y, bounds.minY), bounds.maxY))
    }

    /// `point` settled on the nearest visible edge within `snapDistance`, each axis on its own. `windows`
    /// are front to back; an edge counts only beside its window and where no window in front covers it,
    /// and the display's own edges always count.
    public static func snapped(_ point: CGPoint, toEdgesOf windows: [CGRect], within bounds: CGRect) -> CGPoint {
        let reach = snapDistance
        var x: (distance: CGFloat, value: CGFloat)?
        var y: (distance: CGFloat, value: CGFloat)?
        func covered(_ edge: CGPoint, by front: ArraySlice<CGRect>) -> Bool {
            front.contains { $0.insetBy(dx: 0.5, dy: 0.5).contains(edge) }
        }
        let frames = windows + [bounds]
        for (index, frame) in frames.enumerated() {
            // The display is behind everything, but nothing covers its edges for snapping's sake.
            let front = index < windows.count ? frames[..<index] : []
            if point.y >= frame.minY - reach, point.y <= frame.maxY + reach {
                for edge in [frame.minX, frame.maxX] {
                    let distance = abs(edge - point.x)
                    if distance <= reach, distance < (x?.distance ?? .infinity),
                        !covered(CGPoint(x: edge, y: point.y), by: front)
                    {
                        x = (distance, edge)
                    }
                }
            }
            if point.x >= frame.minX - reach, point.x <= frame.maxX + reach {
                for edge in [frame.minY, frame.maxY] {
                    let distance = abs(edge - point.y)
                    if distance <= reach, distance < (y?.distance ?? .infinity),
                        !covered(CGPoint(x: point.x, y: edge), by: front)
                    {
                        y = (distance, edge)
                    }
                }
            }
        }
        return CGPoint(x: x?.value ?? point.x, y: y?.value ?? point.y)
    }

    /// A drag's anchor and pointer moved together by `delta`, as with Space held, stopping where the
    /// selection between them meets the display's edge.
    public static func moved(
        start: CGPoint, end: CGPoint, by delta: CGVector, within bounds: CGRect
    ) -> (start: CGPoint, end: CGPoint) {
        let rect = CGRect(
            x: min(start.x, end.x), y: min(start.y, end.y), width: abs(end.x - start.x), height: abs(end.y - start.y))
        let dx = min(max(delta.dx, bounds.minX - rect.minX), bounds.maxX - rect.maxX)
        let dy = min(max(delta.dy, bounds.minY - rect.minY), bounds.maxY - rect.maxY)
        return (CGPoint(x: start.x + dx, y: start.y + dy), CGPoint(x: end.x + dx, y: end.y + dy))
    }
}
