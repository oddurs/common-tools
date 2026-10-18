import AppKit
import ColorKit
import CommonUI
import SwiftUI

/// `CommonColor --snapshot out.png` writes the menu's panel, light and dark, in three states: a
/// full history with a blue picked over a dark grey, a Display P3 green that sRGB can't hold, and
/// no picks yet. Rendered offscreen, so nothing appears and no permission is needed.
@MainActor
enum SnapshotCommand {
    static func run(path: String) {
        func srgb(_ hex: UInt32) -> ColorValue {
            ColorValue(
                .sRGB, red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255,
                blue: Double(hex & 0xff) / 255)
        }
        var full = History()
        for hex: UInt32 in [
            0xf4f1ea, 0xd94f30, 0xf2b134, 0x4f9d69, 0x0e7c86, 0x6b4c9a, 0xffffff, 0x000000, 0x777777, 0xe8e0ff,
            0x1d1d1f, 0x3a7bd5,
        ] {
            full.add(srgb(hex))
        }
        var wide = History()
        wide.add(srgb(0xffffff))
        wide.add(ColorValue(.displayP3, red: 0.1, green: 0.85, blue: 0.2))

        func menu(_ scheme: ColorScheme) -> some View {
            VStack(alignment: .leading, spacing: Tokens.Space.sm) {
                ColorPanel(history: full, format: .hex, shortcut: "⌃⇧⌘C")
                ColorPanel(history: wide, format: .oklch, shortcut: "⌃⇧⌘C")
                ColorPanel(history: History(), format: .hex, shortcut: "⌃⇧⌘C")
            }
            .padding(.vertical, Tokens.Space.xs)
            .background(Tokens.Surface.base.color, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg))
            .environment(\.colorScheme, scheme)
        }
        let renderer = ImageRenderer(
            content: HStack(alignment: .top, spacing: Tokens.Space.lg) {
                menu(.light)
                menu(.dark)
            }
            .padding(Tokens.Space.lg))
        renderer.scale = 2
        guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
            let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
        else { fatalError("could not render the menu") }
        do {
            try png.write(to: URL(fileURLWithPath: path))
        } catch {
            FileHandle.standardError.write(Data("common-color: \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }
}
