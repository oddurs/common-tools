import AppKit
import ImageIO
import ShotKit

/// The last few shots, as the PNGs that went to the clipboard, so the panel can offer them again.
/// Observable, so the panel follows a shot added, trashed or put back while it's open.
@MainActor @Observable
final class History {
    struct Shot: Identifiable, Equatable {
        let url: URL
        let date: Date
        let width: Int
        let height: Int
        /// The bundle identifier of the app the shot was taken from, when it was known.
        let app: String?

        var id: URL { url }
    }

    /// Newest first.
    private(set) var shots: [Shot] = []
    /// Each shot read at the size the panel draws it, so a 5K shot never sits in memory for a tile.
    private(set) var thumbnails: [URL: NSImage] = [:]
    let directory: URL

    static let standard = URL.applicationSupportDirectory.appending(
        path: "Common Shot/History", directoryHint: .isDirectory)

    /// Which app each shot came from, by file name. Beside the shots rather than in them, because the
    /// PNG also goes to the clipboard and on into chats, and the app it came from is nobody else's
    /// business. Hidden, so the folder in Finder shows only shots.
    private var index: URL { directory.appending(path: ".apps.json") }
    private var apps: [String: String] = [:]

    init(directory: URL = History.standard) {
        self.directory = directory
        reload()
    }

    /// Reads the folder again: its PNGs, newest first, and what the index says of them.
    func reload() {
        apps =
            (try? Data(contentsOf: index)).flatMap { try? JSONDecoder().decode([String: String].self, from: $0) } ?? [:]
        let urls =
            (try? FileManager.default.contentsOfDirectory(
                at: directory, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)) ?? []
        shots = urls.filter { $0.pathExtension == "png" }.compactMap { url in
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                let width = properties[kCGImagePropertyPixelWidth] as? Int,
                let height = properties[kCGImagePropertyPixelHeight] as? Int
            else { return nil }
            let date = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return Shot(url: url, date: date, width: width, height: height, app: apps[url.lastPathComponent])
        }
        .sorted { $0.date > $1.date }
    }

    /// Where the shot was kept, or nil when the history keeps none.
    @discardableResult
    func add(_ png: Data, width: Int, height: Int, at date: Date, app: String?, keeping limit: Int) throws -> URL? {
        guard limit > 0 else { return nil }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = FileName.unique(FileName.forShot(at: date)) {
            FileManager.default.fileExists(atPath: self.directory.appending(path: $0).path)
        }
        let url = directory.appending(path: name)
        try png.write(to: url, options: .withoutOverwriting)
        shots.insert(Shot(url: url, date: date, width: width, height: height, app: app), at: 0)
        if let app { apps[name] = app }
        try keep(limit)
        try saveIndex()
        return url
    }

    /// Deletes all but the newest `limit`.
    func keep(_ limit: Int) throws {
        guard shots.count > limit else { return }
        let overflow = shots[limit...]
        shots.removeLast(overflow.count)
        for shot in overflow {
            thumbnails[shot.url] = nil
            try FileManager.default.removeItem(at: shot.url)
        }
        try saveIndex()
    }

    func clear() throws {
        try keep(0)
    }

    /// Moves one shot to the Trash, where Finder can put it back too. Returns where it went, for `restore`.
    func trash(_ shot: Shot) throws -> URL? {
        var trashed: NSURL?
        try FileManager.default.trashItem(at: shot.url, resultingItemURL: &trashed)
        shots.removeAll { $0.url == shot.url }
        thumbnails[shot.url] = nil
        return trashed as URL?
    }

    /// Puts a trashed shot back where it was, with its date and app.
    func restore(_ shot: Shot, from trashed: URL) throws {
        try FileManager.default.moveItem(at: trashed, to: shot.url)
        shots.append(shot)
        shots.sort { $0.date > $1.date }
        if let app = shot.app { apps[shot.url.lastPathComponent] = app }
        try saveIndex()
    }

    /// The shot's thumbnail, fitting `side` points at `scale`, read off the main thread the first time.
    func loadThumbnail(for shot: Shot, fitting side: CGFloat, scale: CGFloat) async {
        guard thumbnails[shot.url] == nil else { return }
        let url = shot.url
        let pixels = side * scale
        let image = await Task.detached(priority: .userInitiated) { Self.thumbnail(of: url, pixels: pixels) }.value
        guard let image else { return }
        thumbnails[url] = NSImage(
            cgImage: image, size: NSSize(width: CGFloat(image.width) / scale, height: CGFloat(image.height) / scale))
    }

    /// Every thumbnail at once, on this thread, for `--render`, which draws before a task could run.
    func loadThumbnailsNow(fitting side: CGFloat, scale: CGFloat) {
        for shot in shots where thumbnails[shot.url] == nil {
            guard let image = Self.thumbnail(of: shot.url, pixels: side * scale) else { continue }
            thumbnails[shot.url] = NSImage(
                cgImage: image, size: NSSize(width: CGFloat(image.width) / scale, height: CGFloat(image.height) / scale)
            )
        }
    }

    nonisolated private static func thumbnail(of url: URL, pixels: CGFloat) -> CGImage? {
        let options =
            [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: pixels,
                kCGImageSourceCreateThumbnailWithTransform: true,
            ] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options)
    }

    private func saveIndex() throws {
        let kept = Set(shots.map(\.url.lastPathComponent))
        apps = apps.filter { kept.contains($0.key) }
        guard !apps.isEmpty || FileManager.default.fileExists(atPath: index.path) else { return }
        try JSONEncoder().encode(apps).write(to: index)
    }
}
