import CommonUI
import GlyphKit
import SwiftUI

/// Glyphs at their real size in a light and a dark menu bar, beside the items they will sit with.
struct MenuBarPreview: View {
    let models: [GlyphModel]

    var body: some View {
        VStack(spacing: Tokens.Space.xs) {
            bar(.light)
            bar(.dark)
        }
        .accessibilityElement()
        .accessibilityLabel("Preview in light and dark menu bars")
    }

    private func bar(_ scheme: ColorScheme) -> some View {
        let shape = RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous)
        // Each bar is forced to one appearance, so the system colours inside it resolve for that
        // appearance: the window surface stands in for the bar, and the label colour for its ink.
        return HStack(spacing: 14) {
            Spacer(minLength: 0)
            ForEach(models) { model in
                PreviewGlyph(glyph: model.glyph, animates: model.edit.animates)
            }
            Image(systemName: "wifi")
            Image(systemName: "battery.75percent")
            Text("Fri 9:41")
        }
        // The menu bar's own type: body at medium weight is what the clock is set in.
        .font(.body.weight(.medium))
        .foregroundStyle(.primary)
        .padding(.horizontal, Tokens.Space.sm)
        .frame(height: NSStatusBar.system.thickness + Tokens.Space.xxs)
        .clipped()
        .background(Tokens.Surface.base.color, in: shape)
        .overlay(shape.strokeBorder(Tokens.Color.border.color))
        .environment(\.colorScheme, scheme)
    }
}

private struct PreviewGlyph: View {
    let glyph: Glyph?
    let animates: Bool

    var body: some View {
        if let glyph {
            if glyph.isAnimated && animates {
                TimelineView(.animation) { context in
                    image(
                        glyph.frames[
                            FrameTiming.frame(at: context.date.timeIntervalSinceReferenceDate, delays: glyph.delays)])
                }
            } else {
                image(glyph.frames[0])
            }
        } else {
            Image(systemName: "sparkle")
        }
    }

    private func image(_ image: NSImage) -> some View {
        Image(nsImage: image).renderingMode(glyph?.isTemplate == true ? .template : .original)
    }
}
