import Foundation

/// One colour, held as linear-light sRGB without bounds, so a colour outside sRGB (a Display P3
/// green, say) is kept exactly: its components just fall below 0 or above 1. Every format is
/// derived from this, and nothing is clipped until a format that can't hold the colour asks for
/// it, and then it says so (`isInGamut`).
public struct ColorValue: Hashable, Sendable {
    public let linearSRGB: SIMD3<Double>

    public init(linearSRGB: SIMD3<Double>) {
        self.linearSRGB = linearSRGB
    }

    /// From gamma-encoded components in `space`, as a colour picker, CSS, or `NSColor` gives them.
    public init(_ space: RGBSpace, red: Double, green: Double, blue: Double) {
        let linear = SIMD3(red, green, blue).map(RGBSpace.linear)
        linearSRGB = space == .sRGB ? linear : Self.p3ToSRGB * linear
    }

    /// Gamma-encoded components in `space`, unbounded.
    public func components(in space: RGBSpace) -> SIMD3<Double> {
        (space == .sRGB ? linearSRGB : Self.sRGBToP3 * linearSRGB).map(RGBSpace.encoded)
    }

    /// Whether `space` holds this colour. A little slack absorbs what the display's own
    /// conversion and 8-bit storage add to a colour that was inside the space to begin with: one
    /// 8-bit step, too small to see, which hex would round away anyway.
    public func isInGamut(_ space: RGBSpace) -> Bool {
        let c = components(in: space)
        return c.min() >= -Self.slack && c.max() <= 1 + Self.slack
    }

    static let slack = 1.0 / 255

    // MARK: Conversions

    static let sRGBToP3 = RGBSpace.displayP3.fromXYZ * RGBSpace.sRGB.toXYZ
    static let p3ToSRGB = RGBSpace.sRGB.fromXYZ * RGBSpace.displayP3.toXYZ

    /// CIE XYZ, D65.
    public var xyz: SIMD3<Double> { Self.sRGBToXYZ * linearSRGB }
    static let sRGBToXYZ = RGBSpace.sRGB.toXYZ

    /// Relative luminance, Y of XYZ: what WCAG 2's contrast ratio is made of. For a colour inside
    /// sRGB it is WCAG's own 0.2126 R + 0.7152 G + 0.0722 B on linear components.
    public var luminance: Double { xyz.y }
}

extension SIMD3 where Scalar == Double {
    func map(_ f: (Double) -> Double) -> SIMD3<Double> { SIMD3(f(x), f(y), f(z)) }
}
