import AppKit
import ImageIO
import ShotKit

/// The last few shots, as the PNGs that went to the clipboard, so the menu can offer them again.
@MainActor
final class History {
    struct Shot {
        let url: URL
        let date: Date
        let width: Int
        let height: Int
    }

    /// Newest first.
    private(set) var shots: [Shot] = []
    private var thumbnails: [URL: NSImage] = [:]

    static let directory = URL.applicationSupportDirectory.appending(
        path: "Common Shot/History", directoryHint: .isDirectory)

    init() {
        let urls =
            (try? FileManager.default.contentsOfDirectory(
                at: Self.directory, includingPropertiesForKeys: [.creationDateKey])) ?? []
        shots = urls.filter { $0.pathExtension == "png" }.compactMap { url in
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                let width = properties[kCGImagePropertyPixelWidth] as? Int,
                let height = properties[kCGImagePropertyPixelHeight] as? Int
            else { return nil }
            let date = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return Shot(url: url, date: date, width: width, height: height)
        }
        .sorted { $0.date > $1.date }
    }

    /// Where the shot was kept, or nil when the history keeps none.
    @discardableResult
    func add(_ png: Data, width: Int, height: Int, at date: Date, keeping limit: Int) throws -> URL? {
        guard limit > 0 else { return nil }
        try FileManager.default.createDirectory(at: Self.directory, withIntermediateDirectories: true)
        let name = FileName.unique(FileName.forShot(at: date)) {
            FileManager.default.fileExists(atPath: Self.directory.appending(path: $0).path)
        }
        let url = Self.directory.appending(path: name)
        try png.write(to: url, options: .withoutOverwriting)
        shots.insert(Shot(url: url, date: date, width: width, height: height), at: 0)
        try keep(limit)
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
    }

    func clear() throws {
        try keep(0)
    }

    /// Read at the size the menu draws it, so a 5K shot doesn't sit in memory for a 200-point row.
    func thumbnail(for shot: Shot, fitting side: CGFloat, scale: CGFloat) -> NSImage? {
        if let cached = thumbnails[shot.url] { return cached }
        let options =
            [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: side * scale,
                kCGImageSourceCreateThumbnailWithTransform: true,
            ] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(shot.url as CFURL, nil),
            let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options)
        else { return nil }
        let thumbnail = NSImage(
            cgImage: image, size: NSSize(width: CGFloat(image.width) / scale, height: CGFloat(image.height) / scale))
        thumbnails[shot.url] = thumbnail
        return thumbnail
    }
}
