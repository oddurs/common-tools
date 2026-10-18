import AppKit
import ShotKit
import UniformTypeIdentifiers

/// Where a shot goes once it's a PNG: a file to drag, and the clipboard.
enum Output {
    /// A file for the preview to drag out when the history keeps none. One at a time: each replaces the last.
    nonisolated static func temporaryFile(_ png: Data, at date: Date) throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appending(path: "Common Shot", directoryHint: .isDirectory)
        try? FileManager.default.removeItem(at: folder)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appending(path: FileName.forShot(at: date))
        try png.write(to: url)
        return url
    }

    /// Plain text, for a shot read with ⌥.
    @MainActor static func copy(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// The PNG and the file it was saved to; `Clipboard` says which paste target reads which.
    @MainActor static func copy(_ png: Data, file: URL?) {
        Clipboard.write(png: png, file: file, to: .general)
    }
}
