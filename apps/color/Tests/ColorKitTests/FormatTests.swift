import AppKit
import Foundation
import SwiftUI
import Testing

@testable import ColorKit

@Suite struct FormatTests {
    let blue = ColorValue(.sRGB, red: 58 / 255, green: 123 / 255, blue: 213 / 255)  // #3a7bd5
    let p3Green = ColorValue(.displayP3, red: 0, green: 1, blue: 0)

    func strings(_ color: ColorValue) -> [ColorFormat: String] {
        Dictionary(uniqueKeysWithValues: ColorFormat.allCases.map { ($0, $0.string(color)) })
    }

    @Test func writesAnSRGBColourInEveryFormat() {
        #expect(
            strings(blue) == [
                .hex: "#3a7bd5",
                .rgb: "rgb(58 123 213)",
                .hsl: "hsl(214.8 64.9% 53.1%)",
                .oklch: "oklch(58.62% 0.1533 257.23)",
                .displayP3: "color(display-p3 0.2933 0.4765 0.81)",
                .swiftUI: "Color(.sRGB, red: 0.2275, green: 0.4824, blue: 0.8353)",
                .appKit: "NSColor(srgbRed: 0.2275, green: 0.4824, blue: 0.8353, alpha: 1)",
            ])
        #expect(ColorFormat.allCases.allSatisfy { $0.isExact(blue) })
    }

    @Test func writesADisplayP3ColourWithoutClippingWhereTheFormatCanHoldIt() {
        let text = strings(p3Green)
        #expect(text[.displayP3] == "color(display-p3 0 1 0)")
        #expect(text[.swiftUI] == "Color(.displayP3, red: 0, green: 1, blue: 0)")
        #expect(text[.appKit] == "NSColor(displayP3Red: 0, green: 1, blue: 0, alpha: 1)")
        #expect(text[.oklch]?.hasPrefix("oklch(84.") == true)
        // The sRGB formats get the nearest sRGB colour, and say they did.
        for format in [ColorFormat.hex, .rgb, .hsl] {
            #expect(!format.isExact(p3Green), "\(format)")
        }
        for format in [ColorFormat.oklch, .displayP3, .swiftUI, .appKit] {
            #expect(format.isExact(p3Green), "\(format)")
        }
    }

    @Test func hslMatchesNamedColours() {
        #expect(ColorFormat.hsl.string(ColorValue(.sRGB, red: 1, green: 0, blue: 0)) == "hsl(0 100% 50%)")
        // rebeccapurple, #663399, is hsl(270 50% 40%) in CSS Color 4.
        let purple = ColorValue(.sRGB, red: 0x66 / 255, green: 0x33 / 255, blue: 0x99 / 255)
        #expect(ColorFormat.hsl.string(purple) == "hsl(270 50% 40%)")
        #expect(ColorFormat.hsl.string(ColorValue(.sRGB, red: 0.5, green: 0.5, blue: 0.5)) == "hsl(0 0% 50%)")
    }

    @Test func aGreyHasNoHueInOKLCH() {
        #expect(ColorFormat.oklch.string(ColorValue(.sRGB, red: 1, green: 1, blue: 1)) == "oklch(100% 0 none)")
        #expect(ColorFormat.oklch.string(ColorValue(.sRGB, red: 0, green: 0, blue: 0)) == "oklch(0% 0 none)")
    }

    @Test func numbersUseAPointAndNeverReadMinusZero() {
        #expect(ColorFormat.number(-0.00001, 4) == "0")
        #expect(ColorFormat.number(0.5, 4) == "0.5")
        #expect(ColorFormat.number(1, 4) == "1")
        #expect(ColorFormat.number(12.3456, 2) == "12.35")
    }

    /// CSS Color 4's grammar for each function, as each format writes it: space-separated
    /// numbers, percentages where CSS requires them, and `none` for a missing hue.
    @Test func everyCSSFormatFollowsTheGrammar() throws {
        let number = #"-?\d+(\.\d+)?"#
        let grammar: [ColorFormat: String] = [
            .hex: "^#[0-9a-f]{6}$",
            .rgb: #"^rgb\((\d{1,3}) (\d{1,3}) (\d{1,3})\)$"#,
            .hsl: "^hsl\\(\(number) \(number)% \(number)%\\)$",
            .oklch: "^oklch\\(\(number)% \(number) (\(number)|none)\\)$",
            .displayP3: "^color\\(display-p3 \(number) \(number) \(number)\\)$",
        ]
        let samples = [
            blue, p3Green, ColorValue(.sRGB, red: 1, green: 1, blue: 1), ColorValue(.sRGB, red: 0, green: 0, blue: 0),
        ]
        for color in samples {
            for (format, pattern) in grammar {
                let text = format.string(color)
                #expect(text.range(of: pattern, options: .regularExpression) != nil, "\(text)")
            }
            for value in ColorFormat.rgb.string(color).dropFirst(4).dropLast().split(separator: " ") {
                #expect((0...255).contains(try #require(Int(value))))
            }
        }
    }

    /// What the Swift formats write, pasted here as code: if the formats drift from what compiles,
    /// the expectations above fail, and if these lines stop compiling, the suite doesn't build.
    @Test func theSwiftFormatsCompile() {
        let pasted: [Any] = [
            Color(.sRGB, red: 0.2275, green: 0.4824, blue: 0.8353),
            Color(.displayP3, red: 0, green: 1, blue: 0),
            NSColor(srgbRed: 0.2275, green: 0.4824, blue: 0.8353, alpha: 1),
            NSColor(displayP3Red: 0, green: 1, blue: 0, alpha: 1),
        ]
        #expect(pasted.count == 4)
        let ns = NSColor(srgbRed: 0.2275, green: 0.4824, blue: 0.8353, alpha: 1)
        #expect(abs(ns.redComponent - 0.2275) < 1e-6)
    }
}
