import AppKit
import Testing

@testable import ShotKit

/// Read back the way each paste target reads, from a private pasteboard so the real clipboard is
/// never touched.
@Suite struct ClipboardTests {
    let png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3])
    let file = URL(fileURLWithPath: "/tmp/Common Shot 2026-10-17 at 21.29.16.png")

    private func withPasteboard(_ body: (NSPasteboard) throws -> Void) rethrows {
        let pasteboard = NSPasteboard(name: .init("com.oddurs.commonshot.tests.\(UUID().uuidString)"))
        defer { pasteboard.releaseGlobally() }
        try body(pasteboard)
    }

    @Test func imageReadersGetThePNG() {
        withPasteboard { pasteboard in
            Clipboard.write(png: png, file: file, to: pasteboard)
            // Claude Code and AppleScript's «class PNGf» read this type.
            #expect(pasteboard.data(forType: .png) == png)
        }
    }

    /// Ghostty pastes with ⌘V from `propertyList(forType: .fileURL)` on each item; without it a
    /// shot pasted nothing there.
    @Test func terminalsGetThePath() throws {
        try withPasteboard { pasteboard in
            Clipboard.write(png: png, file: file, to: pasteboard)
            let item = try #require(pasteboard.pasteboardItems?.first)
            let plist = try #require(item.propertyList(forType: .fileURL))
            let url = try #require(NSURL(pasteboardPropertyList: plist, ofType: .fileURL) as URL?)
            #expect(url.isFileURL)
            #expect(url.path == file.path)
        }
    }

    /// Chromium reads files as NSURLs, and prefers them over the image.
    @Test func browsersGetTheFile() {
        withPasteboard { pasteboard in
            Clipboard.write(png: png, file: file, to: pasteboard)
            let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])
            #expect((urls as? [URL])?.map(\.path) == [file.path])
        }
    }

    @Test func oneItemAndNoText() {
        withPasteboard { pasteboard in
            Clipboard.write(png: png, file: file, to: pasteboard)
            #expect(pasteboard.pasteboardItems?.count == 1)
            #expect(pasteboard.string(forType: .string) == nil)
        }
    }

    @Test func withoutAFileOnlyThePNG() {
        withPasteboard { pasteboard in
            Clipboard.write(png: png, file: nil, to: pasteboard)
            #expect(pasteboard.data(forType: .png) == png)
            #expect(pasteboard.types?.contains(.fileURL) == false)
        }
    }

    @Test func replacesWhatWasThere() {
        withPasteboard { pasteboard in
            pasteboard.clearContents()
            pasteboard.setString("old", forType: .string)
            Clipboard.write(png: png, file: file, to: pasteboard)
            #expect(pasteboard.string(forType: .string) == nil)
        }
    }
}
