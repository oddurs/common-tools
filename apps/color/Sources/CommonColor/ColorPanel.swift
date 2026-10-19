import ColorKit
import CommonUI
import SwiftUI

/// What the menu bar item opens. Pick Color first, then the selected colour as the hero: a large
/// swatch, its hex and family, and one row that copies it in the default format, with the other
/// formats a click away. Under it the recent picks, and the contrast between the newest two.
///
/// The keyboard does all of it: arrows move through the recent picks (the hero follows), Return
/// copies in the default format, 1–7 copy a format, Delete removes a pick with Undo beside it, and
/// Escape closes.
struct ColorPanel: View {
    struct Actions {
        var pick: () -> Void = {}
        /// Copies `color` as `format`; `reuse` brings an older pick back to the front, as picking it again would.
        var copy: (_ format: ColorFormat, _ color: ColorValue, _ reuse: Bool) -> Void = { _, _, _ in }
        var settings: () -> Void = {}
        var quit: () -> Void = {}
        var close: () -> Void = {}
    }

    let picks: Picks
    let format: ColorFormat
    @Binding var showsAllFormats: Bool
    let shortcut: String
    var shortcutProblem: String?
    var actions = Actions()

    @State var selection: Int?
    @State private var removed: (color: ColorValue, index: Int)?
    @FocusState private var focused: Bool

    static let columns = 6

    private var colors: [ColorValue] { picks.history.colors }
    /// What the hero shows: the selected pick, or the newest.
    private var selected: (color: ColorValue, index: Int)? {
        let index = selection ?? 0
        return colors.indices.contains(index) ? (colors[index], index) : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            MenuRow("Pick Color", symbol: "eyedropper", shortcut: shortcutProblem == nil ? shortcut : nil) {
                actions.pick()
            }
            if let shortcutProblem {
                SettingsFootnote(shortcutProblem, tone: .danger).padding(.horizontal, Tokens.Space.xs)
            }
            if let selected {
                Card { hero(selected.color, isNewest: selected.index == 0) }
                Card { recent }
                if let contrast = picks.history.contrast {
                    Card { ContrastView(contrast: contrast, text: colors[0], background: colors[1]) }
                }
            } else {
                Card { empty }
            }
            if let removed {
                HStack {
                    Label("Removed \(ColorFormat.hex.string(removed.color))", systemImage: "trash")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Undo") { undo() }
                }
                .font(.subheadline)
                .padding(.horizontal, Tokens.Space.xs)
                .accessibilityElement(children: .combine)
            }
            Divider().padding(.horizontal, Tokens.Space.xs)
            VStack(spacing: 0) {
                MenuRow("Settings…", symbol: "gearshape", shortcut: "⌘,") { actions.settings() }
                MenuRow("Quit Common Color", symbol: "power", shortcut: "⌘Q") { actions.quit() }
            }
        }
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onAppear { focused = true }
        .onKeyPress(keys: [.leftArrow, .rightArrow, .upArrow, .downArrow]) { press in
            let move: GridMove =
                switch press.key {
                case .leftArrow: .left
                case .rightArrow: .right
                case .upArrow: .up
                default: .down
                }
            selection = move.from(selection ?? 0, count: colors.count, columns: Self.columns)
            return .handled
        }
        .onKeyPress(.return) {
            guard let selected else { return .ignored }
            actions.copy(format, selected.color, true)
            return .handled
        }
        .onKeyPress(keys: [.delete, .deleteForward]) { _ in
            guard let selected else { return .ignored }
            remove(at: selected.index)
            return .handled
        }
        .onKeyPress(.escape) {
            actions.close()
            return .handled
        }
        .onKeyPress { press in
            // ⌘, ⌘Q ⌘Z as a menu has them, and a bare digit copies that format.
            guard let character = press.characters.first else { return .ignored }
            if press.modifiers == .command {
                switch character {
                case ",": actions.settings()
                case "q": actions.quit()
                case "z": undo()
                default: return .ignored
                }
                return .handled
            }
            guard press.modifiers.isEmpty, let format = ColorFormat(key: character), let selected else {
                return .ignored
            }
            actions.copy(format, selected.color, true)
            return .handled
        }
    }

    // MARK: The hero

    private func hero(_ color: ColorValue, isNewest: Bool) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            HStack(spacing: Tokens.Space.sm) {
                Swatch(color: color, size: 64, radius: Tokens.Radius.sm)
                VStack(alignment: .leading, spacing: 2) {
                    Text(ColorFormat.hex.string(color))
                        .font(.title2.weight(Tokens.Weight.semibold).monospaced())
                        .textSelection(.disabled)
                    Text(Self.capitalized(color.family) + " · " + color.gamutDescription)
                        .font(.subheadline).foregroundStyle(.secondary)
                    if !isNewest {
                        Text("From recent picks").font(.footnote).foregroundStyle(.tertiary)
                    }
                }
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(color.spoken)
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                FormatRow(format: format, color: color, hint: "↩", prominent: true) {
                    actions.copy(format, color, !isNewest)
                }
                if showsAllFormats {
                    ForEach(ColorFormat.allCases.filter { $0 != format }, id: \.self) { each in
                        FormatRow(format: each, color: color, hint: String(each.key)) {
                            actions.copy(each, color, !isNewest)
                        }
                    }
                }
            }

            HStack(alignment: .firstTextBaseline) {
                Button {
                    withAnimation(Tokens.Motion.animation(Tokens.Motion.fast)) { showsAllFormats.toggle() }
                } label: {
                    Label(
                        showsAllFormats ? "Fewer Formats" : "All Formats",
                        systemImage: showsAllFormats ? "chevron.up" : "chevron.down"
                    )
                    .labelStyle(TrailingIcon())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Tokens.Color.accent.color)
                .accessibilityHint("Shows every format. Press 1 to 7 to copy one.")
                Spacer()
                if !color.isInGamut(.sRGB) {
                    Label("Hex, RGB, HSL: nearest sRGB", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                        .help(
                            "sRGB can’t show this color. Those formats give the nearest color it can; the others are exact."
                        )
                }
            }
            .font(.footnote)
            .padding(.horizontal, Tokens.Space.xxs)
        }
    }

    // MARK: Recent picks

    private var recent: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            SectionHeader("Recent", detail: colors.count == 1 ? "1 color" : "\(colors.count) colors") {
                Button("Clear") { picks.clear() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Tokens.Color.accent.color)
            }
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: Tokens.Space.xs), count: Self.columns),
                spacing: Tokens.Space.xs
            ) {
                ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                    RecentSwatch(color: color, isSelected: (selection ?? 0) == index)
                        .onTapGesture { actions.copy(format, color, true) }
                        .contextMenu {
                            Button("Copy as \(format.title)") { actions.copy(format, color, true) }
                            Menu("Copy As") {
                                ForEach(ColorFormat.allCases, id: \.self) { each in
                                    Button(each.title) { actions.copy(each, color, true) }
                                }
                            }
                            Divider()
                            Button("Remove") { remove(at: index) }
                        }
                        .accessibilityAction(named: "Remove") { remove(at: index) }
                }
            }
        }
    }

    private var empty: some View {
        HStack(alignment: .top, spacing: Tokens.Space.sm) {
            IconBadge(symbol: "eyedropper", tint: .gray, size: 32)
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                Text("No Colors Yet").font(.headline)
                Text(
                    "Press \(shortcut), then click any pixel on any screen. Your last \(History.limit) picks wait here."
                )
                .font(.subheadline).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func remove(at index: Int) {
        guard let color = picks.remove(at: index) else { return }
        removed = (color, index)
        // The selection stays in place, on the pick that moved up into it.
        let count = colors.count
        selection = count == 0 ? nil : min(index, count - 1)
    }

    private func undo() {
        guard let removed else { return }
        picks.restore(removed.color, at: removed.index)
        selection = removed.index
        self.removed = nil
    }

    static func capitalized(_ text: String) -> String {
        text.prefix(1).uppercased() + text.dropFirst()
    }
}

/// A picked colour, drawn as itself: data, not a colour of the interface. A hairline keeps white on a
/// light panel, or black on a dark one, from vanishing; Increase Contrast makes it a full line.
struct Swatch: View {
    let color: ColorValue
    var size: CGFloat = 24
    var radius: CGFloat = Tokens.Radius.xs
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        shape.fill(Color(cgColor: color.cgColor))
            .overlay(
                shape.strokeBorder(
                    contrast == .increased ? Tokens.Color.border.color : Tokens.Color.borderCard.color,
                    lineWidth: contrast == .increased ? 1.5 : 1)
            )
            .frame(width: size, height: size)
    }
}

/// A swatch in the grid: washed on hover, ringed in the accent colour when selected, as ThumbnailTile is.
private struct RecentSwatch: View {
    let color: ColorValue
    let isSelected: Bool
    @State private var hovering = false

    var body: some View {
        let ring = RoundedRectangle(cornerRadius: Tokens.Radius.xs + 3, style: .continuous)
        Swatch(color: color, size: 34)
            .overlay {
                if hovering {
                    RoundedRectangle(cornerRadius: Tokens.Radius.xs, style: .continuous)
                        .fill(Tokens.Text.primary.color.opacity(0.08))
                }
            }
            .padding(3)
            .overlay {
                if isSelected { ring.strokeBorder(Tokens.Color.accent.color, lineWidth: 2) }
            }
            .contentShape(Rectangle())
            .onHover { hovering = $0 }
            .help("\(ColorFormat.hex.string(color)): click to copy, or right-click for more")
            .accessibilityElement()
            .accessibilityLabel(color.spoken)
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// One format, one click to copy, highlighted under the pointer as a menu item is, with the key that
/// copies it where a menu shows one. The default format's row reads as the action, "Copy as OKLCH",
/// with its whole value under it unless the hero already shows it (hex). The others keep to one
/// line, cut at the end if they must be; the whole value is in the tooltip, in what VoiceOver reads,
/// and in the confirmation after copying.
private struct FormatRow: View {
    let format: ColorFormat
    let color: ColorValue
    let hint: String
    var prominent = false
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        let text = format.string(color)
        let secondary = hovering ? Tokens.Text.inverse.color : Tokens.Text.secondary.color
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.xs) {
                if prominent {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Copy as \(format.title)")
                        if format != .hex {
                            Text(text)
                                .font(.callout.monospaced())
                                .foregroundStyle(secondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } else {
                    Text(format.title)
                        .foregroundStyle(secondary)
                        .frame(width: 68, alignment: .leading)
                    Text(text)
                        .font(.callout.monospaced())
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer(minLength: Tokens.Space.xxs)
                if !format.isExact(color) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(hovering ? Tokens.Text.inverse.color : Tokens.Color.warning.color)
                        .accessibilityHidden(true)
                }
                Text(hint).foregroundStyle(secondary).monospacedDigit()
            }
            .font(prominent ? .body : .callout)
            .foregroundStyle(hovering ? Tokens.Text.inverse.color : Tokens.Text.primary.color)
            .padding(.horizontal, Tokens.Space.xxs)
            .padding(.vertical, prominent ? 5 : 3)
            .contentShape(Rectangle())
            .background(
                hovering ? AnyShapeStyle(Tokens.Color.accentFill.color) : AnyShapeStyle(.clear),
                in: RoundedRectangle(cornerRadius: Tokens.Radius.xs, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(text)
        .accessibilityLabel(
            "Copy as \(format.title): \(text)"
                + (format.isExact(color) ? "" : ", the nearest \(format.gamut == .sRGB ? "sRGB" : "Display P3") color")
        )
        .accessibilityHint(hint == "↩" ? "Return" : "Key \(hint)")
    }
}

/// WCAG 2 contrast between the newest two picks: the newer as text on the older, the ratio and the
/// highest bar it clears, then each text size against AA and AAA.
private struct ContrastView: View {
    let contrast: Contrast
    let text: ColorValue
    let background: ColorValue
    @Environment(\.colorSchemeContrast) private var accessibilityContrast

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            SectionHeader("Contrast", detail: "Newest two picks")
            HStack(spacing: Tokens.Space.sm) {
                let shape = RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous)
                Text("Aa")
                    .font(.title2.weight(Tokens.Weight.semibold))
                    .foregroundStyle(Color(cgColor: text.cgColor))
                    .frame(width: 64, height: 44)
                    .background(Color(cgColor: background.cgColor), in: shape)
                    .overlay(
                        shape.strokeBorder(
                            accessibilityContrast == .increased
                                ? Tokens.Color.border.color : Tokens.Color.borderCard.color, lineWidth: 1))
                VStack(alignment: .leading, spacing: 2) {
                    Text(contrast.text).font(.title2.weight(Tokens.Weight.semibold).monospacedDigit())
                    Text(contrast.verdict).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            Grid(alignment: .leading, horizontalSpacing: Tokens.Space.md, verticalSpacing: Tokens.Space.xxs) {
                ForEach(Contrast.TextSize.allCases, id: \.self) { size in
                    GridRow {
                        Text("\(size.rawValue) text").foregroundStyle(.secondary)
                        ForEach(Contrast.Level.allCases, id: \.self) { level in
                            Verdict(level: level.rawValue, passes: contrast.passes(level, size))
                        }
                    }
                }
            }
            .font(.subheadline)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(contrast.spoken)
    }
}

/// "✓ AA" or "✗ AAA": the mark carries the colour, the level stays readable in the text colour.
private struct Verdict: View {
    let level: String
    let passes: Bool

    var body: some View {
        HStack(spacing: Tokens.Space.xxs) {
            Image(systemName: passes ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(passes ? Tokens.Color.success.color : Tokens.Color.danger.color)
            Text(level).foregroundStyle(passes ? Tokens.Text.primary.color : Tokens.Text.secondary.color)
        }
    }
}

/// The title, then the symbol: "All Formats ⌄".
private struct TrailingIcon: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Tokens.Space.xxs) {
            configuration.title
            configuration.icon.imageScale(.small)
        }
    }
}
