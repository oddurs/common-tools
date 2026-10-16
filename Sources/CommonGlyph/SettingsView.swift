import GlyphKit
import SwiftUI

/// A sidebar of glyphs beside the selected glyph's editor. The app-wide settings sit in General, laid out
/// by the Common Tools standard so every app's settings end the same way.
struct SettingsView: View {
    @Bindable var library: GlyphLibrary
    @State private var pendingDelete: GlyphModel?
    @State private var error: String?

    var body: some View {
        NavigationSplitView {
            List(selection: $library.selection) {
                Section("Glyphs") {
                    ForEach(library.models) { model in
                        GlyphRow(model: model)
                            .tag(Pane.glyph(model.id))
                            .contextMenu { actions(for: model) }
                    }
                }
                Section {
                    Label("General", systemImage: "gearshape")
                        .tag(Pane.general)
                }
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 280)
            .safeAreaInset(edge: .bottom, spacing: 0) { listButtons }
        } detail: {
            switch library.selection {
            case .glyph(let id):
                if let model = library.model(id) {
                    GlyphEditor(model: model, library: library, delete: { pendingDelete = model })
                        .id(id)
                }
            case .general, nil:
                GeneralPane()
            }
        }
        .frame(minWidth: 760, minHeight: 620)
        .confirmationDialog(
            "Delete “\(pendingDelete?.spec.name ?? "")”?", isPresented: .constant(pendingDelete != nil),
            presenting: pendingDelete
        ) { model in
            Button("Delete", role: .destructive) {
                library.remove(model)
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: { _ in
            Text("It leaves the menu bar, and its copy of the image is deleted.")
        }
        .alert("Couldn't duplicate the glyph", isPresented: .constant(error != nil)) {
            Button("OK") { error = nil }
        } message: {
            Text(error ?? "")
        }
    }

    @ViewBuilder private func actions(for model: GlyphModel) -> some View {
        Button("Duplicate") { duplicate(model) }
        if model.spec.isVisible {
            Button("Hide from Menu Bar") { model.spec.isVisible = false }
                .disabled(!library.canHide(model))
        } else {
            Button("Show in Menu Bar") { model.spec.isVisible = true }
        }
        Divider()
        Button("Delete…", role: .destructive) { pendingDelete = model }
            .disabled(!library.canRemove(model))
    }

    private var selectedModel: GlyphModel? {
        if case .glyph(let id) = library.selection { library.model(id) } else { nil }
    }

    /// The + and − under the list, as in System Settings.
    private var listButtons: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 2) {
                Button {
                    library.add()
                } label: {
                    Image(systemName: "plus").frame(width: 24, height: 20)
                }
                .help("New glyph")
                Button {
                    pendingDelete = selectedModel
                } label: {
                    Image(systemName: "minus").frame(width: 24, height: 20)
                }
                .help("Delete the selected glyph")
                .disabled(selectedModel.map { !library.canRemove($0) } ?? true)
                Spacer()
            }
            .buttonStyle(.borderless)
            .padding(6)
        }
    }

    private func duplicate(_ model: GlyphModel) {
        do {
            try library.duplicate(model)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

/// A glyph in the sidebar: its look, small, and its name.
private struct GlyphRow: View {
    let model: GlyphModel

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if let image = model.glyph?.frames.first {
                    Image(nsImage: image)
                        .renderingMode(model.glyph?.isTemplate == true ? .template : .original)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "sparkle")
                }
            }
            .frame(width: 34, height: 18)
            Text(model.spec.name)
                .lineLimit(1)
            Spacer(minLength: 0)
            if !model.spec.isVisible {
                Image(systemName: "eye.slash")
                    .foregroundStyle(.secondary)
                    .help("Hidden from the menu bar")
            }
        }
        .opacity(model.spec.isVisible ? 1 : 0.55)
    }
}

/// App-wide settings, then the Common Tools family.
private struct GeneralPane: View {
    @State private var openAtLogin = LoginItem.isEnabled
    @State private var loginError: String?

    var body: some View {
        Form {
            Section {
                Toggle("Open at login", isOn: $openAtLogin)
            } header: {
                Text("General")
            } footer: {
                if let loginError {
                    Text(loginError).foregroundStyle(.secondary)
                }
            }

            Section {
                Label("Hold ⌘ and drag a glyph to move it along the menu bar.", systemImage: "command")
                Label(
                    "Drop an image from Finder onto a glyph to replace its image.", systemImage: "square.and.arrow.down"
                )
                Label(
                    "Click a glyph for its menu, or open Common Glyph again for this window.",
                    systemImage: "cursorarrow.click")
            } header: {
                Text("In the Menu Bar")
            }

            CommonToolsSection()
        }
        .formStyle(.grouped)
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
}
