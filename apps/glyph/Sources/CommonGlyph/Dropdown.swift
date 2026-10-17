import CommonUI
import GlyphKit
import SwiftUI

enum DropdownPanel {
    static var width: CGFloat { Tokens.Layout.menuPanelWidth }
}

/// The card at the top of a glyph's menu: the glyph large, its name, and how it's made.
struct GlyphCard: View {
    let model: GlyphModel
    let others: Int

    var body: some View {
        Card {
            HStack(spacing: Tokens.Space.sm) {
                GlyphTile(glyph: model.glyph, size: 52)
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    Text(model.spec.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text(model.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if others > 0 {
                        Text(others == 1 ? "1 other glyph" : "\(others) other glyphs")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, Tokens.Space.xs)
        .padding(.vertical, Tokens.Space.xxs)
        .frame(width: DropdownPanel.width)
        .accessibilityElement(children: .combine)
    }
}

extension GlyphModel {
    /// What the glyph is drawn from and how, in a few words: "Image · Ink · Subject lifted".
    var summary: String {
        let edit = spec.edit
        var parts = [spec.kind == .image ? "Image" : "Text"]
        if isAnimated { parts[0] = "Animation" }
        let style =
            switch edit.style {
            case .color: "Colour"
            case .silhouette: "Silhouette"
            case .ink: "Ink"
            }
        parts.append(style)
        if spec.kind == .image {
            switch edit.background {
            case .keep: break
            case .solid: parts.append("Background removed")
            case .subject: parts.append("Subject lifted")
            }
        }
        return parts.joined(separator: " · ")
    }
}

/// The glyph on a soft rounded square, like an app icon: in settings rows and the menu's card. It is
/// the card surface at `IconBadge`'s proportions, since it stands where a badge would.
struct GlyphTile: View {
    let glyph: Glyph?
    var size: CGFloat = 28

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
        Group {
            if let glyph, let image = glyph.frames.first {
                Image(nsImage: image)
                    .renderingMode(glyph.isTemplate ? .template : .original)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "sparkle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(size * 0.18)
        .frame(width: size, height: size)
        .background(Tokens.Surface.card.color, in: shape)
        .overlay(shape.strokeBorder(Tokens.Color.borderCard.color, lineWidth: 0.5))
        .accessibilityHidden(true)
    }
}
