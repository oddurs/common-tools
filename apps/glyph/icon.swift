// Common Glyph's icon glyph, drawn by scripts/make-icon glyph on the shared Common Tools body.

func glyph(_ ctx: CGContext) {
    // A menu bar strip with one item grown past its edges: a four-pointed star, the app's default glyph,
    // beside two ordinary items.
    let strip = CGRect(x: 172, y: 402, width: 680, height: 220)
    glass(ctx, rounded(strip, 110))
    let y = strip.midY
    ink(ctx) {
        let c = CGPoint(x: 400, y: y), r: CGFloat = 196, k: CGFloat = 30
        let star = CGMutablePath()
        star.move(to: CGPoint(x: c.x, y: c.y + r))
        star.addQuadCurve(to: CGPoint(x: c.x + r, y: c.y), control: CGPoint(x: c.x + k, y: c.y + k))
        star.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r), control: CGPoint(x: c.x + k, y: c.y - k))
        star.addQuadCurve(to: CGPoint(x: c.x - r, y: c.y), control: CGPoint(x: c.x - k, y: c.y - k))
        star.addQuadCurve(to: CGPoint(x: c.x, y: c.y + r), control: CGPoint(x: c.x - k, y: c.y + k))
        star.closeSubpath()
        ctx.setFillColor(rgb(0xffffff))
        ctx.addPath(star)
        ctx.fillPath()
        for x in [652.0, 752.0] {
            ctx.setFillColor(rgb(0xffffff, 0.85));
            ctx.fillEllipse(in: CGRect(x: x - 30, y: y - 30, width: 60, height: 60))
        }
    }
}
