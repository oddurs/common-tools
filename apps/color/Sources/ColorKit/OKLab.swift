import Foundation

/// OKLab and its polar form OKLCH, as Björn Ottosson defined them ("A perceptual color space for
/// image processing", 2020), with his published matrices for linear sRGB, which CSS Color 4's
/// `oklch()` uses.
public struct OKLab: Equatable, Sendable {
    public var l: Double
    public var a: Double
    public var b: Double

    public init(l: Double, a: Double, b: Double) {
        (self.l, self.a, self.b) = (l, a, b)
    }

    /// Lightness 0–1, chroma (0 for a grey; about 0.4 at most), and hue in degrees, 0–360.
    public struct LCH: Equatable, Sendable {
        public var l: Double
        public var c: Double
        public var h: Double

        public init(l: Double, c: Double, h: Double) {
            (self.l, self.c, self.h) = (l, c, h)
        }
    }

    public var lch: LCH {
        let hue = atan2(b, a) * 180 / .pi
        return LCH(l: l, c: (a * a + b * b).squareRoot(), h: hue < 0 ? hue + 360 : hue)
    }

    public init(_ lch: LCH) {
        let radians = lch.h * .pi / 180
        self.init(l: lch.l, a: lch.c * cos(radians), b: lch.c * sin(radians))
    }

    /// The distance CSS Color 4 measures gamut mapping by: Euclidean, in OKLab.
    public func distance(to other: OKLab) -> Double {
        let (dl, da, db) = (l - other.l, a - other.a, b - other.b)
        return (dl * dl + da * da + db * db).squareRoot()
    }

    // Ottosson's M1 (linear sRGB to cone response) and M2 (cube-rooted cones to Lab), and inverses.
    static let m1 = Matrix3([
        SIMD3(0.4122214708, 0.5363325363, 0.0514459929),
        SIMD3(0.2119034982, 0.6806995451, 0.1073969566),
        SIMD3(0.0883024619, 0.2817188376, 0.6299787005),
    ])
    static let m2 = Matrix3([
        SIMD3(0.2104542553, 0.7936177850, -0.0040720468),
        SIMD3(1.9779984951, -2.4285922050, 0.4505937099),
        SIMD3(0.0259040371, 0.7827717662, -0.8086757660),
    ])
    static let m2Inverse = Matrix3([
        SIMD3(1, 0.3963377774, 0.2158037573),
        SIMD3(1, -0.1055613458, -0.0638541728),
        SIMD3(1, -0.0894841775, -1.2914855480),
    ])
    static let m1Inverse = Matrix3([
        SIMD3(4.0767416621, -3.3077115913, 0.2309699292),
        SIMD3(-1.2684380046, 2.6097574011, -0.3413193965),
        SIMD3(-0.0041960863, -0.7034186147, 1.7076147010),
    ])
}

extension ColorValue {
    public var oklab: OKLab {
        let lab = OKLab.m2 * (OKLab.m1 * linearSRGB).map(cbrt)
        return OKLab(l: lab.x, a: lab.y, b: lab.z)
    }

    public var oklch: OKLab.LCH { oklab.lch }

    public init(_ lab: OKLab) {
        let cones = (OKLab.m2Inverse * SIMD3(lab.l, lab.a, lab.b)).map { $0 * $0 * $0 }
        self.init(linearSRGB: OKLab.m1Inverse * cones)
    }
}
