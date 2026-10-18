import Foundation

/// The ways a colour is written down, each as code that pastes as it is: CSS, SwiftUI, or AppKit.
public enum ColorFormat: String, CaseIterable, Codable, Sendable {
    case hex
    case rgb
    case hsl
    case oklch
    case displayP3
    case swiftUI
    case appKit

    public var title: String {
        switch self {
        case .hex: "Hex"
        case .rgb: "RGB"
        case .hsl: "HSL"
        case .oklch: "OKLCH"
        case .displayP3: "Display P3"
        case .swiftUI: "SwiftUI"
        case .appKit: "AppKit"
        }
    }

    /// The space the format's numbers are in; OKLCH reaches every colour, so it has none.
    public var gamut: RGBSpace? {
        switch self {
        case .hex, .rgb, .hsl: .sRGB
        case .displayP3, .swiftUI, .appKit: .displayP3
        case .oklch: nil
        }
    }

    /// False when the colour is outside what the format can hold, and the text is the nearest
    /// colour that it can (CSS gamut mapping), not the colour itself.
    public func isExact(_ color: ColorValue) -> Bool {
        gamut.map(color.isInGamut) ?? true
    }

    public func string(_ color: ColorValue) -> String {
        switch self {
        case .hex:
            return "#" + Self.bytes(color).map { String(format: "%02x", $0) }.joined()
        case .rgb:
            return "rgb(\(Self.bytes(color).map(String.init).joined(separator: " ")))"
        case .hsl:
            let (h, s, l) = Self.hsl(color.mapped(into: .sRGB))
            return "hsl(\(Self.number(h, 1)) \(Self.number(s * 100, 1))% \(Self.number(l * 100, 1))%)"
        case .oklch:
            let lch = color.oklch
            let chroma = Self.number(lch.c, 4)
            // A grey has no hue, and CSS says so with `none` rather than an arbitrary angle.
            let hue = chroma == "0" ? "none" : Self.number(lch.h, 2)
            return "oklch(\(Self.number(lch.l * 100, 2))% \(chroma) \(hue))"
        case .displayP3:
            return "color(display-p3 \(Self.decimals(color.mapped(into: .displayP3)).joined(separator: " ")))"
        case .swiftUI:
            let (space, c) = Self.appleSpace(color)
            let d = Self.decimals(c)
            return "Color(.\(space == .sRGB ? "sRGB" : "displayP3"), red: \(d[0]), green: \(d[1]), blue: \(d[2]))"
        case .appKit:
            let (space, c) = Self.appleSpace(color)
            let d = Self.decimals(c)
            return
                "NSColor(\(space == .sRGB ? "srgbRed" : "displayP3Red"): \(d[0]), green: \(d[1]), blue: \(d[2]), alpha: 1)"
        }
    }

    /// Apple's formats name their space, so a colour sRGB holds is written in sRGB, where its
    /// numbers match the hex, and anything wider in Display P3, where it fits.
    private static func appleSpace(_ color: ColorValue) -> (RGBSpace, SIMD3<Double>) {
        color.isInGamut(.sRGB)
            ? (.sRGB, color.mapped(into: .sRGB)) : (.displayP3, color.mapped(into: .displayP3))
    }

    private static func bytes(_ color: ColorValue) -> [Int] {
        let c = color.mapped(into: .sRGB)
        return [c.x, c.y, c.z].map { Int(($0 * 255).rounded()) }
    }

    private static func decimals(_ c: SIMD3<Double>) -> [String] {
        [c.x, c.y, c.z].map { number($0, 4) }
    }

    /// Hue in degrees, saturation and lightness 0–1, from gamma-encoded sRGB (CSS Color 4).
    static func hsl(_ c: SIMD3<Double>) -> (Double, Double, Double) {
        let high = c.max(), low = c.min()
        let lightness = (high + low) / 2
        let delta = high - low
        guard delta > 0 else { return (0, 0, lightness) }
        let saturation = delta / (1 - abs(2 * lightness - 1))
        var hue: Double
        switch high {
        case c.x: hue = (c.y - c.z) / delta + (c.y < c.z ? 6 : 0)
        case c.y: hue = (c.z - c.x) / delta + 2
        default: hue = (c.x - c.y) / delta + 4
        }
        hue *= 60
        return (hue >= 360 ? hue - 360 : hue, saturation, lightness)
    }

    /// At most `places` decimals, without trailing zeros, and never "-0": code, not prose, so the
    /// separator is always a point whatever the Mac's region.
    static func number(_ value: Double, _ places: Int) -> String {
        let text = String(format: "%.\(places)f", value)
        var trimmed = text.contains(".") ? String(text.reversed().drop { $0 == "0" }.reversed()) : text
        if trimmed.hasSuffix(".") { trimmed.removeLast() }
        return trimmed == "-0" ? "0" : trimmed
    }
}
