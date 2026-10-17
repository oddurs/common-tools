import CommonUI
import GlyphKit
import SwiftUI

/// Everything about one glyph, as a sheet over Settings: a live preview, its name, its source, and how
/// it's drawn.
struct GlyphEditor: View {
    @Bindable var model: GlyphModel
    let library: GlyphLibrary
    @Environment(\.dismiss) private var dismiss
    @State private var importError: String?
    @State private var confirmingDelete = false
    /// The source being edited. It runs ahead of the glyph's own kind while an image glyph has no image
    /// yet, so the menu bar keeps the text instead of a placeholder.
    @State private var pane: SourceKind
    @FocusState private var editingText: Bool

    init(model: GlyphModel, library: GlyphLibrary) {
        self.model = model
        self.library = library
        _pane = State(initialValue: model.spec.kind)
    }

    private var awaitingImage: Bool { pane == .image && model.spec.imageFile == nil }

    /// Ready-made glyphs that look at home in a menu bar, from symbols to kaomoji to emoji.
    private static let suggestions = ["✦", "☾", "☯", "♞", "⚘", "ᓚᘏᗢ", "(◕‿◕)", "( ˘ω˘ )", "👾", "🐈‍⬛", "🔥", "🌸"]

    var body: some View {
        VStack(spacing: 0) {
            form
            Divider()
            HStack {
                Button("Delete Glyph…", role: .destructive) { confirmingDelete = true }
                    .disabled(!library.canRemove(model))
                Spacer()
                Button("Duplicate") {
                    do {
                        try library.duplicate(model)
                    } catch {
                        importError = error.localizedDescription
                    }
                }
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(Tokens.Space.md)
        }
        .frame(width: Tokens.Layout.settingsWidth, height: 660)
        .confirmationDialog("Delete “\(model.spec.name)”?", isPresented: $confirmingDelete) {
            Button("Delete", role: .destructive) { library.remove(model) }
        } message: {
            Text("It leaves the menu bar, and its copy of the image is deleted.")
        }
        .onChange(of: pane) { _, kind in model.spec.show(kind) }
        .onChange(of: model.spec.kind) { _, kind in pane = kind }
    }

    private var form: some View {
        Form {
            Section {
                MenuBarPreview(models: [model])
            }

            Section {
                TextField("Name", text: $model.spec.name)
                Toggle("Show in menu bar", isOn: $model.spec.isVisible)
                    .disabled(model.spec.isVisible && !library.canHide(model))
            } footer: {
                if model.spec.isVisible && !library.canHide(model) {
                    SettingsFootnote("One glyph always stays in the menu bar, so its menu stays in reach.")
                }
            }

            Section {
                Picker("Source", selection: $pane) {
                    Label("Image", systemImage: "photo").tag(SourceKind.image)
                    Label("Emoji or text", systemImage: "textformat").tag(SourceKind.text)
                }
                .pickerStyle(.segmented)

                switch pane {
                case .image: imageControls
                case .text: textControls
                }
            } header: {
                Text("Source")
            } footer: {
                if let message = importError ?? model.problem {
                    Text(message).font(.callout).foregroundStyle(Tokens.Color.danger.color)
                }
            }

            // Nothing to style until there's an image.
            if !awaitingImage {
                Section {
                    look
                } header: {
                    Text("Look")
                } footer: {
                    SettingsFootnote(Self.summary(of: model.edit.style))
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Image

    @ViewBuilder private var imageControls: some View {
        Group {
            if !awaitingImage, let canvas = model.canvas {
                CropEditor(image: canvas, crop: $model.edit.crop)
                    .frame(height: 260)
            } else {
                VStack(spacing: Tokens.Space.xxs) {
                    Image(systemName: "photo.badge.plus")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Drop an image here, or onto the glyph in the menu bar")
                    Text("A character, a tattoo design, a sticker, an animated GIF")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                // The crop editor's height, so the sheet doesn't jump when the image arrives.
                .frame(maxWidth: .infinity, minHeight: 260)
                .background(
                    RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        .foregroundStyle(.tertiary))
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first(where: \.isFileURL) else { return false }
            importImage { try await model.importImage(at: url) }
            return true
        }

        HStack {
            Button("Choose…", action: chooseImage)
            Button("Paste") { importImage { try await model.importImage(from: .general) } }
            Spacer()
            if !awaitingImage && model.canvas != nil {
                Button {
                    model.edit.rotateClockwise()
                } label: {
                    Image(systemName: "rotate.right")
                }
                .help("Rotate a quarter turn clockwise")
                Button {
                    model.edit.flip()
                } label: {
                    Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                }
                .help("Flip horizontally")
                Button("Reset") { model.edit.resetFraming() }
                    .disabled(model.edit.quarterTurns == 0 && !model.edit.flipped && model.edit.crop.isFull)
                    .help("Show the whole image, the right way up")
            }
        }
    }

    private func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image, .pdf]
        panel.message = "Choose an image for “\(model.spec.name)”"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        importImage { try await model.importImage(at: url) }
    }

    private func importImage(_ work: @escaping @MainActor () async throws -> Void) {
        Task {
            do {
                try await work()
                importError = nil
            } catch {
                importError = error.localizedDescription
            }
        }
    }

    // MARK: Text

    @ViewBuilder private var textControls: some View {
        HStack {
            TextField(
                "Text", text: Binding(get: { model.spec.text }, set: { model.spec.setText($0) }),
                prompt: Text("Emoji, a symbol, or a word")
            )
            .font(.title3)
            .focused($editingText)
            Button {
                editingText = true
                // The palette types into whatever has focus, so give the field a moment to take it.
                DispatchQueue.main.async { NSApp.orderFrontCharacterPalette(nil) }
            } label: {
                Image(systemName: "face.smiling")
            }
            .help("Emoji & Symbols (⌃⌘Space)")
        }
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: Tokens.Space.xxs), count: 6),
            spacing: Tokens.Space.xxs
        ) {
            ForEach(Self.suggestions, id: \.self) { suggestion in
                Button {
                    model.spec.setText(suggestion)
                } label: {
                    Text(suggestion)
                        .font(.title3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity, minHeight: 26)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: Look

    @ViewBuilder private var look: some View {
        Picker("Style", selection: $model.edit.style) {
            Text("Colour").tag(Style.color)
            Text("Silhouette").tag(Style.silhouette)
            Text("Ink").tag(Style.ink)
        }
        .pickerStyle(.segmented)

        if model.edit.style == .ink {
            Slider(value: $model.edit.threshold, in: 0.05...0.95) { Text("Threshold") }
            Toggle("Use the light parts", isOn: $model.edit.inverted)
        }

        if model.spec.kind == .image {
            Picker("Background", selection: $model.edit.background) {
                Text("Keep").tag(Background.keep)
                Text("Remove solid colour").tag(Background.solid)
                Text("Lift subject").tag(Background.subject)
            }
            if model.edit.background == .solid {
                Slider(value: $model.edit.tolerance, in: 0.02...0.5) { Text("Tolerance") }
            }
        }

        Slider(value: $model.edit.scale, in: GlyphSize.scaleRange) { Text("Size") }

        if model.isAnimated {
            Toggle("Animate", isOn: $model.edit.animates)
        }
    }

    private static func summary(of style: Style) -> String {
        switch style {
        case .color: "Drawn in the image's own colours."
        case .silhouette: "The image's outline, tinted to match the menu bar like the system's own icons."
        case .ink: "The image's dark lines, tinted to match the menu bar. Suits line art and tattoo designs."
        }
    }
}
