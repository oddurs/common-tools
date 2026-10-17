import AppKit
import CoreText
import GlyphKit
import ImageIO
import UniformTypeIdentifiers
import Vision

/// One frame of a source image, decoded to plain pixels.
struct Frame: Sendable {
    var bitmap: Bitmap
    /// Seconds before the next frame; ignored for a still image.
    var delay: Double
}

enum ImagingError: LocalizedError {
    case unreadable(String)
    case noSubject
    case nothingToPaste

    var errorDescription: String? {
        switch self {
        case .unreadable(let name): "“\(name)” isn't an image Common Glyph can read."
        case .noSubject: "Couldn't find a subject to lift. Try Remove solid colour instead."
        case .nothingToPaste: "There's no image on the clipboard."
        }
    }
}

/// Translates between Core Graphics and GlyphKit's `Bitmap`, and decodes sources into frames.
/// Everything here is safe to call off the main thread.
enum Imaging {
    /// Large enough to crop a face out of a full-body drawing; the menu bar never shows more than 48
    /// pixels of height on a Retina display.
    static let workingSide = 1024
    /// Animations are decoded smaller, so a long GIF can't take gigabytes.
    static let animationPixelBudget = 16_000_000
    static let maximumFrames = 300

    private static let srgb = CGColorSpace(name: CGColorSpace.sRGB)!

    static func bitmap(from image: CGImage) -> Bitmap? {
        let w = image.width, h = image.height
        guard w > 0, h > 0 else { return nil }
        var data = [UInt8](repeating: 0, count: w * h * 4)
        let drawn = data.withUnsafeMutableBytes { buffer -> Bool in
            guard
                let ctx = CGContext(
                    data: buffer.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                    space: srgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return false }
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard drawn else { return nil }
        // Contexts only draw premultiplied; Bitmap holds straight alpha.
        for i in stride(from: 0, to: data.count, by: 4) {
            let a = Int(data[i + 3])
            guard a > 0 && a < 255 else { continue }
            for c in 0..<3 { data[i + c] = UInt8(min(255, (Int(data[i + c]) * 255 + a / 2) / a)) }
        }
        return Bitmap(width: w, height: h, pixels: data)
    }

    static func cgImage(from bitmap: Bitmap) -> CGImage? {
        guard let provider = CGDataProvider(data: Data(bitmap.pixels) as CFData) else { return nil }
        return CGImage(
            width: bitmap.width, height: bitmap.height, bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: bitmap.width * 4, space: srgb,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: provider, decode: nil,
            shouldInterpolate: true, intent: .defaultIntent)
    }

    /// An image `size` points across that draws `bitmap` smoothly at whatever scale the screen uses.
    @MainActor static func image(from bitmap: Bitmap, size: NSSize, template: Bool) -> NSImage? {
        guard let cg = cgImage(from: bitmap) else { return nil }
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.interpolationQuality = .high
            ctx.draw(cg, in: rect)
            return true
        }
        image.isTemplate = template
        return image
    }

    // MARK: Decoding

    static func frames(of url: URL) throws -> [Frame] {
        let unreadable = ImagingError.unreadable(url.lastPathComponent)
        // Vector images are drawn by NSImage at the working size. ImageIO would rasterise a PDF at its page
        // size, often far smaller, and can't read SVG at all.
        let vector = UTType(filenameExtension: url.pathExtension).map { $0.conforms(to: .pdf) || $0.conforms(to: .svg) }
        guard vector != true, let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            CGImageSourceGetCount(source) > 0
        else {
            guard let image = NSImage(contentsOf: url) else { throw unreadable }
            return [try still(image, name: url.lastPathComponent)]
        }
        let count = min(CGImageSourceGetCount(source), maximumFrames)
        let side =
            count == 1
            ? workingSide : min(workingSide / 2, Int((Double(animationPixelBudget) / Double(count)).squareRoot()))
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: side,
        ]
        let frames = (0..<count).compactMap { i -> Frame? in
            guard let image = CGImageSourceCreateThumbnailAtIndex(source, i, options as CFDictionary),
                let bitmap = bitmap(from: image)
            else { return nil }
            return Frame(bitmap: bitmap, delay: delay(of: source, at: i))
        }
        guard !frames.isEmpty else { throw unreadable }
        return frames
    }

    private static func still(_ image: NSImage, name: String) throws -> Frame {
        let size = image.size
        let scale = Double(workingSide) / max(size.width, size.height, 1)
        var rect = CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale)
        guard let cg = image.cgImage(forProposedRect: &rect, context: nil, hints: nil), let bitmap = bitmap(from: cg)
        else { throw ImagingError.unreadable(name) }
        return Frame(bitmap: bitmap, delay: 0)
    }

    private static func delay(of source: CGImageSource, at index: Int) -> Double {
        let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any] ?? [:]
        // GIF, APNG, and WebP each keep their timing under their own keys.
        let formats: [(CFString, CFString, CFString)] = [
            (kCGImagePropertyGIFDictionary, kCGImagePropertyGIFUnclampedDelayTime, kCGImagePropertyGIFDelayTime),
            (kCGImagePropertyPNGDictionary, kCGImagePropertyAPNGUnclampedDelayTime, kCGImagePropertyAPNGDelayTime),
            (kCGImagePropertyWebPDictionary, kCGImagePropertyWebPUnclampedDelayTime, kCGImagePropertyWebPDelayTime),
        ]
        for (dictionary, unclamped, clamped) in formats {
            guard let info = properties[dictionary] as? [CFString: Any] else { continue }
            return FrameTiming.delay(unclamped: info[unclamped] as? Double, clamped: info[clamped] as? Double)
        }
        return FrameTiming.delay(unclamped: nil, clamped: nil)
    }

    /// Text drawn in the system font, large, so cropping and trimming keep it sharp. Emoji come out in
    /// colour, everything else in black for the style to recolour.
    static func frames(ofText text: String) -> [Frame] {
        let line = text.replacingOccurrences(of: "\n", with: " ")
        guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let font = CTFontCreateUIFontForLanguage(.system, 180, nil)!
        let string = NSAttributedString(
            string: line,
            attributes: [
                NSAttributedString.Key(kCTFontAttributeName as String): font,
                NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor.black,
            ])
        let ctLine = CTLineCreateWithAttributedString(string)
        var ascent: CGFloat = 0, descent: CGFloat = 0
        let advance = CTLineGetTypographicBounds(ctLine, &ascent, &descent, nil)
        // Generous margins: glyphs such as italics and emoji can reach past their typographic box.
        let pad: CGFloat = 40
        let w = Int((advance + pad * 2).rounded(.up)), h = Int((ascent + descent + pad * 2).rounded(.up))
        var data = [UInt8](repeating: 0, count: w * h * 4)
        let drawn = data.withUnsafeMutableBytes { buffer -> CGImage? in
            guard
                let ctx = CGContext(
                    data: buffer.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                    space: srgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return nil }
            ctx.textPosition = CGPoint(x: pad, y: pad + descent)
            CTLineDraw(ctLine, ctx)
            return ctx.makeImage()
        }
        guard let drawn, let bitmap = bitmap(from: drawn) else { return [] }
        return [Frame(bitmap: bitmap.trimmed().fitting(maxSide: workingSide), delay: 0)]
    }

    // MARK: Subject

    /// The image with everything but its subject made transparent, as Photos' "Copy Subject" does.
    static func liftingSubject(_ bitmap: Bitmap) throws -> Bitmap {
        guard let cg = cgImage(from: bitmap) else { throw ImagingError.noSubject }
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cg)
        try handler.perform([request])
        guard let observation = request.results?.first, !observation.allInstances.isEmpty else {
            throw ImagingError.noSubject
        }
        let mask = try observation.generateScaledMaskForImage(forInstances: observation.allInstances, from: handler)
        CVPixelBufferLockBaseAddress(mask, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(mask),
            CVPixelBufferGetWidth(mask) == bitmap.width, CVPixelBufferGetHeight(mask) == bitmap.height
        else { throw ImagingError.noSubject }
        // One 32-bit float per pixel, from 0 (background) to 1 (subject).
        let rowBytes = CVPixelBufferGetBytesPerRow(mask)
        var out = bitmap
        for y in 0..<bitmap.height {
            let row = (base + y * rowBytes).assumingMemoryBound(to: Float32.self)
            for x in 0..<bitmap.width {
                var p = out[x, y]
                p.a = UInt8(Float32(p.a) * min(max(row[x], 0), 1))
                out[x, y] = p
            }
        }
        return out
    }
}
