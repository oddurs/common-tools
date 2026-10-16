import AppKit
import GlyphKit
import Observation
import UniformTypeIdentifiers

/// The glyph as the menu bar shows it: one image per frame, already sized.
struct Glyph {
    let frames: [NSImage]
    let delays: [Double]
    let size: GlyphSize
    let isTemplate: Bool

    var isAnimated: Bool { frames.count > 1 }
}

/// One glyph: its spec, decoded source, and rendered frames. Every change to the spec re-renders off the
/// main thread; `GlyphLibrary` saves the spec.
@MainActor @Observable
final class GlyphModel: Identifiable {
    nonisolated let id: UUID
    var spec: GlyphSpec {
        didSet {
            guard spec != oldValue else { return }
            onSpecChange?()
            respond(to: oldValue)
        }
    }

    /// The current source turned and mirrored, as the crop editor shows it.
    private(set) var canvas: NSImage?
    private(set) var glyph: Glyph?
    /// Why the source couldn't be read, or why the last render fell short.
    var problem: String? { loadProblem ?? renderProblem }
    private var loadProblem: String?
    private var renderProblem: String?
    var isAnimated: Bool { frames.count > 1 }
    /// Whether the status item can be seen: false behind the camera housing, under a full-screen app, or
    /// pushed aside by a menu bar manager. Set by the status item.
    var isOnScreen = true

    var edit: Edit {
        get { spec.edit }
        set { spec.edit = newValue }
    }

    @ObservationIgnored var onSpecChange: (() -> Void)?
    /// Called on the main actor after every render.
    @ObservationIgnored var onRender: (() -> Void)?

    @ObservationIgnored private let folder: URL
    @ObservationIgnored private var frames: [Frame] = []
    /// Each source's decoded frames, keyed by what was decoded, so switching between a glyph's image and
    /// its text, or adopting an image already decoded, shows at once instead of after a fresh decode.
    @ObservationIgnored private var decoded: [SourceKind: (source: String, frames: [Frame])] = [:]
    @ObservationIgnored private var lift: Lift?
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var renderTask: Task<Void, Never>?

    init(spec: GlyphSpec, folder: URL) {
        id = spec.id
        self.spec = spec
        self.folder = folder
        reload()
    }

    var imageURL: URL? { spec.imageFile.map { folder.appending(path: $0) } }

    // MARK: Sources

    /// Copies the file in, so the glyph survives the original being moved or deleted.
    func importImage(at url: URL) async throws {
        let ext = url.pathExtension.isEmpty ? "png" : url.pathExtension.lowercased()
        let copy = try newImageFile(extension: ext)
        try FileManager.default.copyItem(at: url, to: copy)
        try await adopt(copy)
    }

    func importImage(data: Data, type: UTType) async throws {
        let copy = try newImageFile(extension: type.preferredFilenameExtension ?? "png")
        try data.write(to: copy)
        try await adopt(copy)
    }

    /// Takes the first image on the pasteboard: a file, then animated GIF data, then any still image.
    func importImage(from pasteboard: NSPasteboard) async throws {
        if let url =
            (pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])
            as? [URL])?.first
        {
            return try await importImage(at: url)
        }
        if let data = pasteboard.data(forType: NSPasteboard.PasteboardType(UTType.gif.identifier)) {
            return try await importImage(data: data, type: .gif)
        }
        if let data = pasteboard.data(forType: .png) {
            return try await importImage(data: data, type: .png)
        }
        if let image = NSImage(pasteboard: pasteboard), let tiff = image.tiffRepresentation,
            let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
        {
            return try await importImage(data: png, type: .png)
        }
        throw ImagingError.nothingToPaste
    }

    static func hasImage(_ pasteboard: NSPasteboard) -> Bool {
        pasteboard.canReadObject(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true, .urlReadingContentsConformToTypes: [UTType.image.identifier]])
            || NSImage.canInit(with: pasteboard)
    }

    private func newImageFile(extension ext: String) throws -> URL {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appending(path: "glyph-\(UUID().uuidString).\(ext)")
    }

    /// Decodes the copy before switching to it, so a file that isn't an image leaves the glyph alone.
    private func adopt(_ copy: URL) async throws {
        do {
            decoded[.image] = (copy.lastPathComponent, try await Self.decode(copy))
        } catch {
            // The decode error is the one worth reporting; a failed cleanup only leaves a stray file.
            try? FileManager.default.removeItem(at: copy)
            throw error
        }
        let old = imageURL
        spec.setImage(file: copy.lastPathComponent)
        // A copy that won't delete is only wasted space, and the new image is already in place.
        if let old { try? FileManager.default.removeItem(at: old) }
    }

    // MARK: Rendering

    private func respond(to old: GlyphSpec) {
        let sourceChanged =
            spec.kind != old.kind || (spec.kind == .text && spec.text != old.text)
            || (spec.kind == .image && spec.imageFile != old.imageFile)
        if sourceChanged { return reload() }
        let before = old.edit(for: spec.kind)
        guard spec.edit != before else { return }
        if spec.edit.quarterTurns != before.quarterTurns || spec.edit.flipped != before.flipped { updateCanvas() }
        render()
    }

    private func source(of kind: SourceKind) -> String {
        kind == .text ? spec.text : spec.imageFile ?? ""
    }

    private func reload() {
        loadTask?.cancel()
        let kind = spec.kind, source = source(of: kind), url = imageURL
        if let cached = decoded[kind], cached.source == source {
            return show(cached.frames, problem: nil)
        }
        loadTask = Task {
            var frames: [Frame] = []
            var problem: String?
            switch kind {
            case .text:
                frames = await Self.decode(text: source)
            case .image:
                guard let url else { break }
                do {
                    frames = try await Self.decode(url)
                } catch {
                    problem = error.localizedDescription
                }
            }
            guard !Task.isCancelled else { return }
            // A file that failed is read again next time, so its error shows again too.
            if problem == nil { decoded[kind] = (source, frames) }
            show(frames, problem: problem)
        }
    }

    /// Swaps in new frames, the editor's canvas, and, a moment later, the rendered glyph. The old glyph
    /// stays in the menu bar until then, so nothing flashes empty.
    private func show(_ frames: [Frame], problem: String?) {
        self.frames = frames
        loadProblem = problem
        lift = nil
        updateCanvas()
        render()
    }

    private func updateCanvas() {
        canvas = frames.first.flatMap { frame in
            let oriented = edit.oriented(frame.bitmap).fitting(maxSide: 640)
            return Imaging.image(
                from: oriented, size: NSSize(width: oriented.width, height: oriented.height), template: false)
        }
    }

    private func render() {
        renderTask?.cancel()
        let frames = frames, edit = edit, lift = lift
        let thickness = Double(NSStatusBar.system.thickness)
        renderTask = Task {
            // Coalesces the stream of changes a slider or crop drag sends.
            guard (try? await Task.sleep(for: .milliseconds(15))) != nil else { return }
            guard let result = await Self.render(frames, edit: edit, lift: lift), !Task.isCancelled else { return }
            self.lift = result.lift
            renderProblem = result.problem
            glyph = Self.glyph(from: result.frames, delays: frames.map(\.delay), edit: edit, thickness: thickness)
            onRender?()
        }
    }

    private static func glyph(from bitmaps: [Bitmap], delays: [Double], edit: Edit, thickness: Double) -> Glyph? {
        guard let first = bitmaps.first, bitmaps.contains(where: \.hasVisiblePixels) else { return nil }
        // Every frame shares the first one's size, so an animation doesn't jitter the menu bar.
        let size = GlyphSize(
            pixelWidth: first.width, pixelHeight: first.height, barThickness: thickness, scale: edit.scale)
        let points = NSSize(width: size.width, height: size.height)
        let frames = zip(bitmaps, delays).compactMap { bitmap, delay in
            Imaging.image(from: bitmap, size: points, template: edit.style.isTemplate).map { ($0, delay) }
        }
        guard !frames.isEmpty else { return nil }
        return Glyph(
            frames: frames.map(\.0), delays: frames.map(\.1), size: size, isTemplate: edit.style.isTemplate)
    }

    /// The subject lift for one framing, kept so changing only the style or size doesn't run Vision again.
    private struct Lift: Sendable {
        let turns: Int
        let flipped: Bool
        let crop: CropRect
        let frames: [Bitmap]

        func matches(_ edit: Edit) -> Bool {
            edit.quarterTurns == turns && edit.flipped == flipped && edit.crop == crop
        }
    }

    private struct Rendered: Sendable {
        let frames: [Bitmap]
        let lift: Lift?
        let problem: String?
    }

    /// Finished frames sit at most this many pixels tall: twice the tallest menu bar, so a Retina display
    /// is drawn from real pixels, with room to spare for scaling down.
    private nonisolated static let finishedSide = 160

    private nonisolated static func render(_ frames: [Frame], edit: Edit, lift: Lift?) async -> Rendered? {
        var lift = lift
        var problem: String?
        var framed = [Bitmap]()
        for frame in frames {
            guard !Task.isCancelled else { return nil }
            framed.append(edit.framed(frame.bitmap))
        }
        if edit.background == .subject {
            if let cached = lift, cached.matches(edit) {
                framed = cached.frames
            } else {
                do {
                    framed = try framed.map { try Imaging.liftingSubject($0) }
                    lift = Lift(turns: edit.quarterTurns, flipped: edit.flipped, crop: edit.crop, frames: framed)
                } catch {
                    problem = error.localizedDescription
                }
            }
        }
        guard !Task.isCancelled else { return nil }
        // Shrink before finishing, so background and style work on few pixels; trimming can then leave a
        // small glyph, so shrink again only after it.
        let finished = edit.finished(framed.map { $0.fitting(maxSide: finishedSide * 2) }).map {
            $0.fitting(maxSide: finishedSide)
        }
        return Rendered(frames: finished, lift: lift, problem: problem)
    }

    private nonisolated static func decode(_ url: URL) async throws -> [Frame] {
        try Imaging.frames(of: url)
    }

    private nonisolated static func decode(text: String) async -> [Frame] {
        Imaging.frames(ofText: text)
    }
}
