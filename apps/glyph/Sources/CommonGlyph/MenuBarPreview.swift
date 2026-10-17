import GlyphKit
import SwiftUI

/// Glyphs at their real size in a light and a dark menu bar, beside the items they will sit with.
struct MenuBarPreview: View {
    let models: [GlyphModel]

    var body: some View {
        VStack(spacing: 6) {
            bar(.light)
            bar(.dark)
        }
        .accessibilityElement()
        .accessibilityLabel("Preview in light and dark menu bars")
    }

    private func bar(_ scheme: ColorScheme) -> some View {
        let ink: Color = scheme == .dark ? .white : .black
        return HStack(spacing: 14) {
            Spacer(minLength: 0)
            ForEach(models) { model in
                PreviewGlyph(glyph: model.glyph, animates: model.edit.animates)
            }
            .foregroundStyle(ink)
            Image(systemName: "wifi")
            Image(systemName: "battery.75percent")
            Text("Fri 9:41")
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(ink.opacity(0.9))
        .padding(.horizontal, 12)
        .frame(height: NSStatusBar.system.thickness + 4)
        .clipped()
        .background(scheme == .dark ? Color(white: 0.14) : Color(white: 0.95), in: .rect(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(.separator))
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
