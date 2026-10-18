import CoreGraphics
import Foundation
import Testing

@testable import ColorKit

/// Reference values: CSS Color 4's worked examples and sample code, Björn Ottosson's published
/// OKLab table, and ColorSync itself, which is what macOS converts with.
@Suite struct ConversionTests {
    func close(_ a: SIMD3<Double>, _ b: SIMD3<Double>, within tolerance: Double = 0.0001) -> Bool {
        (a - b).map(abs).max() <= tolerance
    }

    func srgb(_ hex: UInt32) -> ColorValue {
        ColorValue(
            .sRGB, red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255)
    }

    /// ColorSync's figures (macOS 26). Its Display P3 profile stores the matrix as s15.16 fixed
    /// point adapted to D50, so it differs from the exact matrices by up to 0.0004.
    @Test func displayP3RedIsOutsideSRGB() {
        let red = ColorValue(.displayP3, red: 1, green: 0, blue: 0)
        #expect(close(red.components(in: .sRGB), SIMD3(1.0930909, -0.2268403, -0.1500796), within: 0.0002))
        #expect(!red.isInGamut(.sRGB))
        #expect(red.isInGamut(.displayP3))
    }

    @Test func sRGBRedIsInsideDisplayP3() {
        let red = srgb(0xff0000)
        #expect(close(red.components(in: .displayP3), SIMD3(0.9174699, 0.2003689, 0.1385207), within: 0.0005))
        #expect(red.isInGamut(.sRGB))
    }

    @Test func agreesWithColorSyncBetweenSRGBAndDisplayP3() throws {
        let p3 = try #require(CGColorSpace(name: CGColorSpace.displayP3))
        let extended = try #require(CGColorSpace(name: CGColorSpace.extendedSRGB))
        let steps: [Double] = [0, 0.1, 0.25, 0.5, 0.75, 0.9, 1]
        for r in steps {
            for g in steps {
                for b in steps {
                    let cg = try #require(CGColor(colorSpace: p3, components: [r, g, b, 1]))
                    let converted = try #require(
                        cg.converted(to: extended, intent: .absoluteColorimetric, options: nil)?.components)
                    let ours = ColorValue(.displayP3, red: r, green: g, blue: b).components(in: .sRGB)
                    // ColorSync's quantised profile differs from the exact matrices by up to 0.0004,
                    // a tenth of an 8-bit step.
                    #expect(close(ours, SIMD3(converted[0], converted[1], converted[2]), within: 0.0005))
                }
            }
        }
    }

    @Test func keepsAColourOutsideBothSpaces() {
        let beyond = ColorValue(.sRGB, red: -0.5, green: 1.2, blue: 0.3)
        #expect(close(beyond.components(in: .sRGB), SIMD3(-0.5, 1.2, 0.3), within: 1e-12))
        #expect(!beyond.isInGamut(.sRGB))
        #expect(!beyond.isInGamut(.displayP3))
    }

    @Test func oklchMatchesCSSExamples() {
        // CSS Color 4 sample code; oklch.com gives the same to the places shown.
        let expected: [(UInt32, Double, Double, Double)] = [
            (0xff0000, 0.62796, 0.25768, 29.2339),
            (0x00ff00, 0.86644, 0.29483, 142.4953),
            (0x0000ff, 0.45201, 0.31321, 264.0520),
        ]
        for (hex, l, c, h) in expected {
            let lch = srgb(hex).oklch
            #expect(abs(lch.l - l) < 0.00001, "L of \(String(hex, radix: 16))")
            #expect(abs(lch.c - c) < 0.00001, "C of \(String(hex, radix: 16))")
            #expect(abs(lch.h - h) < 0.001, "h of \(String(hex, radix: 16))")
        }
        let white = srgb(0xffffff).oklch
        #expect(abs(white.l - 1) < 0.0001)
        #expect(white.c < 0.0001)
        #expect(srgb(0x000000).oklch.l == 0)
    }

    @Test func oklabMatchesOttossonsTable() {
        // "A perceptual color space for image processing", the XYZ (D65) to OKLab table.
        let table: [(SIMD3<Double>, SIMD3<Double>)] = [
            (SIMD3(0.950, 1.000, 1.089), SIMD3(1.000, 0.000, 0.000)),
            (SIMD3(1.000, 0.000, 0.000), SIMD3(0.450, 1.236, -0.019)),
            (SIMD3(0.000, 1.000, 0.000), SIMD3(0.922, -0.671, 0.263)),
            (SIMD3(0.000, 0.000, 1.000), SIMD3(0.153, -1.415, -0.449)),
        ]
        for (xyz, expected) in table {
            let lab = ColorValue(linearSRGB: RGBSpace.sRGB.fromXYZ * xyz).oklab
            // Three places, as published; his sRGB matrices are fitted, not derived, so the
            // last place can differ by one.
            #expect(close(SIMD3(lab.l, lab.a, lab.b), expected, within: 0.0015), "\(xyz)")
        }
    }

    @Test func oklabRoundTrips() {
        for color in [srgb(0x3a7bd5), srgb(0x777777), ColorValue(.displayP3, red: 0, green: 1, blue: 0)] {
            // Ottosson publishes his matrices to ten places, so each is the other's inverse to about 1e-7.
            #expect(close(ColorValue(color.oklab).linearSRGB, color.linearSRGB, within: 1e-6))
            #expect(close(ColorValue(OKLab(color.oklch)).linearSRGB, color.linearSRGB, within: 1e-6))
        }
    }

    @Test func derivesTheMatricesCSSPublishes() {
        // CSS Color 4, lin_sRGB_to_XYZ, first row: 506752/1228815, 87881/245763, 12673/70218.
        let row = RGBSpace.sRGB.toXYZ.rows[0]
        #expect(close(row, SIMD3(506752 / 1228815, 87881 / 245763, 12673 / 70218), within: 1e-12))
        // lin_P3_to_XYZ, second row: 35783/156275, 247089/357200, 198249/2500400.
        let p3 = RGBSpace.displayP3.toXYZ.rows[1]
        #expect(close(p3, SIMD3(35783 / 156275, 247089 / 357200, 198249 / 2500400), within: 1e-12))
    }

    @Test func gamutMappingKeepsHueAndLandsInside() {
        for p3 in [SIMD3(0.0, 1, 0), SIMD3(1, 0.5, 0), SIMD3(1, 0, 0), SIMD3(0.2, 0.4, 1)] {
            let color = ColorValue(.displayP3, red: p3.x, green: p3.y, blue: p3.z)
            #expect(!color.isInGamut(.sRGB))
            let mapped = color.mapped(into: .sRGB)
            #expect(mapped.min() >= 0 && mapped.max() <= 1)
            let result = ColorValue(.sRGB, red: mapped.x, green: mapped.y, blue: mapped.z).oklch
            var hueShift = abs(result.h - color.oklch.h)
            hueShift = min(hueShift, 360 - hueShift)
            // Chroma reduction holds hue; the last clip moves it by under a just-noticeable step.
            #expect(hueShift < 3, "hue moved \(hueShift)° for \(p3)")
            #expect(abs(result.l - color.oklch.l) < 0.03, "lightness for \(p3)")
            #expect(result.c < color.oklch.c)
        }
    }

    @Test func aColourInsideIsLeftAlone() {
        let blue = srgb(0x3a7bd5)
        #expect(close(blue.mapped(into: .sRGB), blue.components(in: .sRGB), within: 1e-12))
    }
}
