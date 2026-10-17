// The Common Tools icon body: Apple's 824 pt squircle on a 1024 canvas, a blue gradient, and a
// frosted glass glyph. scripts/make-icon <app> joins this with apps/<app>/icon.swift, which draws
// the glyph, and shared/icon-main.swift, which writes the files.
import AppKit


// Shared look: Apple's 824 pt squircle on a 1024 canvas, a blue gradient body, and a frosted
// glass glyph with a bright top edge, floating on a soft shadow.

func squircle(_ r: CGRect, n: CGFloat = 4.6) -> CGPath {
    // A superellipse, closer to Apple's continuous corners than a rounded rect.
    let p = CGMutablePath()
    let a = r.width / 2, b = r.height / 2, cx = r.midX, cy = r.midY
    for i in 0...720 {
        let t = CGFloat(i) / 720 * 2 * .pi
        let c = cos(t), s = sin(t)
        let x = cx + a * (c < 0 ? -1 : 1) * pow(abs(c), 2 / n)
        let y = cy + b * (s < 0 ? -1 : 1) * pow(abs(s), 2 / n)
        i == 0 ? p.move(to: CGPoint(x: x, y: y)) : p.addLine(to: CGPoint(x: x, y: y))
    }
    p.closeSubpath()
    return p
}

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
        blue: CGFloat(hex & 255) / 255, alpha: a)
}

func linear(_ ctx: CGContext, _ colors: [CGColor], _ from: CGPoint, _ to: CGPoint, _ locations: [CGFloat]? = nil) {
    let g = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray, locations: locations)!
    ctx.drawLinearGradient(g, start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
}

func radial(_ ctx: CGContext, _ colors: [CGColor], _ c: CGPoint, _ r: CGFloat) {
    let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray, locations: nil)!
    ctx.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: r, options: [])
}

let body = CGRect(x: 100, y: 100, width: 824, height: 824)

func background(_ ctx: CGContext) {
    let shape = squircle(body)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: rgb(0x000000, 0.32))
    ctx.addPath(shape); ctx.setFillColor(rgb(0x1a6ff0)); ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(shape); ctx.clip()
    linear(
        ctx, [rgb(0x5cb1ff), rgb(0x2a84f7), rgb(0x0b52d1)], CGPoint(x: 512, y: 924), CGPoint(x: 512, y: 100),
        [0, 0.45, 1])
    // A wide glow from the top left, as if lit from above.
    radial(ctx, [rgb(0xffffff, 0.30), rgb(0xffffff, 0)], CGPoint(x: 330, y: 900), 620)
    // Rim light: a thin bright edge along the top, fading down the sides.
    ctx.setLineWidth(10)
    ctx.addPath(shape)
    ctx.replacePathWithStrokedPath()
    ctx.clip()
    linear(
        ctx, [rgb(0xffffff, 0.75), rgb(0xffffff, 0.12), rgb(0xffffff, 0.0), rgb(0xffffff, 0.18)],
        CGPoint(x: 512, y: 924), CGPoint(x: 512, y: 100), [0, 0.3, 0.7, 1])
    ctx.restoreGState()
}

/// Fills `path` as frosted glass: translucent white, brighter at the top, with a lit top edge
/// and a soft blue shadow under it.
func glass(_ ctx: CGContext, _ path: CGPath, opacity: CGFloat = 1) {
    let box = path.boundingBox
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 36, color: rgb(0x002a80, 0.45 * opacity))
    ctx.addPath(path); ctx.setFillColor(rgb(0xffffff, 0.22 * opacity)); ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(path); ctx.clip()
    linear(
        ctx, [rgb(0xffffff, 0.50 * opacity), rgb(0xffffff, 0.16 * opacity)], CGPoint(x: box.midX, y: box.maxY),
        CGPoint(x: box.midX, y: box.minY))
    ctx.restoreGState()

    // Liquid Glass catches light on two opposite edges: strong at the top left, softer at the bottom right.
    ctx.saveGState()
    ctx.setLineWidth(7)
    ctx.addPath(path); ctx.replacePathWithStrokedPath(); ctx.clip()
    linear(
        ctx,
        [
            rgb(0xffffff, 1.0 * opacity), rgb(0xffffff, 0.18 * opacity), rgb(0xffffff, 0.18 * opacity),
            rgb(0xffffff, 0.7 * opacity),
        ], CGPoint(x: box.minX, y: box.maxY), CGPoint(x: box.maxX, y: box.minY), [0, 0.4, 0.6, 1])
    ctx.restoreGState()
}

/// Solid white marks that sit on the glass, with a faint shadow so they read as raised.
func ink(_ ctx: CGContext, _ draw: () -> Void) {
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -4), blur: 10, color: rgb(0x003399, 0.35))
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    draw()
    ctx.endTransparencyLayer()
    ctx.restoreGState()
}

func rounded(_ r: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

