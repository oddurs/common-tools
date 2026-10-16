/// One pixel: 8-bit channels, straight (not premultiplied) alpha.
public struct Pixel: Equatable, Hashable, Sendable {
    public var r: UInt8
    public var g: UInt8
    public var b: UInt8
    public var a: UInt8

    public init(_ r: UInt8, _ g: UInt8, _ b: UInt8, _ a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    public static let clear = Pixel(0, 0, 0, 0)
    public static let black = Pixel(0, 0, 0)
    public static let white = Pixel(255, 255, 255)

    /// Perceived brightness from 0 (black) to 1 (white), ignoring alpha.
    public var luminance: Double {
        (0.2126 * Double(r) + 0.7152 * Double(g) + 0.0722 * Double(b)) / 255
    }

    /// The largest difference in any colour channel, from 0 to 1. Transparent pixels have no colour,
    /// so two of them always match.
    public func distance(to other: Pixel) -> Double {
        if a < Self.transparent && other.a < Self.transparent { return 0 }
        if (a < Self.transparent) != (other.a < Self.transparent) { return 1 }
        let d = max(abs(Int(r) - Int(other.r)), abs(Int(g) - Int(other.g)), abs(Int(b) - Int(other.b)))
        return Double(d) / 255
    }

    /// Below this alpha a pixel is treated as see-through.
    static let transparent: UInt8 = 16
}

/// An image as plain values, so every edit can be tested without AppKit. Rows run top to bottom.
public struct Bitmap: Equatable, Sendable {
    public let width: Int
    public let height: Int
    /// RGBA, four bytes per pixel, straight alpha.
    public private(set) var pixels: [UInt8]

    public init(width: Int, height: Int, pixels: [UInt8]) {
        precondition(width > 0 && height > 0 && pixels.count == width * height * 4, "pixel buffer does not match size")
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    public init(width: Int, height: Int, fill: Pixel = .clear) {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        if fill != .clear {
            for i in stride(from: 0, to: pixels.count, by: 4) {
                pixels[i] = fill.r
                pixels[i + 1] = fill.g
                pixels[i + 2] = fill.b
                pixels[i + 3] = fill.a
            }
        }
        self.init(width: width, height: height, pixels: pixels)
    }

    public subscript(x: Int, y: Int) -> Pixel {
        get {
            let i = (y * width + x) * 4
            return Pixel(pixels[i], pixels[i + 1], pixels[i + 2], pixels[i + 3])
        }
        set {
            let i = (y * width + x) * 4
            pixels[i] = newValue.r
            pixels[i + 1] = newValue.g
            pixels[i + 2] = newValue.b
            pixels[i + 3] = newValue.a
        }
    }

    /// A new bitmap of the given size whose pixel at (x, y) is `source(x, y)`.
    static func make(width: Int, height: Int, _ source: (Int, Int) -> Pixel) -> Bitmap {
        var out = Bitmap(width: width, height: height)
        for y in 0..<height {
            for x in 0..<width { out[x, y] = source(x, y) }
        }
        return out
    }

    // MARK: Geometry

    /// Turned clockwise a quarter turn at a time.
    public func rotated(quarterTurns: Int) -> Bitmap {
        switch ((quarterTurns % 4) + 4) % 4 {
        case 1: Self.make(width: height, height: width) { x, y in self[y, height - 1 - x] }
        case 2: Self.make(width: width, height: height) { x, y in self[width - 1 - x, height - 1 - y] }
        case 3: Self.make(width: height, height: width) { x, y in self[width - 1 - y, x] }
        default: self
        }
    }

    public func flippedHorizontally() -> Bitmap {
        Self.make(width: width, height: height) { x, y in self[width - 1 - x, y] }
    }

    /// The part inside `rect`, rounded outwards to whole pixels and never empty.
    public func cropped(to rect: CropRect) -> Bitmap {
        let r = rect.clamped()
        // A rect turned or mirrored with the image lands a hair off whole pixels; don't round that out.
        let slack = 1e-6
        let x0 = min(width - 1, Int((r.x * Double(width) + slack).rounded(.down)))
        let y0 = min(height - 1, Int((r.y * Double(height) + slack).rounded(.down)))
        let x1 = max(x0 + 1, min(width, Int(((r.x + r.width) * Double(width) - slack).rounded(.up))))
        let y1 = max(y0 + 1, min(height, Int(((r.y + r.height) * Double(height) - slack).rounded(.up))))
        return cropped(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }

    func cropped(x: Int, y: Int, width w: Int, height h: Int) -> Bitmap {
        if x == 0 && y == 0 && w == width && h == height { return self }
        return Self.make(width: w, height: h) { dx, dy in self[x + dx, y + dy] }
    }

    /// Whether anything would show in the menu bar.
    public var hasVisiblePixels: Bool {
        stride(from: 3, to: pixels.count, by: 4).contains { pixels[$0] >= Pixel.transparent }
    }

    /// Cut down to the smallest box holding every visible pixel, so the glyph fills the menu bar's
    /// height however much empty margin the image had. An image with nothing visible is returned as is.
    public func trimmed() -> Bitmap {
        Self.trimmedTogether([self])[0]
    }

    /// Frames of one animation, all cut to the smallest box holding every visible pixel of any of them.
    /// Trimming each alone would give each its own shape, and the menu bar draws them all at one size.
    public static func trimmedTogether(_ frames: [Bitmap]) -> [Bitmap] {
        guard let first = frames.first else { return [] }
        precondition(
            frames.allSatisfy { $0.width == first.width && $0.height == first.height }, "frames differ in size")
        var minX = first.width, minY = first.height, maxX = -1, maxY = -1
        for frame in frames {
            for y in 0..<frame.height {
                for x in 0..<frame.width where frame.pixels[(y * frame.width + x) * 4 + 3] >= Pixel.transparent {
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                }
            }
        }
        guard maxX >= 0 else { return frames }
        return frames.map { $0.cropped(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1) }
    }

    /// Scaled down, keeping the aspect ratio, until neither side exceeds `maxSide`. Each output pixel
    /// averages the source pixels it covers, weighted by alpha so transparent pixels don't darken edges.
    public func fitting(maxSide: Int) -> Bitmap {
        let longest = max(width, height)
        guard longest > maxSide else { return self }
        let scale = Double(maxSide) / Double(longest)
        let w = max(1, Int((Double(width) * scale).rounded()))
        let h = max(1, Int((Double(height) * scale).rounded()))
        return Self.make(width: w, height: h) { dx, dy in
            let sx0 = dx * width / w, sx1 = max(sx0 + 1, (dx + 1) * width / w)
            let sy0 = dy * height / h, sy1 = max(sy0 + 1, (dy + 1) * height / h)
            var r = 0, g = 0, b = 0, a = 0
            for sy in sy0..<sy1 {
                for sx in sx0..<sx1 {
                    let p = self[sx, sy]
                    let pa = Int(p.a)
                    r += Int(p.r) * pa
                    g += Int(p.g) * pa
                    b += Int(p.b) * pa
                    a += pa
                }
            }
            let count = (sx1 - sx0) * (sy1 - sy0)
            guard a > 0 else { return .clear }
            return Pixel(UInt8(r / a), UInt8(g / a), UInt8(b / a), UInt8(a / count))
        }
    }
}
