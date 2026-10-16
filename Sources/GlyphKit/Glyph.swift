/// What the glyph is drawn from. Each kind keeps its own source and edit, so switching between them
/// loses nothing.
public enum SourceKind: String, Codable, CaseIterable, Identifiable, Sendable {
    /// An image file the app keeps a copy of.
    case image
    /// An emoji, a symbol, a kaomoji, or a word, drawn in the system font.
    case text

    public var id: Self { self }

    /// A four-pointed star: reads as a glyph in any menu bar, and says what the app is for.
    public static let initialText = "✦"
}

extension Style {
    /// Emoji are drawn in their own colours; other text is drawn like the menu bar's own.
    public static func suggested(forText text: String) -> Style {
        let emoji = text.unicodeScalars.contains { $0.properties.isEmojiPresentation || $0 == "\u{FE0F}" }
        return emoji ? .color : .silhouette
    }
}

extension Edit {
    /// Where a text glyph starts: drawn like the menu bar's own items.
    public static var text: Edit {
        var edit = Edit()
        edit.style = .silhouette
        return edit
    }
}

/// The glyph's size in the menu bar, in points.
public struct GlyphSize: Equatable, Sendable {
    public let width: Double
    public let height: Double

    /// Wide enough for a tattoo band or a short word, narrow enough that it can't crowd out the menus.
    public static let maximumWidth = 180.0
    public static let scaleRange = 0.5...1.0

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    /// An image of the given pixel size, `scale` of the bar's thickness tall, shrunk further only if
    /// it would be wider than `maximumWidth`. Whole points, so the glyph sits on the pixel grid.
    public init(pixelWidth: Int, pixelHeight: Int, barThickness: Double, scale: Double) {
        let aspect = Double(max(pixelWidth, 1)) / Double(max(pixelHeight, 1))
        let s = min(max(scale, Self.scaleRange.lowerBound), Self.scaleRange.upperBound)
        var h = max(1, (barThickness * s).rounded())
        var w = h * aspect
        if w > Self.maximumWidth {
            w = Self.maximumWidth
            h = max(1, w / aspect)
        }
        self.init(width: max(1, w.rounded()), height: h.rounded())
    }
}

public enum FrameTiming {
    /// The delay before an animated image's next frame, in seconds. Browsers play delays of 10 ms or
    /// less at 100 ms, and GIFs are made to look right in browsers, so this does the same.
    public static func delay(unclamped: Double?, clamped: Double?) -> Double {
        let delay = unclamped ?? clamped ?? 0
        return delay <= 0.01 ? 0.1 : delay
    }

    /// Which frame of a looping animation shows `time` seconds after it started.
    public static func frame(at time: Double, delays: [Double]) -> Int {
        let total = delays.reduce(0, +)
        guard total > 0, time.isFinite else { return 0 }
        var t = time.truncatingRemainder(dividingBy: total)
        if t < 0 { t += total }
        for (i, delay) in delays.enumerated() {
            if t < delay { return i }
            t -= delay
        }
        return delays.count - 1
    }
}
