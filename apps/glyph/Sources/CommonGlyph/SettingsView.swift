import CommonKit
import CommonUI
import GlyphKit
import SwiftUI

/// Laid out by the Common Tools Settings standard: a live preview, the app's own sections, then General,
/// then `CommonToolsSection`, so every app's Settings window reads the same. Each glyph's editor opens
/// as a sheet from its row.
struct SettingsView: View {
    @Bindable var library: GlyphLibrary
    @State private var loginError: String?
    @State private var pendingDelete: GlyphModel?
    @State private var duplicateError: String?

    var body: some View {
        Form {
            Section {
                MenuBarPreview(models: library.visible)
            } footer: {
                if let warning {
                    Label(warning, systemImage: "eye.slash")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                ForEach(library.models) { model in
                    row(model)
                }
                Button("Add Glyph") { library.add() }
            } header: {
                Text("Glyphs")
            } footer: {
                if let duplicateError {
                    Text(duplicateError).font(.callout).foregroundStyle(Tokens.Color.danger.color)
                } else {
                    SettingsFootnote("Click a glyph to edit it. Hold ⌘ and drag a glyph in the menu bar to move it.")
                }
            }

            Section {
                OpenAtLoginToggle(error: $loginError)
            } header: {
                Text("General")
            } footer: {
                if let loginError {
                    SettingsFootnote(loginError)
                }
            }

            CommonToolsSection()
        }
        .settingsForm()
        .sheet(item: editing) { model in
            GlyphEditor(model: model, library: library)
        }
        .confirmationDialog(
            "Delete “\(pendingDelete?.spec.name ?? "")”?", isPresented: deleting, presenting: pendingDelete
        ) { model in
            Button("Delete", role: .destructive) { library.remove(model) }
        } message: { _ in
            Text("It leaves the menu bar, and its copy of the image is deleted.")
        }
    }

    private func row(_ model: GlyphModel) -> some View {
        let visible = model.spec.isVisible
        return HStack(spacing: Tokens.Space.xs) {
            Button {
                library.editing = model.id
            } label: {
                LabeledRow(model.spec.name, subtitle: model.summary) {
                    GlyphTile(glyph: model.glyph, size: 32)
                } trailing: {
                    EmptyView()
                }
                .lineLimit(1)
                // Glyphs left out of the menu bar recede, so the shown set reads at a glance.
                .opacity(visible ? 1 : 0.5)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Edit")

            // Under a full-screen app every glyph is hidden at once; the warning above says so instead.
            if visible && !model.isOnScreen && visibility != .barHidden {
                Image(systemName: "eye.slash")
                    .foregroundStyle(.secondary)
                    .help("Running, but can’t be seen in the menu bar")
            }
            Toggle(
                "Show in menu bar",
                isOn: Binding(get: { model.spec.isVisible }, set: { model.spec.isVisible = $0 })
            )
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)
            .disabled(visible && !library.canHide(model))
            .help(visible && !library.canHide(model) ? "One glyph always stays in the menu bar" : "Show in menu bar")
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contextMenu {
            Button("Edit…") { library.editing = model.id }
            Button("Duplicate") {
                do {
                    try library.duplicate(model)
                    duplicateError = nil
                } catch {
                    duplicateError = error.localizedDescription
                }
            }
            Divider()
            Button("Delete…", role: .destructive) { pendingDelete = model }
                .disabled(!library.canRemove(model))
        }
    }

    private var visibility: MenuBarVisibility {
        MenuBarVisibility(glyphs: library.visible.map { ($0.spec.name, $0.isOnScreen) })
    }

    private var warning: String? {
        switch visibility {
        case .seen:
            nil
        case .barHidden:
            "The menu bar is hidden right now, as it is under a full-screen app. Your glyphs are still there."
        case .hidden(let names):
            "\(ListFormatter.localizedString(byJoining: names.map { "“\($0)”" })) can’t be seen in the menu bar. "
                + "They may be behind the camera housing or hidden by a menu bar manager. "
                + "Hold ⌘ and drag them nearer the clock, or drag other items out of the way."
        }
    }

    private var editing: Binding<GlyphModel?> {
        Binding(
            get: { library.editing.flatMap(library.model) },
            set: { library.editing = $0?.id })
    }

    private var deleting: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }
}
