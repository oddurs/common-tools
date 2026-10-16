import Foundation
import GlyphKit
import Observation

/// Every glyph, in the order Settings lists them. Specs are saved together in UserDefaults; images live
/// in Application Support, one file per glyph.
@MainActor @Observable
final class GlyphLibrary {
    private static let key = "glyphs"

    private(set) var models: [GlyphModel] = []
    /// The glyph whose editor is open over Settings.
    var editing: UUID?
    /// Called when a glyph is added, removed, shown, or hidden.
    @ObservationIgnored var onChange: (() -> Void)?

    @ObservationIgnored let folder: URL
    @ObservationIgnored private let defaults = UserDefaults.standard

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        folder = support.appending(path: "Common Glyph", directoryHint: .isDirectory)
        var specs = [Library.starter()]
        if let data = defaults.data(forKey: Self.key) {
            do {
                specs = try JSONDecoder().decode([GlyphSpec].self, from: data)
            } catch {
                // Saved by a build with a different format. Keep the data aside rather than lose it.
                defaults.set(data, forKey: "\(Self.key).unreadable")
            }
        }
        models = Library.loaded(specs).map(makeModel)
    }

    var specs: [GlyphSpec] { models.map(\.spec) }
    var visible: [GlyphModel] { models.filter(\.spec.isVisible) }

    func model(_ id: UUID) -> GlyphModel? { models.first { $0.id == id } }

    func canHide(_ model: GlyphModel) -> Bool { Library.canHide(model.id, in: specs) }
    func canRemove(_ model: GlyphModel) -> Bool { Library.canRemove(model.id, from: specs) }

    @discardableResult
    func add() -> GlyphModel {
        insert(GlyphSpec(name: Library.freshName(taken: specs.map(\.name))), after: models.last)
    }

    @discardableResult
    func duplicate(_ model: GlyphModel) throws -> GlyphModel {
        var file: String?
        if let url = model.imageURL {
            let name = "glyph-\(UUID().uuidString).\(url.pathExtension)"
            try FileManager.default.copyItem(at: url, to: folder.appending(path: name))
            file = name
        }
        return insert(Library.duplicate(model.spec, among: specs, imageFile: file), after: model)
    }

    func remove(_ model: GlyphModel) {
        guard canRemove(model), let index = models.firstIndex(where: { $0.id == model.id }) else { return }
        models.remove(at: index)
        // Only wasted space if these linger; the glyph itself is already gone.
        if let url = model.imageURL { try? FileManager.default.removeItem(at: url) }
        defaults.removeObject(forKey: "NSStatusItem Preferred Position \(model.spec.autosaveName)")
        if editing == model.id { editing = nil }
        save()
        onChange?()
    }

    private func insert(_ spec: GlyphSpec, after neighbour: GlyphModel?) -> GlyphModel {
        let model = makeModel(spec)
        let index = neighbour.flatMap { n in models.firstIndex { $0.id == n.id } }.map { $0 + 1 } ?? models.count
        models.insert(model, at: index)
        editing = model.id
        save()
        onChange?()
        return model
    }

    private func makeModel(_ spec: GlyphSpec) -> GlyphModel {
        let model = GlyphModel(spec: spec, folder: folder)
        var visible = spec.isVisible
        model.onSpecChange = { [weak self, weak model] in
            guard let self, let model else { return }
            save()
            if model.spec.isVisible != visible {
                visible = model.spec.isVisible
                onChange?()
            }
        }
        return model
    }

    private func save() {
        // GlyphSpec is plain values; encoding it cannot fail.
        defaults.set(try! JSONEncoder().encode(specs), forKey: Self.key)
    }
}
