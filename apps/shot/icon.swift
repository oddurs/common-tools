// Common Shot's icon glyph, drawn by scripts/make-icon shot on the shared Common Tools body.

func glyph(_ ctx: CGContext) {
    // A viewfinder: four glass corners around the area being taken, and a crosshair where you aim.
    let box = CGRect(x: 232, y: 232, width: 560, height: 560)
    let arm: CGFloat = 200, thickness: CGFloat = 84, radius: CGFloat = 42
    let corners = CGMutablePath()
    for (x, y, dx, dy) in [
        (box.minX, box.minY, 1.0, 1.0), (box.maxX, box.minY, -1.0, 1.0), (box.minX, box.maxY, 1.0, -1.0),
        (box.maxX, box.maxY, -1.0, -1.0),
    ] {
        let horizontal = CGRect(
            x: dx > 0 ? x : x - arm, y: dy > 0 ? y : y - thickness, width: arm, height: thickness)
        let vertical = CGRect(
            x: dx > 0 ? x : x - thickness, y: dy > 0 ? y : y - arm, width: thickness, height: arm)
        let corner = rounded(horizontal, radius).union(rounded(vertical, radius))
        corners.addPath(corner)
    }
    glass(ctx, corners)
    let cross = CGMutablePath()
    cross.addPath(rounded(CGRect(x: 512 - 20, y: 512 - 110, width: 40, height: 220), 20))
    cross.addPath(rounded(CGRect(x: 512 - 110, y: 512 - 20, width: 220, height: 40), 20))
    ink(ctx) {
        ctx.addPath(cross.union(cross))
        ctx.setFillColor(rgb(0xffffff))
        ctx.fillPath()
    }
}
