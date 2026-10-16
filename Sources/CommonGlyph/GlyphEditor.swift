import GlyphKit
import SwiftUI

/// Everything about one glyph: a live preview, its name, its source, and how it's drawn.
struct GlyphEditor: View {
    @Bindable var model: GlyphModel
    let library: GlyphLibrary
    let delete: () -> Void
    @State private var importError: String?
    @FocusState private var editingText: Bool

    /// Ready-made glyphs that look at home in a menu bar, from symbols to kaomoji to emoji.
    private static let suggestions = ["✦", "☾", "☯", "♞", "⚘", "ᓚᘏᗢ", "(◕‿◕)", "( ˘ω˘ )", "👾", "🐈‍⬛", "🔥", "🌸"]

    var body: some View {
        Form {
            Section {
                MenuBarPreview(glyph: model.glyph, animates: model.edit.animates)
            }

            Section {
                TextField("Name", text: $model.spec.name)
                Toggle("Show in menu bar", isOn: $model.spec.isVisible)
                    .disabled(model.spec.isVisible && !library.canHide(model))
            } footer: {
                if model.spec.isVisible && !library.canHide(model) {
                    Text("One glyph always stays in the menu bar, so its menu stays in reach.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Picker("Source", selection: $model.kind) {
                    Label("Image", systemImage: "photo").tag(SourceKind.image)
                    Label("Emoji or text", systemImage: "textformat").tag(SourceKind.text)
                }
                .pickerStyle(.segmented)

                switch model.kind {
                case .image: imageControls
                case .text: textControls
                }
            } header: {
                Text("Source")
            } footer: {
                if let message = importError ?? model.problem {
                    Text(message).foregroundStyle(.red)
                }
            }

            Section {
                look
            } header: {
                Text("Look")
            } footer: {
                Text(Self.summary(of: model.edit.style))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Button("Duplicate") {
                        do {
                            try library.duplicate(model)
                        } catch {
                            importError = error.localizedDescription
                        }
                    }
                    Spacer()
                    Button("Delete Glyph…", role: .destructive, action: delete)
                        .disabled(!library.canRemove(model))
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(model.spec.name)
    }

    // MARK: Image

    @ViewBuilder private var imageControls: some View {
        Group {
            if let canvas = model.canvas {
                CropEditor(image: canvas, crop: $model.edit.crop)
                    .frame(height: 260)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "photo.badge.plus")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Drop an image here, or onto the glyph in the menu bar")
                    Text("A character, a tattoo design, a sticker, an animated GIF")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
                .background(
                    RoundedRectangle(cornerRadius: 10)
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
            if model.canvas != nil {
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
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
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

        if model.kind == .image {
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
