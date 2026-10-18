import Foundation

/// A 3×3 matrix, row-major, for the linear maps between colour spaces.
struct Matrix3: Equatable, Sendable {
    var rows: [SIMD3<Double>]

    init(_ rows: [SIMD3<Double>]) { self.rows = rows }

    static func * (m: Matrix3, v: SIMD3<Double>) -> SIMD3<Double> {
        SIMD3((m.rows[0] * v).sum(), (m.rows[1] * v).sum(), (m.rows[2] * v).sum())
    }

    static func * (a: Matrix3, b: Matrix3) -> Matrix3 {
        let columns = b.transposed.rows
        return Matrix3(a.rows.map { row in SIMD3(columns.map { (row * $0).sum() }) })
    }

    var transposed: Matrix3 {
        Matrix3((0..<3).map { i in SIMD3(rows[0][i], rows[1][i], rows[2][i]) })
    }

    var inverse: Matrix3 {
        let (a, b, c) = (rows[0], rows[1], rows[2])
        let x = cross(b, c), y = cross(c, a), z = cross(a, b)
        let determinant = (a * x).sum()
        // The rows of the inverse are the columns of [x y z] / det.
        return Matrix3([x, y, z]).transposed * (1 / determinant)
    }

    static func * (m: Matrix3, k: Double) -> Matrix3 { Matrix3(m.rows.map { $0 * k }) }

    private func cross(_ u: SIMD3<Double>, _ v: SIMD3<Double>) -> SIMD3<Double> {
        SIMD3(u.y * v.z - u.z * v.y, u.z * v.x - u.x * v.z, u.x * v.y - u.y * v.x)
    }
}

/// An RGB colour space that CSS and Apple both name: its primaries, its white, and its transfer
/// function. sRGB and Display P3 share D65 and the sRGB curve, and differ only in primaries.
public enum RGBSpace: String, CaseIterable, Codable, Sendable {
    case sRGB
    case displayP3

    /// CIE 1931 xy chromaticities of red, green, and blue, from IEC 61966-2-1 (sRGB) and SMPTE
    /// EG 432-1 with a D65 white (Display P3).
    var primaries: [SIMD2<Double>] {
        switch self {
        case .sRGB: [SIMD2(0.640, 0.330), SIMD2(0.300, 0.600), SIMD2(0.150, 0.060)]
        case .displayP3: [SIMD2(0.680, 0.320), SIMD2(0.265, 0.690), SIMD2(0.150, 0.060)]
        }
    }

    /// D65, as CSS Color 4 writes it, so the matrices agree with every browser's.
    static let white = SIMD2(0.3127, 0.3290)

    /// Linear RGB to CIE XYZ, built from the primaries and white the standard way: each primary's
    /// XYZ at Y = 1, scaled so that RGB (1, 1, 1) lands on the white point.
    var toXYZ: Matrix3 {
        func xyz(_ p: SIMD2<Double>) -> SIMD3<Double> { SIMD3(p.x / p.y, 1, (1 - p.x - p.y) / p.y) }
        let columns = Matrix3(primaries.map(xyz)).transposed
        let scale = columns.inverse * xyz(Self.white)
        return Matrix3(columns.rows.map { $0 * scale })
    }

    var fromXYZ: Matrix3 { toXYZ.inverse }

    /// The sRGB curve, which Display P3 shares, extended to negative values by symmetry as CSS
    /// Color 4 does, so a colour outside the space survives the round trip.
    static func linear(_ encoded: Double) -> Double {
        let magnitude = abs(encoded)
        let value = magnitude <= 0.04045 ? magnitude / 12.92 : pow((magnitude + 0.055) / 1.055, 2.4)
        return encoded < 0 ? -value : value
    }

    static func encoded(_ linear: Double) -> Double {
        let magnitude = abs(linear)
        let value = magnitude <= 0.0031308 ? magnitude * 12.92 : 1.055 * pow(magnitude, 1 / 2.4) - 0.055
        return linear < 0 ? -value : value
    }
}
