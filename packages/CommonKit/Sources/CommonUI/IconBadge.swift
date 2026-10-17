import SwiftUI

/// A System Settings–style icon: a white symbol on a tinted, continuously rounded square. It is
/// decoration beside a label, so VoiceOver skips it; the row it sits in carries the name.
///
///     IconBadge(symbol: "cpu", tint: .blue)
///     IconBadge(symbol: "keyboard", tint: .indigo, size: 32)
public struct IconBadge: View {
    private let symbol: String
    private let tint: Color
    private let size: CGFloat

    public init(symbol: String, tint: Color, size: CGFloat = 20) {
        self.symbol = symbol
        self.tint = tint
        self.size = size
    }

    public var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(Tokens.Text.inverse.color)
            .frame(width: size, height: size)
            // App icons round at a fixed share of their size; so does the badge, whatever its size.
            .background(tint.gradient, in: RoundedRectangle(cornerRadius: size * 0.27, style: .continuous))
            .accessibilityHidden(true)
    }
}
