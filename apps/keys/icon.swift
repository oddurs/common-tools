// Common Keys's icon glyph, drawn by scripts/make-icon keys on the shared Common Tools body.

func text(_ ctx: CGContext, _ s: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, center: CGPoint) {
    let font = NSFont.systemFont(ofSize: size, weight: weight)
    let attr = NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: color])
    let line = CTLineCreateWithAttributedString(attr)
    let b = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
    ctx.textPosition = CGPoint(x: center.x - b.midX, y: center.y - b.midY)
    CTLineDraw(line, ctx)
}

func glyph(_ ctx: CGContext) {
    // A keycap seen from above: a glass cap on a darker skirt.
    let cap = CGRect(x: 232, y: 262, width: 560, height: 520)
    ctx.saveGState()
    ctx.addPath(rounded(cap.offsetBy(dx: 0, dy: -26), 120)); ctx.setFillColor(shade(0.55)); ctx.fillPath()
    ctx.restoreGState()
    glass(ctx, rounded(cap, 120))
    ink(ctx) {
        text(ctx, "A", size: 240, weight: .semibold, color: .white, center: CGPoint(x: 405, y: 560))
        text(
            ctx, "Ж", size: 240, weight: .semibold, color: NSColor.white.withAlphaComponent(0.7),
            center: CGPoint(x: 622, y: 480))
    }
}
