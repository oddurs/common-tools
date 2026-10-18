import AppKit

/// What a shot puts on the clipboard, so every place it's pasted finds something it reads.
public enum Clipboard {
    /// One item with two representations of the same shot:
    ///
    /// - `public.png`, the image itself. Claude Code reads it with Ctrl+V (natively, or through
    ///   AppleScript's `«class PNGf»`, which is this type), and so does any app that takes a pasted image.
    /// - `public.file-url`, the PNG on disk. A terminal pastes text, and with ⌘V Ghostty turns a file
    ///   URL into its escaped path, which Claude Code attaches as the image. Chromium-based apps, the
    ///   Claude desktop app among them, take the file in place of the image when both are there.
    ///
    /// No plain text: a path as text would land in every text field as a path.
    public static func write(png: Data, file: URL?, to pasteboard: NSPasteboard) {
        let item = NSPasteboardItem()
        item.setData(png, forType: .png)
        if let file, file.isFileURL {
            item.setString(file.absoluteString, forType: .fileURL)
        }
        pasteboard.clearContents()
        pasteboard.writeObjects([item])
    }
}
