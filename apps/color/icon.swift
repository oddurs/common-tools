// Common Color's icon glyph, drawn by scripts/make-icon color on the shared Common Tools body.

func glyph(_ ctx: CGContext) {
    // macOS's colour sampler, as it looks while you pick: a glass loupe over a grid of magnified
    // pixels, with the one under the pointer ringed in white. The spectrum shows through it.
    let centre = CGPoint(x: 512, y: 512)
    let outer: CGFloat = 300, inner: CGFloat = 228

    // The lens: faint glass across the whole disc, so the pixels read as magnified behind it.
    let lens = CGPath(
        ellipseIn: CGRect(x: centre.x - inner, y: centre.y - inner, width: inner * 2, height: inner * 2),
        transform: nil)
    ctx.saveGState()
    ctx.addPath(lens); ctx.clip()
    ctx.setFillColor(rgb(0xffffff, 0.10)); ctx.fill(lens.boundingBox)
    // The pixel grid: lines every cell, fading toward the rim as a lens's edge does.
    let cell: CGFloat = 104
    ctx.setStrokeColor(rgb(0xffffff, 0.42)); ctx.setLineWidth(5)
    for k in -2...2 {
        let o = CGFloat(k) * cell + cell / 2
        ctx.move(to: CGPoint(x: centre.x + o, y: centre.y - inner)); ctx.addLine(to: CGPoint(x: centre.x + o, y: centre.y + inner))
        ctx.move(to: CGPoint(x: centre.x - inner, y: centre.y + o)); ctx.addLine(to: CGPoint(x: centre.x + inner, y: centre.y + o))
    }
    ctx.strokePath()
    radial(ctx, [rgb(0xffffff, 0), rgb(0xffffff, 0), shade(0.35)], centre, inner)
    ctx.restoreGState()

    // The rim: a thick ring of glass.
    let ring = CGMutablePath()
    ring.addEllipse(in: CGRect(x: centre.x - outer, y: centre.y - outer, width: outer * 2, height: outer * 2))
    ring.addEllipse(in: CGRect(x: centre.x - inner, y: centre.y - inner, width: inner * 2, height: inner * 2))
    glass(ctx, ring.normalized(using: .evenOdd))

    // The picked pixel, ringed in white so it shows on any colour.
    let pick = CGRect(x: centre.x - cell / 2, y: centre.y - cell / 2, width: cell, height: cell)
    ink(ctx) {
        ctx.setStrokeColor(rgb(0xffffff)); ctx.setLineWidth(18)
        ctx.addPath(rounded(pick.insetBy(dx: 2, dy: 2), 10)); ctx.strokePath()
    }
}
