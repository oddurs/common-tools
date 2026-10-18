import AppKit

/// The colour of graphs, gauges, and legends. Every choice is a system
/// colour, so each adapts to light, dark, and Increase Contrast.
public enum Palette: String, Codable, CaseIterable, Sendable {
    /// Follows the accent colour chosen in System Settings.
    case accent
    /// Each metric in its own colour, matching its Settings icon.
    case metric
    case blue, purple, pink, red, orange, yellow, green, graphite

    public var name: String {
        switch self {
        case .accent: "Accent Color"
        case .metric: "Per Metric"
        default: rawValue.capitalized
        }
    }

    public func color(for metric: Metric) -> NSColor {
        switch self {
        case .accent: .controlAccentColor
        case .metric: metric.tint
        case .blue: .systemBlue
        case .purple: .systemPurple
        case .pink: .systemPink
        case .red: .systemRed
        case .orange: .systemOrange
        case .yellow: .systemYellow
        case .green: .systemGreen
        case .graphite: .systemGray
        }
    }

    /// One step of the metric's colour. Every coloured mark in the menu takes its colour from here,
    /// and the Settings swatches preview the same steps.
    public func color(for metric: Metric, _ shade: Shade) -> NSColor {
        let base = color(for: metric)
        guard shade != .strong else { return base }
        return NSColor(name: nil) { appearance in
            base.withAlphaComponent(shade.alpha(in: appearance))
        }
    }
}

/// Three steps of one palette colour, used the same way everywhere: the strongest is the primary
/// series, and a legend dot takes the step of the mark it names.
public enum Shade: CaseIterable, Sendable {
    case strong, medium, soft

    /// The step's opacity over the base colour. Translucency darkens over a dark menu, so the
    /// lighter steps carry more alpha there to stay apart; Increase Contrast raises them again so the
    /// softest step still stands off the card behind it.
    public func alpha(dark: Bool, highContrast: Bool) -> CGFloat {
        let (medium, soft): (CGFloat, CGFloat) =
            switch (dark, highContrast) {
            case (false, false): (0.62, 0.36)
            case (true, false): (0.72, 0.5)
            case (false, true): (0.75, 0.5)
            case (true, true): (0.82, 0.62)
            }
        switch self {
        case .strong: return 1
        case .medium: return medium
        case .soft: return soft
        }
    }

    func alpha(in appearance: NSAppearance) -> CGFloat {
        let match = appearance.bestMatch(from: [
            .aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua,
        ])
        return alpha(
            dark: match == .darkAqua || match == .accessibilityHighContrastDarkAqua,
            highContrast: match == .accessibilityHighContrastAqua || match == .accessibilityHighContrastDarkAqua)
    }
}

extension Metric {
    /// The metric's own colour: its icon in Settings, and its marks under `Palette.metric`.
    public var tint: NSColor {
        switch self {
        case .cpu: .systemBlue
        case .gpu: .systemPurple
        case .memory: .systemPink
        case .network: .systemTeal
        case .disk: .systemOrange
        case .storage: .systemGray
        case .battery: .systemGreen
        }
    }
}
