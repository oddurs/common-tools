import CoreGraphics
import Foundation
import Testing

@testable import ColorKit

/// Reference values: CSS Color 4's matrices, and ColorSync itself, which is what macOS converts with.
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

    @Test func derivesTheMatricesCSSPublishes() {
        // CSS Color 4, lin_sRGB_to_XYZ, first row: 506752/1228815, 87881/245763, 12673/70218.
        let row = RGBSpace.sRGB.toXYZ.rows[0]
        #expect(close(row, SIMD3(506752 / 1228815, 87881 / 245763, 12673 / 70218), within: 1e-12))
        // lin_P3_to_XYZ, second row: 35783/156275, 247089/357200, 198249/2500400.
        let p3 = RGBSpace.displayP3.toXYZ.rows[1]
        #expect(close(p3, SIMD3(35783 / 156275, 247089 / 357200, 198249 / 2500400), within: 1e-12))
    }

}
