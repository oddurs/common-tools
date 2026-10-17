import AppKit

public enum BarStyle: String, Codable, CaseIterable, Sendable {
    case icon, iconAndPercent, percentInIcon, percent

    public var name: String {
        switch self {
        case .icon: "Icon"
        case .iconAndPercent: "Icon and Percentage"
        case .percentInIcon: "Percentage in Icon"
        case .percent: "Percentage"
        }
    }
}

public struct BarAppearance: Equatable, Sendable {
    public var style: BarStyle
    public var showsTime: Bool
    /// Red when low, yellow in Low Power Mode, as the system's own battery icon does.
    public var colorsAlerts: Bool

    public init(style: BarStyle, showsTime: Bool, colorsAlerts: Bool) {
        self.style = style
        self.showsTime = showsTime
        self.colorsAlerts = colorsAlerts
    }

    public static let standard = BarAppearance(style: .iconAndPercent, showsTime: false, colorsAlerts: true)
}

/// Draws the menu bar item. Widths depend only on the appearance, never on the reading, so the
/// item never shifts its neighbours as the level or the state changes.
///
/// Everything is black at varying opacity in a template image, so AppKit tints it like the
/// system's battery icon. Only an alert (low, or Low Power Mode, with colours on) draws in
/// dynamic system colours instead, which resolve against the menu bar's appearance.
public struct BarRenderer {
    public let appearance: BarAppearance
    public let height: CGFloat
    let parts: [(part: Part, x: CGFloat, width: CGFloat)]

    enum Part: Equatable { case time, percent, icon }

    public init(appearance: BarAppearance, height: CGFloat) {
        self.appearance = appearance
        self.height = height
        var kinds: [Part] = []
        if appearance.showsTime { kinds.append(.time) }
        if appearance.style == .iconAndPercent || appearance.style == .percent { kinds.append(.percent) }
        if appearance.style != .percent { kinds.append(.icon) }
        var x: CGFloat = 0
        var placed: [(Part, CGFloat, CGFloat)] = []
        for kind in kinds {
            if !placed.isEmpty { x += Self.partGap }
            let w = Self.width(of: kind, appearance.style)
            placed.append((kind, x, w))
            x += w
        }
        parts = placed
    }

    public var size: CGSize { CGSize(width: ceil(parts.last.map { $0.x + $0.width } ?? 0), height: height) }

    // MARK: Geometry

    // NSFont is immutable; Swift just can't see that.
    nonisolated(unsafe) static let textFont = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
    nonisolated(unsafe) static let insetFont = NSFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .bold)

    static let partGap: CGFloat = 4
    /// The outline and nub sit back from the fill, as the system draws them.
    static let outlineAlpha: CGFloat = 0.45
    static let nubGap: CGFloat = 1
    static let nubSize = CGSize(width: 1.5, height: 4.5)

    static func bodySize(_ style: BarStyle) -> CGSize {
        style == .percentInIcon ? CGSize(width: 33, height: 12.5) : CGSize(width: 23, height: 11.5)
    }

    static func width(of part: Part, _ style: BarStyle) -> CGFloat {
        switch part {
        case .time: measure(["88:88"], textFont)
        case .percent: measure(["100%"], textFont)
        case .icon: bodySize(style).width + nubGap + nubSize.width
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

    func ink(_ reading: BatteryReading) -> Ink {
        guard appearance.colorsAlerts else { return .template }
        if reading.isLow { return .alert(.systemRed) }
        if reading.isLowPowerMode { return .alert(.systemYellow) }
        return .template
    }

    // MARK: Drawing

    /// The item's image. Without a battery, a plug: the Mac runs on power from the wall.
    public func image(_ reading: BatteryReading?) -> NSImage {
        guard let reading else {
            let size = CGSize(width: 15, height: height)
            let image = NSImage(size: size, flipped: true) { _ in
                NSColor.black.setFill()
                Self.place(Self.plugGlyph, in: CGRect(x: 0, y: (size.height - 10) / 2, width: 15, height: 10)).fill()
                return true
            }
            image.isTemplate = true
            return image
        }
        let ink = self.ink(reading)
        let image = NSImage(size: size, flipped: true) { _ in
            for (part, x, width) in self.parts {
                switch part {
                case .time:
                    // A battery that isn't moving has no time to show; one still being estimated shows a dash.
                    guard reading.state == .charging || reading.state == .discharging else { break }
                    let text = reading.minutesRemaining.map { Format.duration(minutes: $0) } ?? Format.missing
                    self.drawText(text, ink: ink, x: x, width: width)
                case .percent:
                    self.drawText(Format.percent(reading.percent), ink: ink, x: x, width: width)
                case .icon:
                    self.drawIcon(reading, ink: ink, x: x)
                }
            }
            return true
        }
        image.isTemplate = ink.isTemplate
        return image
    }

    private func drawText(_ text: String, ink: Ink, x: CGFloat, width: CGFloat) {
        let font = Self.textFont
        let string = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: ink.text])
        let baseline = (height + font.capHeight) / 2
        // In a flipped context the drawing origin is the line's top; the baseline sits one ascender below.
        string.draw(at: CGPoint(x: x + width - string.size().width, y: baseline - font.ascender))
    }

    private func drawIcon(_ reading: BatteryReading, ink: Ink, x: CGFloat) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let style = appearance.style
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
        if reading.state == .charging, style != .percentInIcon {
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
        // bolt) is cut out of the fill and drawn in ink beyond it, so it reads at any level.
        let glyph: NSBezierPath? =
            switch reading.state {
            case .charging: Self.bolt
            case .charged, .notCharging: Self.plugGlyph
            case .discharging: nil
            }
        var marks: [NSBezierPath] = []
        var text: (NSAttributedString, CGPoint)?
        if style == .percentInIcon {
            var content = inner.insetBy(dx: 1, dy: 0)
            if let glyph {
                let h = glyph === Self.bolt ? inner.height - 1 : inner.height - 2.5
                let w = h * Self.aspect(glyph)
                marks.append(Self.place(glyph, in: CGRect(x: content.minX, y: inner.midY - h / 2, width: w, height: h)))
                content.origin.x += w + 0.5
                content.size.width -= w + 0.5
            }
            let font = Self.insetFont
            let number = NSAttributedString(string: "\(reading.percent)", attributes: [.font: font])
            let origin = CGPoint(
                x: content.midX - number.size().width / 2, y: inner.midY + font.capHeight / 2 - font.ascender)
            text = (number, origin)
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
        ctx.setBlendMode(.destinationOut)
        drawMarks(.black)
        ctx.restoreGState()
        ctx.saveGState()
        ctx.clip(to: CGRect(x: fill.maxX, y: body.minY, width: body.maxX - fill.maxX, height: body.height))
        drawMarks(ink.text)
        ctx.restoreGState()
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
