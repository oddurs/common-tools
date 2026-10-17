import AppKit
import QuartzCore
import SwiftUI

/// A colour named for what it is for, usable from AppKit and SwiftUI. Where macOS has a semantic
/// colour it is that colour, so the user's accent, increased contrast, and appearance all apply;
/// where it has none, the token defines a light and a dark value and the colour follows the
/// appearance by itself.
public struct SemanticColor: Sendable {
    public let nsColor: NSColor

    public var color: Color { Color(nsColor: nsColor) }

    public init(system: NSColor) {
        nsColor = system
    }

    /// Ours: `0xrrggbb` for each appearance, with an alpha when the colour is a tint over another.
    public init(light: UInt32, alpha lightAlpha: Double = 1, dark: UInt32, alpha darkAlpha: Double = 1) {
        let lightColor = NSColor(rgb: light, alpha: lightAlpha)
        let darkColor = NSColor(rgb: dark, alpha: darkAlpha)
        nsColor = NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? darkColor : lightColor
        }
    }
}

extension NSColor {
    convenience init(rgb: UInt32, alpha: Double) {
        self.init(
            srgbRed: CGFloat((rgb >> 16) & 0xff) / 255, green: CGFloat((rgb >> 8) & 0xff) / 255,
            blue: CGFloat(rgb & 0xff) / 255, alpha: alpha)
    }
}

/// A cubic Bézier easing, as the motion tokens define it.
public struct Curve: Sendable {
    public let x1: Double
    public let y1: Double
    public let x2: Double
    public let y2: Double

    public init(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) {
        (self.x1, self.y1, self.x2, self.y2) = (x1, y1, x2, y2)
    }
}

extension Tokens.Motion {
    /// An animation from the tokens, or none while the user asks for reduced motion, so every
    /// animated change in the apps honours that setting through one call.
    @MainActor
    public static func animation(_ duration: TimeInterval = base, easing: Curve = Easing.standard) -> Animation? {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion { return nil }
        return .timingCurve(easing.x1, easing.y1, easing.x2, easing.y2, duration: duration)
    }

    /// A duration for AppKit, zero while the user asks for reduced motion, so an
    /// `NSAnimationContext` set from it finishes at once.
    @MainActor
    public static func duration(_ duration: TimeInterval = base) -> TimeInterval {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : duration
    }

    /// Runs `changes` on `animator()` proxies as one AppKit animation group, on the tokens' duration
    /// and easing; at once under reduced motion. `completion` runs on the main actor when it ends.
    @MainActor
    public static func animate(
        _ duration: TimeInterval = base, easing: Curve = Easing.standard, changes: () -> Void,
        completion: (@MainActor @Sendable () -> Void)? = nil
    ) {
        // AppKit calls back on the main thread, which is the main actor; it just can't say so.
        let finish: (@Sendable () -> Void)? = completion.map { done in
            { @Sendable in MainActor.assumeIsolated { done() } }
        }
        NSAnimationContext.runAnimationGroup(
            { context in
                context.duration = Self.duration(duration)
                context.timingFunction = CAMediaTimingFunction(
                    controlPoints: Float(easing.x1), Float(easing.y1), Float(easing.x2), Float(easing.y2))
                changes()
            }, completionHandler: finish)
    }
}
