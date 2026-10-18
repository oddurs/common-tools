import AppKit
import Testing

@testable import ColorKit

@Suite struct AppKitBridgeTests {
    /// What the sampler hands back is a colour in the display's space; a Display P3 one stands in.
    @Test func readsADisplayColourWithoutClipping() throws {
        let green = NSColor(colorSpace: .displayP3, components: [0, 1, 0, 1], count: 4)
        let value = try #require(ColorValue(green))
        #expect(ColorFormat.displayP3.string(value) == "color(display-p3 0 1 0)")
        #expect(!value.isInGamut(.sRGB))
    }

    @Test func readsAnSRGBColour() throws {
        let value = try #require(ColorValue(NSColor(srgbRed: 0.2275, green: 0.4824, blue: 0.8353, alpha: 1)))
        #expect(ColorFormat.hex.string(value) == "#3a7bd5")
    }

    @Test func drawsASwatchAsTheColourItself() throws {
        let green = ColorValue(.displayP3, red: 0, green: 1, blue: 0)
        let p3 = try #require(CGColorSpace(name: CGColorSpace.displayP3))
        let back = try #require(
            green.cgColor.converted(to: p3, intent: .absoluteColorimetric, options: nil)?.components)
        #expect(abs(back[0]) < 0.001 && abs(back[1] - 1) < 0.001 && abs(back[2]) < 0.001)
    }
}

extension AppKitBridgeTests {
    @Test func keepsAColourBeyondDisplayP3() throws {
        let beyond = NSColor(colorSpace: .extendedSRGB, components: [-0.6, 1.1, -0.4, 1], count: 4)
        let value = try #require(ColorValue(beyond))
        #expect(!value.isInGamut(.displayP3))
        #expect(abs(value.components(in: .sRGB).x + 0.6) < 0.0001)
    }
}
