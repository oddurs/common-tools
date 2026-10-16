import GlyphKit
import SwiftUI

enum DropdownPanel {
    static let width: CGFloat = 320
}

/// The card at the top of a glyph's menu: the glyph large, its name, and how it's made.
struct GlyphCard: View {
    let model: GlyphModel
    let others: Int

    var body: some View {
        Card {
            HStack(spacing: 12) {
                GlyphTile(glyph: model.glyph, size: 52)
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.spec.name)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Text(model.summary)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if others > 0 {
                        Text(others == 1 ? "1 other glyph" : "\(others) other glyphs")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
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

/// The glyph on a soft rounded square, like an app icon: in settings rows and the menu's card.
struct GlyphTile: View {
    let glyph: Glyph?
    var size: CGFloat = 28

    var body: some View {
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
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: size * 0.27, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
        .accessibilityHidden(true)
    }
}

/// A Control Center–style module: a softly filled rounded panel, as in Common Stats and Common Keys.
struct Card<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5))
    }
}
