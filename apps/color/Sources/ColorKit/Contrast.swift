import Foundation

/// WCAG 2's contrast ratio between two colours, and what it passes.
public struct Contrast: Equatable, Sendable {
    /// From 1 (the same luminance) to 21 (black on white).
    public let ratio: Double

    public init(_ first: ColorValue, _ second: ColorValue) {
        let (a, b) = (first.luminance, second.luminance)
        ratio = (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    public enum Level: String, CaseIterable, Sendable {
        case aa = "AA"
        case aaa = "AAA"
    }

    public enum TextSize: String, CaseIterable, Sendable {
        /// Under 18 pt, or under 14 pt bold.
        case normal = "Normal"
        /// 18 pt and up, or 14 pt bold and up.
        case large = "Large"
    }

    /// WCAG 2.2, success criteria 1.4.3 (AA) and 1.4.6 (AAA). The ratio is compared unrounded:
    /// 4.48 does not pass a 4.5 requirement by being shown as 4.5.
    public static func required(_ level: Level, _ size: TextSize) -> Double {
        switch (level, size) {
        case (.aa, .normal): 4.5
        case (.aa, .large): 3
        case (.aaa, .normal): 7
        case (.aaa, .large): 4.5
        }
    }

    public func passes(_ level: Level, _ size: TextSize) -> Bool {
        ratio >= Self.required(level, size)
    }

    /// "4.47:1": truncated, not rounded, to two places, so a ratio just short of a threshold never
    /// reads as meeting it.
    public var text: String {
        // Rounded to six places first, so floating-point dust (20.999999…) doesn't truncate away.
        let truncated = ((ratio * 100 * 10_000).rounded() / 10_000).rounded(.down) / 100
        return ColorFormat.number(truncated, 2) + ":1"
    }
}
