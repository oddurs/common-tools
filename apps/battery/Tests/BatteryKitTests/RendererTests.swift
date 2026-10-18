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

    /// Every arrangement of every non-empty set of parts, with each look of the icon.
    static let appearances: [BarAppearance] = {
        func orders(_ parts: [BarPart]) -> [[BarPart]] {
            parts.isEmpty ? [[]] : parts.flatMap { p in orders(parts.filter { $0 != p }).map { [p] + $0 } }
        }
        let sets = (1..<8).map { mask in
            BarPart.allCases.enumerated().filter { mask & (1 << $0.offset) != 0 }.map(\.element)
        }
        return sets.flatMap(orders).flatMap { parts in
            IconStyle.allCases.map { BarAppearance(parts: parts, iconStyle: $0) }
        }
    }()

    @Test(arguments: appearances)
    func widthNeverDependsOnTheReading(_ appearance: BarAppearance) {
        let renderer = BarRenderer(appearance: appearance, height: 24)
        #expect(renderer.size.width > 0)
        for reading in Self.states {
            #expect(renderer.image(reading).size == renderer.size)
        }
    }

    /// With only the percentage showing, the number sat against the right edge of a slot measured
    /// for "100%", eight points from the left and one from the right. Whatever is drawn, the slack
    /// falls evenly on both sides.
    @Test(arguments: appearances)
    func contentIsCentredInTheItem(_ appearance: BarAppearance) throws {
        let renderer = BarRenderer(appearance: appearance, height: 24)
        for reading in Self.states {
            let ink = try #require(Self.inkColumns(renderer.image(reading)), "\(appearance) drew nothing")
            let left = ink.lowerBound, right = renderer.size.width - ink.upperBound
            #expect(
                abs(left - right) <= 1,
                "\(appearance.parts) at \(reading.percent)% \(reading.state): \(left) left, \(right) right")
        }
    }

    @Test func timeAloneShowsAPlugWhenThereIsNoTime() throws {
        let charged = BatteryReading(level: 1, state: .charged)
        let timeOnly = BarRenderer(appearance: BarAppearance(parts: [.time]), height: 24)
        #expect(Self.inkColumns(timeOnly.image(charged)) != nil)
        // Beside the icon, which shows the plug itself, the time leaves no blank: the icon alone is centred.
        let both = BarRenderer(appearance: BarAppearance(parts: [.time, .battery]), height: 24)
        let ink = try #require(Self.inkColumns(both.image(charged)))
        #expect(abs((ink.upperBound - ink.lowerBound) - BarRenderer.iconWidth(.plain)) <= 1)
    }

    /// The span of columns, in points, holding anything more than faint ink, drawn at 2x.
    static func inkColumns(_ image: NSImage) -> ClosedRange<CGFloat>? {
        let scale = 2
        let w = Int(image.size.width) * scale, h = Int(image.size.height) * scale
        guard
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4,
                hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: w * 4, bitsPerPixel: 32),
            let data = rep.bitmapData
        else { return nil }
        rep.size = image.size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        NSGraphicsContext.restoreGraphicsState()
        let inked = (0..<w).filter { x in (0..<h).contains { y in data[y * w * 4 + x * 4 + 3] > 64 } }
        guard let first = inked.first, let last = inked.last else { return nil }
        return CGFloat(first) / CGFloat(scale)...CGFloat(last + 1) / CGFloat(scale)
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
