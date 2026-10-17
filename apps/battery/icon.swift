// Common Battery's icon glyph, drawn by scripts/make-icon battery on the shared Common Tools body.

func glyph(_ ctx: CGContext) {
    // A battery: a glass case and nub, with a solid white charge two-thirds full.
    let body = CGRect(x: 182, y: 342, width: 600, height: 340)
    let wall: CGFloat = 56
    let outer = rounded(body, 104)
    let inner = rounded(body.insetBy(dx: wall, dy: wall), 104 - wall)
    glass(ctx, outer.subtracting(inner))
    glass(ctx, rounded(CGRect(x: body.maxX + 24, y: body.midY - 72, width: 58, height: 144), 29))
    let cavity = body.insetBy(dx: wall + 26, dy: wall + 26)
    var charge = cavity
    charge.size.width *= 0.66
    ink(ctx) {
        ctx.addPath(rounded(charge, 52))
        ctx.setFillColor(rgb(0xffffff))
        ctx.fillPath()
    }
}
