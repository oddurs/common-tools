/// A rectangle in fractions of an image's width and height, with the origin at the top left.
public struct CropRect: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public static let full = CropRect(x: 0, y: 0, width: 1, height: 1)
    /// Small enough to pick out a face from a full-body drawing, large enough to grab with a pointer.
    public static let minimumSide = 0.04

    public var isFull: Bool { self == .full }

    /// Inside the image, and no smaller than `minimumSide` either way.
    public func clamped() -> CropRect {
        let w = min(max(width, Self.minimumSide), 1)
        let h = min(max(height, Self.minimumSide), 1)
        return CropRect(x: min(max(x, 0), 1 - w), y: min(max(y, 0), 1 - h), width: w, height: h)
    }

    /// Slid by the given fractions, stopping at the image's edges without changing size.
    public func moved(dx: Double, dy: Double) -> CropRect {
        CropRect(x: x + dx, y: y + dy, width: width, height: height).clamped()
    }

    public enum Corner: CaseIterable, Sendable {
        case topLeading, topTrailing, bottomLeading, bottomTrailing
    }

    /// One corner dragged by the given fractions while the opposite corner stays put.
    public func resized(_ corner: Corner, dx: Double, dy: Double) -> CropRect {
        var left = x, top = y, right = x + width, bottom = y + height
        switch corner {
        case .topLeading:
            left = min(max(left + dx, 0), right - Self.minimumSide)
            top = min(max(top + dy, 0), bottom - Self.minimumSide)
        case .topTrailing:
            right = max(min(right + dx, 1), left + Self.minimumSide)
            top = min(max(top + dy, 0), bottom - Self.minimumSide)
        case .bottomLeading:
            left = min(max(left + dx, 0), right - Self.minimumSide)
            bottom = max(min(bottom + dy, 1), top + Self.minimumSide)
        case .bottomTrailing:
            right = max(min(right + dx, 1), left + Self.minimumSide)
            bottom = max(min(bottom + dy, 1), top + Self.minimumSide)
        }
        return CropRect(x: left, y: top, width: right - left, height: bottom - top)
    }

    /// The same region after the image turns a quarter turn clockwise.
    public func rotatedClockwise() -> CropRect {
        CropRect(x: 1 - y - height, y: x, width: height, height: width)
    }

    /// The same region after the image is mirrored left to right.
    public func flippedHorizontally() -> CropRect {
        CropRect(x: 1 - x - width, y: y, width: width, height: height)
    }
}

/// What to do with the image's backdrop.
public enum Background: String, Codable, CaseIterable, Identifiable, Sendable {
    case keep
    /// Flood the edge colour away: clip art, stickers, scans on white.
    case solid
    /// Let Vision find the subject: photos and busy backgrounds.
    case subject

    public var id: Self { self }
}

/// Every change made to the source, kept apart from it so any edit can be undone or adjusted later.
/// Applied in order: orientation, crop, background, style, trim.
public struct Edit: Codable, Equatable, Sendable {
    /// Clockwise quarter turns, applied before the flip.
    public var quarterTurns = 0
    public var flipped = false
    /// In the oriented image's space, which is what the crop editor shows.
    public var crop = CropRect.full
    public var background = Background.keep
    public var tolerance = 0.12
    public var style = Style.color
    public var threshold = 0.5
    public var inverted = false
    /// Height as a fraction of the menu bar's.
    public var scale = 0.85
    public var animates = true

    public init() {}

    /// Turns the image as shown a quarter turn clockwise, crop and all.
    public mutating func rotateClockwise() {
        // The flip comes after the turn, so on a mirrored image a clockwise turn on screen is a
        // counter-clockwise turn underneath.
        quarterTurns = ((quarterTurns + (flipped ? 3 : 1)) % 4)
        crop = crop.rotatedClockwise()
    }

    /// Mirrors the image as shown left to right, crop and all.
    public mutating func flip() {
        flipped.toggle()
        crop = crop.flippedHorizontally()
    }

    /// Back to the whole image the right way up, keeping how it's coloured and sized.
    public mutating func resetFraming() {
        quarterTurns = 0
        flipped = false
        crop = .full
    }

    /// What the crop editor shows: turned and mirrored, not yet cropped.
    public func oriented(_ bitmap: Bitmap) -> Bitmap {
        let turned = bitmap.rotated(quarterTurns: quarterTurns)
        return flipped ? turned.flippedHorizontally() : turned
    }

    public func framed(_ bitmap: Bitmap) -> Bitmap {
        oriented(bitmap).cropped(to: crop)
    }

    /// The steps after framing, for every frame of the image. A subject lift, which needs Vision, happens
    /// between the two.
    public func finished(_ frames: [Bitmap]) -> [Bitmap] {
        Bitmap.trimmedTogether(
            frames.map { bitmap in
                let backdrop = background == .solid ? bitmap.removingBackground(tolerance: tolerance) : bitmap
                return backdrop.styled(style, threshold: threshold, inverted: inverted)
            })
    }
}
