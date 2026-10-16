import GlyphKit
import SwiftUI

/// Laid out by the Common Tools Settings standard: a live preview, the app's own sections, then General,
/// then `CommonToolsSection`, so every app's Settings window reads the same. Each glyph's editor opens
/// as a sheet from its row.
struct SettingsView: View {
    @Bindable var library: GlyphLibrary
    @State private var openAtLogin = LoginItem.isEnabled
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
                        .font(.footnote)
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
                    Text(duplicateError).font(.footnote).foregroundStyle(.red)
                } else {
                    Text("Click a glyph to edit it. Hold ⌘ and drag a glyph in the menu bar to move it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Toggle("Open at login", isOn: $openAtLogin)
            } header: {
                Text("General")
            } footer: {
                if let loginError {
                    Text(loginError).font(.footnote).foregroundStyle(.secondary)
                }
            }

            CommonToolsSection()
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
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
        .onChange(of: openAtLogin) { _, enabled in
            guard enabled != LoginItem.isEnabled else { return }
            do {
                try LoginItem.setEnabled(enabled)
                loginError = nil
            } catch {
                loginError = error.localizedDescription
                openAtLogin = LoginItem.isEnabled
            }
        }
    }

    private func row(_ model: GlyphModel) -> some View {
        let visible = model.spec.isVisible
        return HStack(spacing: 10) {
            Button {
                library.editing = model.id
            } label: {
                HStack(spacing: 10) {
                    GlyphTile(glyph: model.glyph)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(model.spec.name).lineLimit(1)
                        Text(model.summary)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                }
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
                .font(.system(size: 11, weight: .semibold))
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
