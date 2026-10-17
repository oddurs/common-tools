// Common Command's icon glyph, drawn by scripts/make-icon command on the shared Common Tools body.

func glyph(_ ctx: CGContext) {
    // A search field: one line of glass, and the ⌘ that opens it.
    let panel = CGRect(x: 212, y: 292, width: 600, height: 440)
    glass(ctx, rounded(panel, 120))
    let font = NSFont.systemFont(ofSize: 330, weight: .medium) as CTFont
    var unichar = UniChar(0x2318)
    var glyphID = CGGlyph(0)
    CTFontGetGlyphsForCharacters(font, &unichar, &glyphID, 1)
    guard let symbol = CTFontCreatePathForGlyph(font, glyphID, nil) else { return }
    let box = symbol.boundingBox
    var place = CGAffineTransform(translationX: panel.midX - box.midX, y: panel.midY - box.midY)
    let centred = symbol.copy(using: &place)!
    ink(ctx) {
        ctx.addPath(centred)
        ctx.setFillColor(rgb(0xffffff))
        ctx.fillPath()
    }
}
