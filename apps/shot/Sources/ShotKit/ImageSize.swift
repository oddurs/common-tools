/// How big a shot is when it reaches the clipboard. Claude reads an image as roughly one token per 750
/// pixels, so pixels, not bytes, are what a prompt pays for.
public enum ImageSize: String, CaseIterable, Sendable {
    /// Long edge at most 1568 px: a full Retina screen drops from Claude's ~4,800-token ceiling to about
    /// 2,100, and an ordinary crop of code or an error is untouched.
    case prompt
    case full

    public static let promptLongEdge = 1568

    /// The size to scale a `width` × `height` image to. Never larger, and the aspect ratio kept.
    public func fit(width: Int, height: Int) -> (width: Int, height: Int) {
        switch self {
        case .full: (width, height)
        case .prompt: Self.fit(width: width, height: height, longEdge: Self.promptLongEdge, pixels: .max)
        }
    }

    /// What current Claude models charge for an image: about one token per 750 pixels after scaling it to
    /// fit 2576 px on the long edge, and never more than 4,784.
    public static func estimatedTokens(width: Int, height: Int) -> Int {
        let seen = fit(width: width, height: height, longEdge: 2576, pixels: .max)
        return min(4784, Int((Double(seen.width * seen.height) / 750).rounded()))
    }

    static func fit(width: Int, height: Int, longEdge: Int, pixels: Int) -> (width: Int, height: Int) {
        guard width > 0, height > 0 else { return (width, height) }
        let byEdge = Double(longEdge) / Double(max(width, height))
        let byArea = (Double(pixels) / (Double(width) * Double(height))).squareRoot()
        let scale = min(1, byEdge, byArea)
        guard scale < 1 else { return (width, height) }
        return (max(1, Int((Double(width) * scale).rounded())), max(1, Int((Double(height) * scale).rounded())))
    }

    /// "≈ 840 tokens", "≈ 2.1k tokens".
    public static func describe(tokens: Int) -> String {
        guard tokens >= 1000 else { return "≈ \(tokens) tokens" }
        let tenths = (tokens + 50) / 100
        return "≈ \(tenths / 10).\(tenths % 10)k tokens"
    }
}
