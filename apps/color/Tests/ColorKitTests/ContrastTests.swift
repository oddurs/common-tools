import Foundation
import Testing

@testable import ColorKit

@Suite struct ContrastTests {
    func srgb(_ hex: UInt32) -> ColorValue {
        ColorValue(
            .sRGB, red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255)
    }

    /// Ratios as WebAIM's contrast checker and the WCAG 2 understanding documents give them.
    @Test func matchesPublishedRatios() {
        let pairs: [(UInt32, UInt32, Double)] = [
            (0x000000, 0xffffff, 21),
            (0x777777, 0xffffff, 4.48),
            (0x767676, 0xffffff, 4.54),
            (0x0000ff, 0xffffff, 8.59),
            (0xff0000, 0xffffff, 4.0),
            (0xffffff, 0xffffff, 1),
        ]
        for (a, b, expected) in pairs {
            let ratio = Contrast(srgb(a), srgb(b)).ratio
            #expect(abs(ratio - expected) < 0.005, "\(String(a, radix: 16)) on \(String(b, radix: 16)): \(ratio)")
        }
    }

    @Test func orderDoesNotMatter() {
        #expect(Contrast(srgb(0x3a7bd5), srgb(0x111111)) == Contrast(srgb(0x111111), srgb(0x3a7bd5)))
    }

    @Test func greyOnWhiteJustFailsAANormal() {
        let contrast = Contrast(srgb(0x777777), srgb(0xffffff))
        #expect(!contrast.passes(.aa, .normal))
        #expect(contrast.passes(.aa, .large))
        #expect(!contrast.passes(.aaa, .large))
        #expect(contrast.text == "4.47:1")
        #expect(Contrast(srgb(0x767676), srgb(0xffffff)).passes(.aa, .normal))
    }

    @Test func blackOnWhitePassesEverything() {
        let contrast = Contrast(srgb(0x000000), srgb(0xffffff))
        for level in Contrast.Level.allCases {
            for size in Contrast.TextSize.allCases { #expect(contrast.passes(level, size)) }
        }
        #expect(contrast.text == "21:1")
    }
}
