import CommonTesting
import CoreGraphics
import Foundation
import ImageIO
import Testing

@testable import ShotKit

@Suite struct PNGTests {
    /// A `width` × `height` picture in `space`: a gradient with a hard-edged block, like a screen.
    static func picture(width: Int, height: Int, space: CGColorSpace) -> CGImage {
        let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: space,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let gradient = CGGradient(
            colorsSpace: space,
            colors: [
                CGColor(colorSpace: space, components: [0.9, 0.2, 0.1, 1])!,
                CGColor(colorSpace: space, components: [0.1, 0.4, 0.9, 1])!,
            ] as CFArray, locations: nil)!
        context.drawLinearGradient(
            gradient, start: .zero, end: CGPoint(x: width, y: height), options: [])
        context.setFillColor(CGColor(colorSpace: space, components: [0.95, 0.95, 0.95, 1])!)
        context.fill(CGRect(x: width / 4, y: height / 4, width: width / 2, height: height / 3))
        return context.makeImage()!
    }

    let p3 = CGColorSpace(name: CGColorSpace.displayP3)!
    let srgb = CGColorSpace(name: CGColorSpace.sRGB)!

    @Test func aDisplayP3CaptureBecomesSRGB() throws {
        let image = try PNG.prepared(Self.picture(width: 200, height: 100, space: p3), size: .full)
        #expect(image.colorSpace?.name == CGColorSpace.sRGB)
        #expect(image.width == 200 && image.height == 100)
    }

    @Test func theColoursAreConvertedNotRelabelled() throws {
        // P3's (0.9, 0.2, 0.1) is redder than sRGB can show, so converted it comes out at sRGB's limit.
        let image = try PNG.prepared(Self.picture(width: 2, height: 2, space: p3), size: .full)
        let relabelled = Self.picture(width: 2, height: 2, space: srgb)
        #expect(pixel(image) != pixel(relabelled))
    }

    @Test func anSRGBImageAtItsSizeIsLeftAlone() throws {
        let image = Self.picture(width: 300, height: 200, space: srgb)
        #expect(try PNG.prepared(image, size: .prompt) === image)
    }

    @Test func aLargeShotIsScaledToFitAPrompt() throws {
        let image = try PNG.prepared(Self.picture(width: 3024, height: 1964, space: srgb), size: .prompt)
        #expect(image.width == 1568 && image.height == 1018)
    }

    @Test func thePNGIsSRGBAndCarriesTheDensity() throws {
        let image = try PNG.prepared(Self.picture(width: 400, height: 300, space: p3), size: .prompt)
        let data = try PNG.data(image, scale: 2)
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        #expect(properties[kCGImagePropertyDPIWidth] as? Double == 144)
        let decoded = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        #expect(decoded.colorSpace?.name == CGColorSpace.sRGB)
    }

    private func pixel(_ image: CGImage) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: 4)
        let context = CGContext(
            data: &bytes, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: srgb,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return bytes
    }
}

/// Regression gates, not benchmarks: budgets about ten times a quiet M-series measurement.
@Suite(.serialized) struct PNGPerformanceTests {
    @Test func aFullRetinaScreenIsReadyForAPromptQuickly() throws {
        let screen = PNGTests.picture(width: 3456, height: 2234, space: CGColorSpace(name: CGColorSpace.displayP3)!)
        let microseconds = Benchmark.microseconds(iterations: 1, batches: 3) {
            _ = try? PNG.data(PNG.prepared(screen, size: .prompt), scale: 2)
        }
        print("prompt-sized PNG of a full Retina screen: \(Int(microseconds / 1000)) ms")
        #expect(microseconds < 500_000)
    }
}
