import SwiftUI

/// A card in a menu or popover: the panel Common Stats and Common Keys draw under each metric. A
/// faint tint of the text colour over the menu's own material, inside a hairline, so it reads the
/// same over a light or a dark menu without painting over the system.
///
///     Card {
///         VStack(alignment: .leading, spacing: Tokens.Space.xs) {
///             Text("CPU").font(.headline)
///             Text("12%").font(.title3.monospacedDigit())
///         }
///     }
///     .frame(width: Tokens.Layout.menuPanelWidth)
public struct Card<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
        content
            .padding(Tokens.Layout.cardInset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Tokens.Surface.card.color, in: shape)
            .overlay(shape.strokeBorder(Tokens.Color.borderCard.color, lineWidth: 0.5))
    }
}

extension Tokens.Layout {
    /// What a `Card` insets its content by; a layout that must know the card's inner width reads it here.
    public static let cardInset: CGFloat = Tokens.Space.sm
}
