// Common Bar's icon glyph, drawn by scripts/make-icon bar on the shared Common Tools body.

func glyph(_ ctx: CGContext) {
    // A menu bar strip: hidden items fading out to the left of the divider, the chevron, then visible items.
    let strip = CGRect(x: 172, y: 402, width: 680, height: 220)
    glass(ctx, rounded(strip, 110))
    let y = strip.midY
    for (i, x) in [262.0, 352.0].enumerated() {
        ctx.setFillColor(rgb(0xffffff, 0.28 + 0.16 * CGFloat(i)))
        ctx.fillEllipse(in: CGRect(x: x - 26, y: y - 26, width: 52, height: 52))
    }
    ink(ctx) {
        ctx.setFillColor(rgb(0xffffff, 0.9))
        ctx.addPath(rounded(CGRect(x: 431, y: y - 58, width: 14, height: 116), 7)); ctx.fillPath()
        // chevron.compact.left, drawn as two strokes.
        ctx.setStrokeColor(rgb(0xffffff)); ctx.setLineWidth(26); ctx.setLineCap(.round); ctx.setLineJoin(.round)
        ctx.move(to: CGPoint(x: 548, y: y + 50)); ctx.addLine(to: CGPoint(x: 508, y: y));
        ctx.addLine(to: CGPoint(x: 548, y: y - 50)); ctx.strokePath()
        for x in [652.0, 752.0] {
            ctx.setFillColor(rgb(0xffffff)); ctx.fillEllipse(in: CGRect(x: x - 30, y: y - 30, width: 60, height: 60))
        }
    }
}
