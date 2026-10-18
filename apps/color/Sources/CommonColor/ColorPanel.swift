import ColorKit
import CommonUI
import SwiftUI

/// The top of the menu: the current colour in every format, the recent picks, and the contrast
/// between the newest two. A pure function of its inputs, so the snapshot renders it offscreen.
struct ColorPanel: View {
    let history: History
    let format: ColorFormat
    let shortcut: String
    var copy: (ColorFormat, ColorValue) -> Void = { _, _ in }
    var choose: (ColorValue) -> Void = { _ in }
    var clear: () -> Void = {}

    var body: some View {
        VStack(spacing: Tokens.Space.xs) {
            if let current = history.current {
                Card { CurrentColor(color: current, format: format, copy: copy) }
                Card { RecentColors(history: history, choose: choose, clear: clear) }
                if let contrast = history.contrast {
                    Card { ContrastView(contrast: contrast, first: history.colors[0], second: history.colors[1]) }
                }
            } else {
                Card {
                    VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                        Text("No Colors Yet").font(.headline)
                        Text("Press \(shortcut) or choose Pick Color, then click any pixel on any screen.")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(width: Tokens.Layout.menuPanelWidth)
        .padding(.horizontal, Tokens.Space.xs)
        .padding(.vertical, Tokens.Space.xxs)
    }
}

/// A picked colour, drawn as itself: data, not a colour of the interface. A hairline keeps white
/// on a light menu, or black on a dark one, from vanishing.
struct Swatch: View {
    let color: ColorValue
    var size: CGFloat = 24
    var selected = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Tokens.Radius.xs, style: .continuous)
        shape.fill(Color(cgColor: color.cgColor))
            .overlay(shape.strokeBorder(Tokens.Color.borderCard.color, lineWidth: 1))
            .overlay {
                if selected {
                    shape.inset(by: -3).strokeBorder(Tokens.Color.accent.color, lineWidth: 2)
                }
            }
            .frame(width: size, height: size)
    }
}

private struct CurrentColor: View {
    let color: ColorValue
    let format: ColorFormat
    let copy: (ColorFormat, ColorValue) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            HStack(spacing: Tokens.Space.sm) {
                Swatch(color: color, size: 40)
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    // The hex names the colour at a glance; ≈ when sRGB can only come close.
                    Text((color.isInGamut(.sRGB) ? "" : "≈ ") + ColorFormat.hex.string(color))
                        .font(.headline.monospaced())
                    Text(gamut).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            VStack(spacing: 0) {
                ForEach(ColorFormat.allCases, id: \.self) { each in
                    FormatRow(format: each, color: color, isDefault: each == format) { copy(each, color) }
                }
            }
            if !color.isInGamut(.sRGB) {
                SettingsFootnote(
                    "Outside sRGB. Hex, RGB and HSL give the nearest sRGB color; the others are exact.",
                    symbol: "exclamationmark.triangle")
            }
        }
    }

    private var gamut: String {
        if color.isInGamut(.sRGB) { return "Within sRGB" }
        return color.isInGamut(.displayP3) ? "Display P3, outside sRGB" : "Outside Display P3"
    }
}

/// One format, one click to copy. Marked when it is the one a pick copies.
private struct FormatRow: View {
    let format: ColorFormat
    let color: ColorValue
    let isDefault: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.xs) {
                Text(format.title)
                    .foregroundStyle(.secondary)
                    .frame(width: 72, alignment: .leading)
                // Whole, wrapping if it must: the code is the point, so none of it is elided.
                Text(format.string(color))
                    .font(.callout.monospaced())
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !format.isExact(color) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(Tokens.Color.warning.color)
                        .help("The nearest color \(format.gamut == .sRGB ? "sRGB" : "Display P3") can show")
                } else if isDefault {
                    Image(systemName: "checkmark").foregroundStyle(.secondary)
                        .help("What a pick copies")
                }
            }
            .padding(.horizontal, Tokens.Space.xxs)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
            .background(
                hovering ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear),
                in: RoundedRectangle(cornerRadius: Tokens.Radius.xs, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .accessibilityLabel("Copy \(format.title): \(format.string(color))")
    }
}

private struct RecentColors: View {
    let history: History
    let choose: (ColorValue) -> Void
    let clear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            HStack {
                Text("Recent").font(.headline)
                Spacer()
                Button(action: clear) {
                    Text("Clear").foregroundStyle(Tokens.Color.accent.color)
                }
                .buttonStyle(.plain)
            }
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: Tokens.Space.xs), count: 6),
                spacing: Tokens.Space.xs
            ) {
                ForEach(Array(history.colors.enumerated()), id: \.offset) { index, color in
                    Button {
                        choose(color)
                    } label: {
                        Swatch(color: color, size: 32, selected: index == 0)
                    }
                    .buttonStyle(.plain)
                    .help(ColorFormat.hex.string(color))
                    .accessibilityLabel(ColorFormat.hex.string(color))
                }
            }
        }
    }
}

/// WCAG 2 contrast between the newest two picks, with what it passes for each text size.
private struct ContrastView: View {
    let contrast: Contrast
    let first: ColorValue
    let second: ColorValue

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            HStack(alignment: .center, spacing: Tokens.Space.sm) {
                // The newest pick as text on the one before it, the question contrast answers.
                Text("Aa")
                    .font(.title2.weight(Tokens.Weight.semibold))
                    .foregroundStyle(Color(cgColor: first.cgColor))
                    .frame(width: 48, height: 40)
                    .background(
                        Color(cgColor: second.cgColor),
                        in: RoundedRectangle(cornerRadius: Tokens.Radius.xs, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Tokens.Radius.xs, style: .continuous)
                            .strokeBorder(Tokens.Color.borderCard.color, lineWidth: 1)
                    )
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    Text("Contrast").font(.headline)
                    Text("Newest two picks, WCAG 2").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text(contrast.text).font(.title2.weight(Tokens.Weight.semibold).monospacedDigit())
            }
            Grid(alignment: .leading, horizontalSpacing: Tokens.Space.md, verticalSpacing: Tokens.Space.xxs) {
                GridRow {
                    Text("")
                    ForEach(Contrast.Level.allCases, id: \.self) { Text($0.rawValue).foregroundStyle(.secondary) }
                }
                ForEach(Contrast.TextSize.allCases, id: \.self) { size in
                    GridRow {
                        Text("\(size.rawValue) text").foregroundStyle(.secondary)
                        ForEach(Contrast.Level.allCases, id: \.self) { level in
                            Verdict(passes: contrast.passes(level, size))
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct Verdict: View {
    let passes: Bool

    var body: some View {
        Label(passes ? "Pass" : "Fail", systemImage: passes ? "checkmark.circle.fill" : "xmark.circle.fill")
            .foregroundStyle(passes ? Tokens.Color.success.color : Tokens.Color.danger.color)
    }
}
