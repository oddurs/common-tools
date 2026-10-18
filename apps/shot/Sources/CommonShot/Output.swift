import AppKit
import ShotKit
import UniformTypeIdentifiers

enum OutputError: LocalizedError {
    case encoding

    var errorDescription: String? { "The screenshot couldn't be encoded as PNG." }
}

/// What a shot becomes on its way to the clipboard.
enum Output {
    /// Scaled down to `size` with high-quality interpolation; returned as is when it's already that size.
    nonisolated static func resized(_ image: CGImage, to size: ImageSize) throws -> CGImage {
        let fit = size.fit(width: image.width, height: image.height)
        guard fit != (image.width, image.height) else { return image }
        guard
            let context = CGContext(
                data: nil, width: fit.width, height: fit.height, bitsPerComponent: 8, bytesPerRow: 0,
                space: image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { throw OutputError.encoding }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: fit.width, height: fit.height))
        guard let resized = context.makeImage() else { throw OutputError.encoding }
        return resized
    }

    /// PNG, tagged with the display's density the way macOS's own screenshots are, so a 2× shot opens
    /// at the size it had on screen.
    nonisolated static func png(_ image: CGImage, scale: CGFloat) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)
        else { throw OutputError.encoding }
        let dpi = 72 * scale
        let properties = [kCGImagePropertyDPIWidth: dpi, kCGImagePropertyDPIHeight: dpi] as CFDictionary
        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else { throw OutputError.encoding }
        return data as Data
    }

    /// A file for the preview to drag out when the history keeps none. One at a time: each replaces the last.
    nonisolated static func temporaryFile(_ png: Data, at date: Date) throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appending(path: "Common Shot", directoryHint: .isDirectory)
        try? FileManager.default.removeItem(at: folder)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appending(path: FileName.forShot(at: date))
        try png.write(to: url)
        return url
    }

    /// Plain text, for a shot read with ⌥.
    @MainActor static func copy(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// The PNG and the file it was saved to; `Clipboard` says which paste target reads which.
    @MainActor static func copy(_ png: Data, file: URL?) {
        Clipboard.write(png: png, file: file, to: .general)
    }
}
