import Foundation

/// One glyph in the menu bar: its sources, the edit for each, and whether it shows. Each source kind
/// keeps its own edit, so switching between an image and text loses nothing.
public struct GlyphSpec: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var kind: SourceKind
    public var text: String
    /// The glyph's own copy of its image, named relative to the app's storage folder.
    public var imageFile: String?
    public var imageEdit: Edit
    public var textEdit: Edit
    public var isVisible: Bool

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        kind = .text
        text = SourceKind.initialText
        imageFile = nil
        imageEdit = Edit()
        textEdit = .text
        isVisible = true
    }

    public func edit(for kind: SourceKind) -> Edit {
        kind == .image ? imageEdit : textEdit
    }

    /// The edit for whichever source is showing.
    public var edit: Edit {
        get { edit(for: kind) }
        set {
            if kind == .image { imageEdit = newValue } else { textEdit = newValue }
        }
    }

    /// Switches to `newText`. Typing an emoji over plain text, or the reverse, also switches to the
    /// style that suits it; changing one emoji for another leaves a chosen style alone.
    public mutating func setText(_ newText: String) {
        guard newText != text else { return }
        let suggested = Style.suggested(forText: newText)
        if suggested != Style.suggested(forText: text) { textEdit.style = suggested }
        text = newText
        kind = .text
    }

    /// Switches to a new image, starting its edit afresh but keeping the size the glyph had.
    public mutating func setImage(file: String) {
        let scale = imageEdit.scale
        imageFile = file
        imageEdit = Edit()
        imageEdit.scale = scale
        kind = .image
    }

    /// The name macOS saves the status item's position under.
    public var autosaveName: String { "glyph-\(id.uuidString)" }
}

/// The rules for the list of glyphs, kept apart from the app so they can be tested.
public enum Library {
    public static let baseName = "Glyph"

    /// The first glyph, on first launch.
    public static func starter() -> GlyphSpec {
        GlyphSpec(name: baseName)
    }

    /// "Glyph", then "Glyph 2", "Glyph 3", skipping any name already in use.
    public static func freshName(_ base: String = baseName, taken: [String]) -> String {
        let used = Set(taken)
        guard used.contains(base) else { return base }
        var n = 2
        while used.contains("\(base) \(n)") { n += 1 }
        return "\(base) \(n)"
    }

    /// A copy under a new id and name. `imageFile` is the copy's own image, so deleting one glyph can't
    /// take the other's image with it.
    public static func duplicate(_ spec: GlyphSpec, among specs: [GlyphSpec], imageFile: String?) -> GlyphSpec {
        var copy = spec
        copy.id = UUID()
        copy.name = freshName("\(spec.name) copy", taken: specs.map(\.name))
        copy.imageFile = imageFile
        copy.isVisible = true
        return copy
    }

    /// At least one glyph stays in the menu bar, so its menu, and Settings, stay in reach.
    public static func canHide(_ id: UUID, in specs: [GlyphSpec]) -> Bool {
        specs.contains { $0.id != id && $0.isVisible }
    }

    /// Deleting follows the same rule, and the list is never left empty.
    public static func canRemove(_ id: UUID, from specs: [GlyphSpec]) -> Bool {
        guard let spec = specs.first(where: { $0.id == id }) else { return false }
        return specs.count > 1 && (!spec.isVisible || canHide(id, in: specs))
    }
}
