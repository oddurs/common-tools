import CommonKit
import CommonUI
import StatKit
import SwiftUI

struct SettingsView: View {
    @Bindable var model: AppModel
    @State private var loginProblem: LoginItem.Problem?

    var body: some View {
        Form {
            Section {
                BarEditor(model: model)
            } footer: {
                if !model.barVisible {
                    SettingsFootnote(
                        "Common Stats is running but can’t be seen in the menu bar. It may be behind the camera housing or hidden by a menu bar manager. Show fewer items, choose Compact density, or hold ⌘ and drag other menu bar items out of the way.",
                        symbol: "eye.slash"
                    )
                }
            }

            Section {
                Toggle("Show labels", isOn: $model.layout.showCaptions)
                Picker("Density", selection: $model.layout.density) {
                    ForEach(Density.allCases, id: \.self) { Text($0.name) }
                }
                LabeledContent("Color") {
                    PaletteSwatches(selection: $model.layout.palette)
                }
                Toggle("Color in menu bar", isOn: $model.layout.colorInMenuBar)
            } header: {
                Text("Appearance")
            } footer: {
                SettingsFootnote(
                    "Color applies to graphs and gauges. Off in the menu bar, items stay monochrome like the system’s own icons."
                )
            }

            Section {
                OpenAtLoginToggle(problem: $loginProblem)
                Picker("Update every", selection: $model.layout.interval) {
                    ForEach(BarLayout.intervals, id: \.self) { s in
                        Text(s == 1 ? "1 second" : "\(s.formatted()) seconds")
                    }
                }
                Picker("Average over", selection: $model.layout.smoothing) {
                    ForEach(Smoothing.allCases, id: \.self) { Text($0.name) }
                }
            } header: {
                Text("General")
            } footer: {
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    OpenAtLoginFootnote(loginProblem)
                    SettingsFootnote(
                        "Averaging steadies the menu bar’s numbers and graphs. The menu always shows exact readings.")
                }
            }

            CommonToolsSection()
        }
        .settingsForm()
    }
}

/// Colour swatches in the style of System Settings' accent colour picker.
/// The selected swatch carries a white dot; its name shows beneath.
private struct PaletteSwatches: View {
    @Binding var selection: Palette

    var body: some View {
        VStack(alignment: .trailing, spacing: Tokens.Space.xxs) {
            HStack(spacing: Tokens.Space.xs) {
                ForEach(Palette.allCases, id: \.self) { palette in
                    Button {
                        selection = palette
                    } label: {
                        swatch(palette)
                            .overlay {
                                if palette == selection {
                                    Circle().fill(Tokens.Text.inverse.color).frame(width: 6, height: 6)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .help(palette.name)
                    .accessibilityLabel(palette.name)
                    .accessibilityAddTraits(palette == selection ? .isSelected : [])
                }
            }
            Text(selection.name).font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private func swatch(_ palette: Palette) -> some View {
        let circle = Circle().frame(width: 16, height: 16)
        Group {
            switch palette {
            case .accent:
                circle.foregroundStyle(Tokens.Color.accent.color)
            case .metric:
                // Per Metric shows every metric's colour, like the system's Multicolor swatch.
                circle.foregroundStyle(
                    AngularGradient(
                        colors: (Metric.allCases + [Metric.cpu]).map { Color(nsColor: $0.tint) }, center: .center))
            default:
                circle.foregroundStyle(Color(nsColor: palette.color(for: .cpu)))
            }
        }
        .overlay(Circle().strokeBorder(Tokens.Color.border.color, lineWidth: 0.5))
    }
}

extension IconBadge {
    /// A metric's icon: its SF Symbol on its own tint, the identity it keeps in Settings and the menu.
    init(metric: Metric, size: CGFloat) {
        self.init(symbol: metric.symbol, tint: Color(nsColor: metric.tint), size: size)
    }
}
