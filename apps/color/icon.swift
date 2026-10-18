// Common Color's icon glyph, drawn by scripts/make-icon color on the shared Common Tools body.

func glyph(_ ctx: CGContext) {
    // An eyedropper on the diagonal: a glass bulb, collar and barrel, and the drop it has just
    // taken, in white, falling from the tip.
    ctx.saveGState()
    ctx.translateBy(x: 528, y: 556)
    ctx.rotate(by: -.pi / 4)
    // Drawn upright about the origin, tip down; the rotation lays it along the diagonal.
    let bulb = rounded(CGRect(x: -92, y: 110, width: 184, height: 250), 92)
    let collar = rounded(CGRect(x: -132, y: 54, width: 264, height: 72), 36)
    let barrel = CGMutablePath()
    barrel.move(to: CGPoint(x: -58, y: 70))
    barrel.addLine(to: CGPoint(x: 58, y: 70))
    barrel.addLine(to: CGPoint(x: 58, y: -190))
    barrel.addQuadCurve(to: CGPoint(x: 14, y: -300), control: CGPoint(x: 56, y: -250))
    barrel.addQuadCurve(to: CGPoint(x: -14, y: -300), control: CGPoint(x: 0, y: -312))
    barrel.addQuadCurve(to: CGPoint(x: -58, y: -190), control: CGPoint(x: -56, y: -250))
    barrel.closeSubpath()
    glass(ctx, bulb.union(collar).union(barrel))
    ctx.restoreGState()

    // The drop: below and left of the tip, a round base under a point, upright as drops fall.
    let reach = 300 / CGFloat(2).squareRoot()
    let tip = CGPoint(x: 528 - reach, y: 556 - reach)
    let centre = CGPoint(x: tip.x - 34, y: tip.y - 120)
    let r: CGFloat = 50
    let drop = CGMutablePath()
    drop.move(to: CGPoint(x: centre.x, y: centre.y + r * 2.1))
    drop.addCurve(
        to: CGPoint(x: centre.x + r, y: centre.y), control1: CGPoint(x: centre.x + r * 0.35, y: centre.y + r * 1.4),
        control2: CGPoint(x: centre.x + r, y: centre.y + r * 0.7))
    drop.addArc(center: centre, radius: r, startAngle: 0, endAngle: .pi, clockwise: true)
    drop.addCurve(
        to: CGPoint(x: centre.x, y: centre.y + r * 2.1), control1: CGPoint(x: centre.x - r, y: centre.y + r * 0.7),
        control2: CGPoint(x: centre.x - r * 0.35, y: centre.y + r * 1.4))
    drop.closeSubpath()
    ink(ctx) {
        ctx.addPath(drop)
        ctx.setFillColor(rgb(0xffffff))
        ctx.fillPath()
    }
}
