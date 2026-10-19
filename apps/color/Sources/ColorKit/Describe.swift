import Foundation

/// Words for a colour, for VoiceOver and for the line under the hero: a coarse family ("blue",
/// "dark grey", "vivid green") from OKLCH, where equal steps look equal. Not colour naming: no
/// "cornflower", only what someone who can't see the swatch needs to place it.
extension ColorValue {
    public var family: String {
        let lch = oklch
        if lch.c < 0.025 {
            if lch.l >= 0.95 { return "white" }
            if lch.l <= 0.15 { return "black" }
            return lch.l < 0.45 ? "dark grey" : lch.l > 0.8 ? "light grey" : "grey"
        }
        let hue = Self.hue(lch.h)
        // Dark, weak oranges and yellows are what people call brown.
        if hue == "orange" || hue == "yellow", lch.l < 0.55, lch.c < 0.15 { return "brown" }
        let modifier = Self.modifier(lightness: lch.l, chroma: lch.c)
        return modifier.isEmpty ? hue : "\(modifier) \(hue)"
    }

    /// "Light" and "pale" are for pastels: pure yellow and cyan are light by nature, and vivid.
    static func modifier(lightness: Double, chroma: Double) -> String {
        if lightness < 0.45 { return "dark" }
        if lightness > 0.85, chroma < 0.08 { return "pale" }
        if lightness > 0.85, chroma < 0.12 { return "light" }
        if chroma < 0.07 { return "muted" }
        return chroma > 0.2 ? "vivid" : ""
    }

    /// OKLCH hue in degrees to a family; the boundaries sit between the sRGB primaries and
    /// secondaries (red 29°, yellow 110°, green 142°, cyan 195°, blue 264°, magenta 328°).
    static func hue(_ degrees: Double) -> String {
        switch degrees {
        case 15..<45: "red"
        case 45..<75: "orange"
        case 75..<115: "yellow"
        case 115..<165: "green"
        case 165..<215: "cyan"
        case 215..<275: "blue"
        case 275..<335: "purple"
        default: "pink"
        }
    }

    /// Where the colour sits: what the line under the hero says.
    public var gamutDescription: String {
        if isInGamut(.sRGB) { return "sRGB" }
        return isInGamut(.displayP3) ? "Display P3, outside sRGB" : "Outside Display P3"
    }

    /// What VoiceOver says for a swatch: "Blue, hex 3A7BD5", and the gamut when sRGB can't hold it.
    public var spoken: String {
        let hex = ColorFormat.hex.string(self).dropFirst().uppercased()
        let gamut = isInGamut(.sRGB) ? "" : ", \(gamutDescription)"
        return "\(family.prefix(1).uppercased() + family.dropFirst()), hex \(hex)\(gamut)"
    }
}

extension Contrast {
    /// The highest bar it clears, in a few words: "Passes AAA", "Passes AA", "Large text only", "Fails AA".
    public var verdict: String {
        if passes(.aaa, .normal) { return "Passes AAA" }
        if passes(.aa, .normal) { return "Passes AA" }
        if passes(.aa, .large) { return "Large text only" }
        return "Fails AA"
    }

    /// The whole card as a sentence: "Contrast 4.47 to 1. Normal text: fails AA and AAA. Large text:
    /// passes AA, fails AAA."
    public var spoken: String {
        func size(_ size: TextSize) -> String {
            let (aa, aaa) = (passes(.aa, size), passes(.aaa, size))
            switch (aa, aaa) {
            case (true, true): return "passes AA and AAA"
            case (true, false): return "passes AA, fails AAA"
            default: return "fails AA and AAA"
            }
        }
        return "Contrast \(text.dropLast(2)) to 1. Normal text: \(size(.normal)). Large text: \(size(.large))."
    }
}

extension ColorFormat {
    /// The number key that copies this format in the panel: 1 for hex through 7 for AppKit.
    public var key: Character {
        Character(String(Self.allCases.firstIndex(of: self)! + 1))
    }

    public init?(key: Character) {
        guard let number = key.wholeNumberValue, Self.allCases.indices.contains(number - 1) else { return nil }
        self = Self.allCases[number - 1]
    }
}

/// Moving a selection through a grid that fills row by row, as the arrow keys do. Up and down stay
/// put at the first and last rows rather than wrap; with nothing selected, any arrow starts at the
/// first item.
public enum GridMove: Sendable {
    case left, right, up, down

    public func from(_ index: Int?, count: Int, columns: Int) -> Int? {
        guard count > 0 else { return nil }
        guard let index, index < count else { return 0 }
        switch self {
        case .left: return max(index - 1, 0)
        case .right: return min(index + 1, count - 1)
        case .up: return index - columns >= 0 ? index - columns : index
        case .down: return index + columns < count ? index + columns : index
        }
    }
}
