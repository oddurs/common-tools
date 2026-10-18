import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// What a captured image becomes on its way to the clipboard: sized, in sRGB, and encoded as PNG.
public enum PNG {
    public enum Failure: LocalizedError {
        case encoding

        public var errorDescription: String? { "The screenshot couldn't be encoded as PNG." }
    }

    /// `image` scaled down to `size`, with high-quality interpolation, and in sRGB. A capture comes in
    /// the display's own colour space; a prompt, and most of the web, reads a PNG's numbers as sRGB and
    /// ignores its profile, so anything else would paste with shifted colours. Returned as it is when it
    /// is already both.
    public static func prepared(_ image: CGImage, size: ImageSize) throws -> CGImage {
        let fit = size.fit(width: image.width, height: image.height)
        let srgb = CGColorSpace(name: CGColorSpace.sRGB)!
        if fit == (image.width, image.height), image.colorSpace?.name == CGColorSpace.sRGB { return image }
        guard
            let context = CGContext(
                data: nil, width: fit.width, height: fit.height, bitsPerComponent: 8, bytesPerRow: 0, space: srgb,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { throw Failure.encoding }
        context.interpolationQuality = .high
        // Drawing converts from the image's colour space to the context's.
        context.draw(image, in: CGRect(x: 0, y: 0, width: fit.width, height: fit.height))
        guard let prepared = context.makeImage() else { throw Failure.encoding }
        return prepared
    }

    /// PNG, tagged with the display's density the way macOS's own screenshots are, so a 2× shot opens at
    /// the size it had on screen.
    public static func data(_ image: CGImage, scale: CGFloat) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)
        else { throw Failure.encoding }
        let dpi = 72 * scale
        let properties = [kCGImagePropertyDPIWidth: dpi, kCGImagePropertyDPIHeight: dpi] as CFDictionary
        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else { throw Failure.encoding }
        return data as Data
    }
}
