/// How the glyph is coloured in the menu bar.
public enum Style: String, Codable, CaseIterable, Identifiable, Sendable {
    /// The image's own colours.
    case color
    /// The image's shape, drawn in the menu bar's text colour.
    case silhouette
    /// The image's dark lines, drawn in the menu bar's text colour: line art, tattoo flash, a scan.
    case ink

    public var id: Self { self }

    /// Silhouette and ink become template images, which macOS tints to match the menu bar.
    public var isTemplate: Bool { self != .color }
}

extension Bitmap {
    /// Template images keep only their alpha, so silhouette and ink paint black and carry the glyph's
    /// shape in alpha. Ink keeps pixels darker than `threshold`, or lighter when `inverted`.
    public func styled(_ style: Style, threshold: Double, inverted: Bool) -> Bitmap {
        guard style != .color else { return self }
        // A narrow ramp around the threshold keeps anti-aliased lines smooth instead of jagged.
        let ramp = 0.06
        var out = self
        for y in 0..<height {
            for x in 0..<width {
                let p = self[x, y]
                var coverage = 1.0
                if style == .ink {
                    coverage = min(max((threshold - p.luminance) / ramp + 0.5, 0), 1)
                    if inverted { coverage = 1 - coverage }
                }
                out[x, y] = Pixel(0, 0, 0, UInt8((Double(p.a) * coverage).rounded()))
            }
        }
        return out
    }
}
