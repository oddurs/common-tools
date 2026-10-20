// Common Stats's icon glyph, drawn by scripts/make-icon stats on the shared Common Tools body.

func glyph(_ ctx: CGContext) {
    let panel = CGRect(x: 232, y: 272, width: 560, height: 480)
    glass(ctx, rounded(panel, 100))
    // A history graph: a quiet stretch, a dip, then a climb.
    let values: [CGFloat] = [0.22, 0.30, 0.24, 0.52, 0.42, 0.78]
    let plot = panel.insetBy(dx: 80, dy: 100)
    let pts = values.enumerated().map { i, v in
        CGPoint(x: plot.minX + plot.width * CGFloat(i) / CGFloat(values.count - 1), y: plot.minY + plot.height * v)
    }
    let line = CGMutablePath()
    line.move(to: pts[0])
    // Catmull-Rom through the points, so the curve passes through every sample without overshooting much.
    for i in 1..<pts.count {
        let p0 = pts[max(i - 2, 0)], p1 = pts[i - 1], p2 = pts[i], p3 = pts[min(i + 1, pts.count - 1)]
        let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
        let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
        line.addCurve(to: p2, control1: c1, control2: c2)
    }
    let area = line.mutableCopy()!
    area.addLine(to: CGPoint(x: plot.maxX, y: plot.minY)); area.addLine(to: CGPoint(x: plot.minX, y: plot.minY));
    area.closeSubpath()
    ctx.saveGState()
    ctx.addPath(area); ctx.clip()
    linear(ctx, [rgb(0xffffff, 0.55), rgb(0xffffff, 0.04)], CGPoint(x: 0, y: plot.maxY), CGPoint(x: 0, y: plot.minY))
    ctx.restoreGState()
    ink(ctx) {
        ctx.addPath(line); ctx.setStrokeColor(rgb(0xffffff)); ctx.setLineWidth(34); ctx.setLineCap(.round);
        ctx.setLineJoin(.round); ctx.strokePath()
        let end = pts.last!
        ctx.setFillColor(rgb(0xffffff));
        ctx.fillEllipse(in: CGRect(x: end.x - 30, y: end.y - 30, width: 60, height: 60))
    }
    ctx.setFillColor(brandMid);
    ctx.fillEllipse(in: CGRect(x: pts.last!.x - 14, y: pts.last!.y - 14, width: 28, height: 28))
}
