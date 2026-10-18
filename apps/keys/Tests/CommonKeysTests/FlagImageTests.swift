import AppKit
import Testing

@testable import CommonKeys

@MainActor
struct FlagImageTests {
    /// The button centres an image, so a flag sits level with the bar's other icons only if its ink
    /// fills the image: no empty rows above or below.
    @Test(arguments: ["🇺🇸", "🇮🇸", "🇷🇺", "🇰🇷", "🇯🇵"])
    func aFlagFillsItsImage(flag: String) throws {
        let image = try #require(StatusMenu.flagImage(flag))
        let bitmap = try #require(
            NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: Int(image.size.width) * 2, pixelsHigh: Int(image.size.height) * 2,
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                bytesPerRow: 0, bitsPerPixel: 0))
        bitmap.size = image.size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        image.draw(in: NSRect(origin: .zero, size: image.size))
        NSGraphicsContext.restoreGraphicsState()

        let inked = (0..<bitmap.pixelsHigh).filter { y in
            (0..<bitmap.pixelsWide).contains { x in (bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.1 }
        }
        let first = try #require(inked.first)
        let last = try #require(inked.last)
        // Within a point (two pixels) of each edge: integral bounds round outward by under one.
        #expect(first <= 2)
        #expect(bitmap.pixelsHigh - 1 - last <= 2)
    }

    /// The lock takes the bar's label colour as it is drawn: dark on a light bar, light on a dark one.
    @Test(arguments: [(NSAppearance.Name.aqua, false), (.darkAqua, true)])
    func theLockFollowsTheBar(appearance: NSAppearance.Name, light: Bool) throws {
        let flag = try #require(StatusMenu.flagImage("🇮🇸"))
        let image = try #require(StatusMenu.lockedFlagImage("🇮🇸"))
        #expect(image.size.width > flag.size.width)
        #expect(image.size.height >= flag.size.height)

        let bitmap = try #require(
            NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: Int(image.size.width), pixelsHigh: Int(image.size.height),
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                bytesPerRow: 0, bitsPerPixel: 0))
        try #require(NSAppearance(named: appearance)).performAsCurrentDrawingAppearance {
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
            image.draw(in: NSRect(origin: .zero, size: image.size))
            NSGraphicsContext.restoreGraphicsState()
        }
        // The lock's column: right of the flag and the gap.
        let lock = (Int(flag.size.width) + 2..<bitmap.pixelsWide).flatMap { x in
            (0..<bitmap.pixelsHigh).compactMap { y in bitmap.colorAt(x: x, y: y) }
        }.filter { $0.alphaComponent > 0.5 }
        #expect(!lock.isEmpty)
        #expect(lock.allSatisfy { ($0.brightnessComponent > 0.5) == light })
    }
}
