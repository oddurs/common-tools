// The Common Tools icon body: Apple's 824 pt squircle on a 1024 canvas, a gradient in the app's own
// colour, and a frosted glass glyph. scripts/make-icon <app> joins this with apps/<app>/icon.swift,
// which draws the glyph, and shared/icon-main.swift, which writes the files.
import AppKit

// Shared look: Apple's 824 pt squircle on a 1024 canvas, a body in the app's colour, and a frosted
// glass glyph with a bright top edge, floating on a soft shadow. Every app's colour comes from the
// brand tokens (packages/common-ui/tokens.json): the same ramp of lightness and chroma, its own hue.

/// The app's colours, top to bottom, and Common Color's spectrum; icon-main sets them before drawing.
var brandTop = rgb(0x70bffe), brandMid = rgb(0x048ff4), brandDeep = rgb(0x005dca)
var brandSpectrum: [CGColor] = []

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
    ctx.addPath(shape); ctx.setFillColor(brandMid); ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(shape); ctx.clip()
    if brandSpectrum.isEmpty {
        linear(ctx, [brandTop, brandMid, brandDeep], CGPoint(x: 512, y: 924), CGPoint(x: 512, y: 100), [0, 0.45, 1])
    } else {
        // The whole wheel round the centre, as fine wedges blending stop to stop, then shaded toward
        // the bottom so it keeps its depth.
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let stops = brandSpectrum.map { $0.converted(to: space, intent: .defaultIntent, options: nil)!.components! }
        let centre = CGPoint(x: 512, y: 512)
        let wedges = 720
        for i in 0..<wedges {
            let t = CGFloat(i) / CGFloat(wedges) * CGFloat(stops.count)
            let a = stops[Int(t) % stops.count], b = stops[(Int(t) + 1) % stops.count], f = t - floor(t)
            ctx.setFillColor(red: a[0] + (b[0] - a[0]) * f, green: a[1] + (b[1] - a[1]) * f,
                blue: a[2] + (b[2] - a[2]) * f, alpha: 1)
            let start = CGFloat.pi / 2 - CGFloat(i) / CGFloat(wedges) * 2 * .pi
            ctx.move(to: centre)
            ctx.addArc(center: centre, radius: 760, startAngle: start, endAngle: start - 2 * .pi / CGFloat(wedges) * 1.6,
                clockwise: true)
            ctx.closePath(); ctx.fillPath()
        }
        linear(ctx, [rgb(0x000000, 0), rgb(0x000000, 0.1)], CGPoint(x: 512, y: 600), CGPoint(x: 512, y: 100))
    }
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

/// The body's deepest colour at `alpha`, for shadows that take the app's hue rather than black.
func shade(_ alpha: CGFloat) -> CGColor { brandDeep.copy(alpha: alpha)! }

/// Fills `path` as frosted glass: translucent white, brighter at the top, with a lit top edge
/// and a soft blue shadow under it.
func glass(_ ctx: CGContext, _ path: CGPath, opacity: CGFloat = 1) {
    let box = path.boundingBox
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 36, color: shade(0.6 * opacity))
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
    ctx.setShadow(offset: CGSize(width: 0, height: -4), blur: 10, color: shade(0.5))
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    draw()
    ctx.endTransparencyLayer()
    ctx.restoreGState()
}

func rounded(_ r: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

