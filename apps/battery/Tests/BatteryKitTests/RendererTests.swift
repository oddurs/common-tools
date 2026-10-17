import AppKit
import Testing

@testable import BatteryKit

struct RendererTests {
    static let states: [BatteryReading] = [
        BatteryReading(level: 1, state: .charged),
        BatteryReading(level: 0.72, state: .discharging, minutesRemaining: 161),
        BatteryReading(level: 0.45, state: .charging, minutesRemaining: 600),
        BatteryReading(level: 0.8, state: .notCharging),
        BatteryReading(level: 0.05, state: .discharging),
        BatteryReading(level: 0, state: .discharging, minutesRemaining: 0),
        BatteryReading(level: 0.5, state: .discharging, isLowPowerMode: true),
    ]

    static let appearances: [BarAppearance] = BarStyle.allCases.flatMap { style in
        [false, true].map { BarAppearance(style: style, showsTime: $0, colorsAlerts: true) }
    }

    @Test(arguments: appearances)
    func widthNeverDependsOnTheReading(_ appearance: BarAppearance) {
        let renderer = BarRenderer(appearance: appearance, height: 24)
        #expect(renderer.size.width > 0)
        for reading in Self.states {
            #expect(renderer.image(reading).size == renderer.size)
        }
    }

    @Test func templateUnlessAnAlertNeedsColour() {
        let renderer = BarRenderer(appearance: .standard, height: 24)
        #expect(renderer.image(BarRendererFixtures.normal).isTemplate)
        #expect(!renderer.image(BarRendererFixtures.low).isTemplate)
        #expect(!renderer.image(BarRendererFixtures.lowPower).isTemplate)
        // Low while charging needs no warning.
        #expect(renderer.image(BatteryReading(level: 0.1, state: .charging)).isTemplate)
        var plain = BarAppearance.standard
        plain.colorsAlerts = false
        #expect(BarRenderer(appearance: plain, height: 24).image(BarRendererFixtures.low).isTemplate)
    }

    @Test func noBatteryStillDraws() {
        let image = BarRenderer(appearance: .standard, height: 24).image(nil)
        #expect(image.isTemplate)
        #expect(image.size.width > 0)
    }

    @Test func imagesActuallyContainInk() throws {
        for appearance in Self.appearances {
            let image = BarRenderer(appearance: appearance, height: 24).image(BarRendererFixtures.normal)
            let tiff = try #require(image.tiffRepresentation)
            let rep = try #require(NSBitmapImageRep(data: tiff))
            var opaque = 0
            for x in 0..<rep.pixelsWide {
                for y in 0..<rep.pixelsHigh where (rep.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.5 { opaque += 1 }
            }
            #expect(opaque > 20, "\(appearance) drew almost nothing")
        }
    }

    @Test func aHiddenItemStillGetsItsFirstImage() {
        // A new item lands hidden behind a menu bar manager; skipping its first draw left it an empty sliver.
        #expect(BarRenderer.mustDraw(hasImage: false, resized: true, visible: false, menuOpen: false))
        #expect(BarRenderer.mustDraw(hasImage: true, resized: true, visible: false, menuOpen: false))
        #expect(!BarRenderer.mustDraw(hasImage: true, resized: false, visible: false, menuOpen: false))
        #expect(BarRenderer.mustDraw(hasImage: true, resized: false, visible: false, menuOpen: true))
        #expect(BarRenderer.mustDraw(hasImage: true, resized: false, visible: true, menuOpen: false))
    }

    @Test func accessibility() {
        #expect(BarRenderer.accessibilityText(BarRendererFixtures.normal) == "Battery 72%, 2:41 remaining")
        #expect(
            BarRenderer.accessibilityText(BarRendererFixtures.lowPower) == "Battery 50%, Calculating…, Low Power Mode")
        #expect(BarRenderer.accessibilityText(nil) == "No battery")
    }
}

enum BarRendererFixtures {
    static let normal = BatteryReading(level: 0.72, state: .discharging, minutesRemaining: 161)
    static let low = BatteryReading(level: 0.12, state: .discharging, minutesRemaining: 18)
    static let lowPower = BatteryReading(level: 0.5, state: .discharging, isLowPowerMode: true)
}
