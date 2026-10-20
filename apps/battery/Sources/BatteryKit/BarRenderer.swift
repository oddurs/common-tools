import AppKit

/// Draws the menu bar item. Widths depend only on the appearance, never on the reading, so the
/// item never shifts its neighbours as the level or the state changes. Within that width, what is
/// drawn is centred by its ink, so a short reading ("8%", or a time-only item showing a plug) sits
/// in the middle rather than against one side.
///
/// Everything is black at varying opacity in a template image, so AppKit tints it like the
/// system's battery icon. Only an alert (low, or Low Power Mode, with colours on) draws in
/// dynamic system colours instead, which resolve against the menu bar's appearance.
public struct BarRenderer {
    public let appearance: BarAppearance
    public let height: CGFloat
    public let size: CGSize

    public init(appearance: BarAppearance, height: CGFloat) {
        self.appearance = appearance
        self.height = height
        let widths = appearance.parts.map { Self.width(of: $0, appearance.iconStyle) }
        let gaps = Self.partGap * CGFloat(widths.count - 1)
        size = CGSize(width: ceil(widths.reduce(0, +) + gaps), height: height)
    }

    // MARK: Geometry

    // NSFont is immutable; Swift just can't see that.
    nonisolated(unsafe) static let textFont = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
    nonisolated(unsafe) static let insetFont = NSFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .bold)

    static let partGap: CGFloat = 4
    /// The outline and nub sit back from the fill, as the system draws them.
    static let outlineAlpha: CGFloat = 0.45
    static let nubGap: CGFloat = 1
    static let nubSize = CGSize(width: 1.5, height: 4.5)
    static let plugSize = CGSize(width: 15, height: 10)
    /// In Percentage in Icon, the clear space between what's drawn and the sides of the fill area,
    /// and between the glyph and the number.
    static let insetPadding: CGFloat = 1
    static let glyphGap: CGFloat = 1.5

    static func bodySize(_ style: IconStyle) -> CGSize {
        style == .percentInside ? CGSize(width: 33, height: 12.5) : CGSize(width: 23, height: 11.5)
    }

    static func iconWidth(_ style: IconStyle) -> CGFloat { bodySize(style).width + nubGap + nubSize.width }

    /// The most a part can take, whatever the reading.
    static func width(of part: BarPart, _ style: IconStyle) -> CGFloat {
        switch part {
        case .time: measure(["88:88"], textFont)
        case .percent: measure(["100%"], textFont)
        case .battery: iconWidth(style)
        }
    }

    static func measure(_ texts: [String], _ font: NSFont) -> CGFloat {
        ceil(texts.map { NSAttributedString(string: $0, attributes: [.font: font]).size().width }.max() ?? 0)
    }

    // MARK: Ink

    struct Ink {
        let text: NSColor
        let outline: NSColor
        let fill: NSColor
        let isTemplate: Bool

        static let template = Ink(
            text: .black, outline: .black.withAlphaComponent(outlineAlpha), fill: .black, isTemplate: true)

        static func alert(_ fill: NSColor) -> Ink {
            // secondaryLabelColor, not labelColor with alpha: a dynamic colour with alpha added
            // resolves once, against whatever appearance is current when it's made.
            Ink(text: .labelColor, outline: .secondaryLabelColor, fill: fill, isTemplate: false)
        }
    }

    /// Black or white, whichever reads better on `fill` as it resolves in the current appearance.
    static func legible(on fill: NSColor) -> NSColor {
        contrast(.black, fill) >= contrast(.white, fill) ? .black : .white
    }

    /// The WCAG contrast ratio between two colours, from 1 to 21.
    static func contrast(_ a: NSColor, _ b: NSColor) -> CGFloat {
        func luminance(_ color: NSColor) -> CGFloat {
            guard let c = color.usingColorSpace(.sRGB) else { return 0 }
            func linear(_ v: CGFloat) -> CGFloat { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
            return 0.2126 * linear(c.redComponent) + 0.7152 * linear(c.greenComponent)
                + 0.0722 * linear(c.blueComponent)
        }
        let (x, y) = (luminance(a), luminance(b))
        return (max(x, y) + 0.05) / (min(x, y) + 0.05)
    }

    func ink(_ reading: BatteryReading) -> Ink {
        guard appearance.colorsAlerts else { return .template }
        if reading.isLow { return .alert(.systemRed) }
        if reading.isLowPowerMode { return .alert(.systemYellow) }
        return .template
    }

    // MARK: Drawing

    /// Something drawn in the item: how far it advances, where its ink starts and ends relative
    /// to its origin, and how to draw it there.
    struct Piece {
        let advance: CGFloat
        let ink: ClosedRange<CGFloat>
        let draw: (CGFloat) -> Void
    }

    /// The item's image. Without a battery, a plug: the Mac runs on power from the wall.
    public func image(_ reading: BatteryReading?) -> NSImage {
        guard let reading else {
            let size = CGSize(width: Self.plugSize.width, height: height)
            let image = NSImage(size: size, flipped: true) { _ in
                self.plugPiece(.black).draw(0)
                return true
            }
            image.isTemplate = true
            return image
        }
        let ink = self.ink(reading)
        let image = NSImage(size: size, flipped: true) { _ in
            let pieces = self.pieces(reading, ink: ink)
            for (piece, x) in zip(pieces, self.positions(pieces)) { piece.draw(x) }
            return true
        }
        image.isTemplate = ink.isTemplate
        return image
    }

    private func pieces(_ reading: BatteryReading, ink: Ink) -> [Piece] {
        appearance.parts.compactMap { part in
            switch part {
            case .time:
                // One still being estimated shows a dash. A battery that isn't moving has no time:
                // beside the icon, which already shows the plug, nothing; on its own, the plug, so
                // the item never goes blank.
                if reading.state == .charging || reading.state == .discharging {
                    let time = reading.minutesRemaining.map { Format.duration(minutes: $0) }
                    return textPiece(time ?? Format.missing, ink)
                }
                return appearance.parts.contains(.battery) ? nil : plugPiece(ink.text)
            case .percent:
                return textPiece(Format.percent(reading.percent), ink)
            case .battery:
                let width = Self.iconWidth(appearance.iconStyle)
                return Piece(advance: width, ink: 0...width) { self.drawIcon(reading, ink: ink, x: $0) }
            }
        }
    }

    /// Where each piece goes: one gap apart, on whole points so the icon's outline stays sharp,
    /// and as a group centred by ink in the item's fixed width, so the slack falls evenly on
    /// both sides however short the reading is.
    private func positions(_ pieces: [Piece]) -> [CGFloat] {
        guard let first = pieces.first, let last = pieces.last else { return [] }
        var xs: [CGFloat] = [0]
        for piece in pieces.dropLast() { xs.append((xs[xs.count - 1] + piece.advance + Self.partGap).rounded()) }
        let lo = first.ink.lowerBound, hi = xs[xs.count - 1] + last.ink.upperBound
        let offset = ((size.width - (hi - lo)) / 2 - lo).rounded()
        return xs.map { $0 + offset }
    }

    private func textPiece(_ text: String, _ ink: Ink) -> Piece {
        let font = Self.textFont
        let string = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: ink.text])
        // The glyphs' own extent, not the advance: digits and "%" carry side bearings.
        let bounds = CTLineGetImageBounds(CTLineCreateWithAttributedString(string), nil)
        let baseline = (height + font.capHeight) / 2
        return Piece(advance: string.size().width, ink: bounds.minX...bounds.maxX) { x in
            // In a flipped context the drawing origin is the line's top; the baseline sits one ascender below.
            string.draw(at: CGPoint(x: x, y: baseline - font.ascender))
        }
    }

    private func plugPiece(_ color: NSColor) -> Piece {
        let size = Self.plugSize
        return Piece(advance: size.width, ink: 0...size.width) { x in
            color.setFill()
            Self.place(
                Self.plugGlyph,
                in: CGRect(x: x, y: (self.height - size.height) / 2, width: size.width, height: size.height)
            ).fill()
        }
    }

    private func drawIcon(_ reading: BatteryReading, ink: Ink, x: CGFloat) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let style = appearance.iconStyle
        let size = Self.bodySize(style)
        let body = CGRect(x: x, y: ((height - size.height) / 2).rounded(), width: size.width, height: size.height)

        ink.outline.setStroke()
        let outline = NSBezierPath(roundedRect: body.insetBy(dx: 0.5, dy: 0.5), xRadius: 3.5, yRadius: 3.5)
        outline.lineWidth = 1
        outline.stroke()
        ink.outline.setFill()
        let nub = CGRect(
            x: body.maxX + Self.nubGap, y: body.midY - Self.nubSize.height / 2, width: Self.nubSize.width,
            height: Self.nubSize.height)
        NSBezierPath(roundedRect: nub, xRadius: 0.75, yRadius: 0.75).fill()

        let inner = body.insetBy(dx: 2, dy: 2)
        let level = CGFloat(min(max(reading.level, 0), 1))
        var fill = inner
        fill.size.width = level > 0 ? max(inner.width * level, 1.5) : 0
        ink.fill.setFill()
        NSBezierPath(roundedRect: fill, xRadius: 1.5, yRadius: 1.5).fill()

        // The bolt sits over the middle with a clear halo and spills past the body, as the system
        // draws it, so it reads over any fill.
        if reading.state == .charging, style != .percentInside {
            let h = size.height + 2
            let w = h * Self.aspect(Self.bolt)
            let path = Self.place(
                Self.bolt, in: CGRect(x: body.midX - w / 2, y: body.midY - h / 2, width: w, height: h))
            ctx.saveGState()
            ctx.setBlendMode(.clear)
            path.lineWidth = 2.5
            path.stroke()
            ctx.restoreGState()
            ink.text.setFill()
            path.fill()
            return
        }

        // Everything else inside the body (the plug, and in Percentage in Icon the number and the
        // bolt) is drawn in ink beyond the fill and, over it, cut out of a template's fill, as the
        // system draws it: the menu bar shows through, and contrasts with a fill AppKit tints in
        // the bar's own text colour. A coloured fill can be as pale as the bar (yellow on a light
        // one), so on it they're drawn in black or white, whichever reads against that colour.
        let glyph: NSBezierPath? =
            switch reading.state {
            case .charging: Self.bolt
            case .charged, .notCharging: Self.plugGlyph
            case .discharging: nil
            }
        var marks: [NSBezierPath] = []
        var text: (NSAttributedString, CGPoint)?
        if style == .percentInside {
            let layout = Self.insetLayout("\(reading.percent)", glyph: glyph, in: inner)
            if let glyph, let rect = layout.glyph { marks.append(Self.place(glyph, in: rect)) }
            text = (layout.number, layout.origin)
        } else if let glyph {
            let h = inner.height - 0.5
            let w = h * Self.aspect(glyph)
            marks.append(
                Self.place(glyph, in: CGRect(x: inner.midX - w / 2, y: inner.midY - h / 2, width: w, height: h)))
        }
        guard !marks.isEmpty || text != nil else { return }

        func drawMarks(_ color: NSColor) {
            color.setFill()
            marks.forEach { $0.fill() }
            if let (string, origin) = text {
                let colored = NSMutableAttributedString(attributedString: string)
                colored.addAttribute(
                    .foregroundColor, value: color, range: NSRange(location: 0, length: colored.length))
                colored.draw(at: origin)
            }
        }
        ctx.saveGState()
        ctx.clip(to: fill)
        if ink.isTemplate {
            ctx.setBlendMode(.destinationOut)
            drawMarks(.black)
        } else {
            drawMarks(Self.legible(on: ink.fill))
        }
        ctx.restoreGState()
        ctx.saveGState()
        ctx.clip(to: CGRect(x: fill.maxX, y: body.minY, width: body.maxX - fill.maxX, height: body.height))
        drawMarks(ink.text)
        ctx.restoreGState()
    }

    /// Where Percentage in Icon puts its glyph and number inside the body: the rect the glyph fills,
    /// the number, where it's drawn from, and the extent of its ink.
    struct InsetLayout {
        let glyph: CGRect?
        let number: NSAttributedString
        let origin: CGPoint
        let ink: CGRect
    }

    /// The glyph, a gap, and the number's ink (not its advance: digits carry side bearings) are
    /// centred together as one group. A glyph is as wide as fits beside "100" with `glyphGap`
    /// between them and `insetPadding` to spare at both ends, and no taller than the body allows.
    static func insetLayout(_ text: String, glyph: NSBezierPath?, in inner: CGRect) -> InsetLayout {
        let font = insetFont
        func line(_ text: String) -> NSAttributedString { NSAttributedString(string: text, attributes: [.font: font]) }
        func ink(_ line: NSAttributedString) -> CGRect {
            CTLineGetImageBounds(CTLineCreateWithAttributedString(line), nil)
        }
        let number = line(text)
        let bounds = ink(number)
        let glyphSize = glyph.map { glyph in
            let room = inner.width - 2 * insetPadding - glyphGap - ink(line("100")).width
            let h = min(glyph === bolt ? inner.height - 1 : inner.height - 2.5, room / aspect(glyph))
            return CGSize(width: h * aspect(glyph), height: h)
        }
        let lead = glyphSize.map { $0.width + glyphGap } ?? 0
        let start = inner.midX - (lead + bounds.width) / 2
        let glyphRect = glyphSize.map {
            CGRect(x: start, y: inner.midY - $0.height / 2, width: $0.width, height: $0.height)
        }
        // The flipped drawing starts the line at its top; its baseline sits one ascender below.
        let baseline = inner.midY + font.capHeight / 2
        let origin = CGPoint(x: start + lead - bounds.minX, y: baseline - font.ascender)
        let numberInk = CGRect(x: start + lead, y: baseline - bounds.maxY, width: bounds.width, height: bounds.height)
        return InsetLayout(glyph: glyphRect, number: number, origin: origin, ink: numberInk)
    }

    // MARK: Glyphs

    /// A lightning bolt in a unit square, y down.
    nonisolated(unsafe) static let bolt: NSBezierPath = polygon([
        (0.64, 0), (0.06, 0.58), (0.44, 0.58), (0.34, 1), (0.94, 0.40), (0.56, 0.40),
    ])

    /// A plug pointing right in a unit square, y down: cord, head, two prongs. Drawn at `aspect`
    /// times as wide as it is tall.
    nonisolated(unsafe) static let plugGlyph: NSBezierPath = {
        let p = NSBezierPath()
        p.append(NSBezierPath(rect: CGRect(x: 0, y: 0.4, width: 0.3, height: 0.2)))
        p.append(NSBezierPath(roundedRect: CGRect(x: 0.26, y: 0, width: 0.4, height: 1), xRadius: 0.08, yRadius: 0.15))
        p.append(NSBezierPath(rect: CGRect(x: 0.66, y: 0.18, width: 0.34, height: 0.18)))
        p.append(NSBezierPath(rect: CGRect(x: 0.66, y: 0.64, width: 0.34, height: 0.18)))
        return p
    }()

    static func aspect(_ glyph: NSBezierPath) -> CGFloat { glyph === bolt ? 0.62 : 1.5 }

    static func polygon(_ points: [(CGFloat, CGFloat)]) -> NSBezierPath {
        let p = NSBezierPath()
        for (i, (x, y)) in points.enumerated() {
            i == 0 ? p.move(to: CGPoint(x: x, y: y)) : p.line(to: CGPoint(x: x, y: y))
        }
        p.close()
        return p
    }

    static func place(_ unit: NSBezierPath, in rect: CGRect) -> NSBezierPath {
        let path = unit.copy() as! NSBezierPath
        var t = AffineTransform(translationByX: rect.minX, byY: rect.minY)
        t.scale(x: rect.width, y: rect.height)
        path.transform(using: t)
        return path
    }

    // MARK: Redrawing

    /// Whether the status item needs drawing now. Redraws are skipped while nobody can see the
    /// item (behind the notch, collapsed by a menu bar manager, under a full-screen app), but
    /// never the first drawing or one that changes the width: a new item starts hidden, and
    /// without an image it would stay an empty sliver that nobody could find.
    public static func mustDraw(hasImage: Bool, resized: Bool, visible: Bool, menuOpen: Bool) -> Bool {
        !hasImage || resized || visible || menuOpen
    }

    // MARK: Accessibility

    public static func accessibilityText(_ reading: BatteryReading?) -> String {
        guard let reading else { return "No battery" }
        var parts = ["Battery \(Format.percent(reading.percent))", Format.status(reading)]
        if reading.isLowPowerMode { parts.append("Low Power Mode") }
        return parts.joined(separator: ", ")
    }
}
