import AppKit
import ColorKit
import CommonKit
import CommonUI
import SwiftUI

/// `CommonColor --snapshot <folder>` draws every state of the panel, the copy confirmation, and
/// Settings, light and dark, into `<folder>`, and the full panel light beside dark as `menu.png`, the
/// image `docs/menu.png` holds. Each view is hosted in a window that is never shown, as DesignRender
/// does, so AppKit controls draw as they really do, nothing appears on screen, and no permission is
/// needed. `-contrast` images use the Increase Contrast appearances.
@MainActor
enum SnapshotCommand {
    static func run(folder: String) {
        let folder = URL(fileURLWithPath: folder)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try renderAll(into: folder)
            try sideBySide(
                folder.appending(path: "panel-full-light.png"), folder.appending(path: "panel-full-dark.png"),
                to: folder.appending(path: "menu.png"))
        } catch {
            FileHandle.standardError.write(Data("common-color: \(error)\n".utf8))
            exit(1)
        }
    }

    private static func renderAll(into folder: URL) throws {
        func panel(_ history: History, format: ColorFormat = .hex, allFormats: Bool = false, selection: Int? = nil)
            -> some View
        {
            MenuPanelSurface {
                ColorPanel(
                    picks: Picks(history), format: format, showsAllFormats: .constant(allFormats),
                    shortcut: "⌃⇧⌘C", selection: selection)
            }
        }
        let s = Samples.self
        try render("panel-empty", into: folder) { panel(History()) }
        try render("panel-one", into: folder) { panel(s.one) }
        try render("panel-full", into: folder, contrast: true) { panel(s.full) }
        // Every format, for a pick three back that the arrow keys have reached.
        try render("panel-formats", into: folder) { panel(s.full, allFormats: true, selection: 3) }
        try render("panel-gamut", into: folder, contrast: true) { panel(s.wide, format: .oklch, allFormats: true) }
        try render("confirmation", into: folder, contrast: true) {
            VStack(alignment: .leading, spacing: Tokens.Space.sm) {
                CopyConfirmation(format: .hex, color: s.blue)
                CopyConfirmation(format: .swiftUI, color: s.blue)
                CopyConfirmation(format: .hex, color: s.green)
            }
            .padding(Tokens.Space.lg)
            .background(Tokens.Surface.base.color)
        }
        let defaults = UserDefaults(suiteName: "CommonColorSnapshot")!
        defaults.removePersistentDomain(forName: "CommonColorSnapshot")
        let color = CommonTool.all.first { $0.id == "color" }!
        try render("settings", into: folder, titled: "Common Color Settings") {
            SettingsView(preferences: Preferences(defaults: defaults), updates: UpdateCheck(tool: color))
        }
    }

    /// `<name>-light.png` and `<name>-dark.png` at 2x, and with `contrast`, `<name>-contrast-light.png`
    /// and `-contrast-dark.png` in the Increase Contrast appearances.
    static func render<V: View>(
        _ name: String, into folder: URL, titled title: String? = nil, contrast: Bool = false,
        @ViewBuilder _ view: () -> V
    ) throws {
        var appearances: [(String, NSAppearance.Name)] = [("light", .aqua), ("dark", .darkAqua)]
        if contrast {
            appearances += [
                ("contrast-light", .accessibilityHighContrastAqua),
                ("contrast-dark", .accessibilityHighContrastDarkAqua),
            ]
        }
        for (suffix, appearance) in appearances {
            let host = NSHostingView(rootView: view())
            let window = NSWindow(
                contentRect: NSRect(origin: .zero, size: host.fittingSize),
                styleMask: title == nil ? .borderless : [.titled, .closable], backing: .buffered, defer: false)
            window.title = title ?? ""
            if title == nil {
                // Around the panel's rounded corners, nothing.
                window.isOpaque = false
                window.backgroundColor = .clear
            }
            window.appearance = NSAppearance(named: appearance)
            window.contentView = host
            window.setContentSize(host.fittingSize)
            let target = title == nil ? host : (host.superview ?? host)
            target.layoutSubtreeIfNeeded()
            try write(target, to: folder.appending(path: "\(name)-\(suffix).png"))
        }
    }

    static func write(_ view: NSView, to url: URL) throws {
        let scale: CGFloat = 2
        guard
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: Int(view.bounds.width * scale),
                pixelsHigh: Int(view.bounds.height * scale), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
        else { throw CocoaError(.fileWriteUnknown) }
        rep.size = view.bounds.size
        view.cacheDisplay(in: view.bounds, to: rep)
        guard let png = rep.representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
        try png.write(to: url)
    }

    /// Two renders beside each other on a clear ground, a gap between, top edges aligned.
    private static func sideBySide(_ left: URL, _ right: URL, to url: URL) throws {
        guard let a = NSBitmapImageRep(data: try Data(contentsOf: left)),
            let b = NSBitmapImageRep(data: try Data(contentsOf: right))
        else { throw CocoaError(.fileReadCorruptFile) }
        let gap = 48
        let size = NSSize(width: a.pixelsWide + gap + b.pixelsWide, height: max(a.pixelsHigh, b.pixelsHigh))
        let image = NSImage(size: size, flipped: false) { _ in
            a.draw(
                in: NSRect(
                    x: 0, y: size.height - CGFloat(a.pixelsHigh), width: CGFloat(a.pixelsWide),
                    height: CGFloat(a.pixelsHigh)))
            b.draw(
                in: NSRect(
                    x: CGFloat(a.pixelsWide + gap), y: size.height - CGFloat(b.pixelsHigh),
                    width: CGFloat(b.pixelsWide),
                    height: CGFloat(b.pixelsHigh)))
            return true
        }
        guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
            let png = rep.representation(using: .png, properties: [:])
        else { throw CocoaError(.fileWriteUnknown) }
        try png.write(to: url)
    }
}

/// The picks every render shows, so the images never depend on what this Mac has picked.
enum Samples {
    static func srgb(_ hex: UInt32) -> ColorValue {
        ColorValue(
            .sRGB, red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255)
    }

    static let blue = srgb(0x3a7bd5)
    static let green = ColorValue(.displayP3, red: 0.1, green: 0.85, blue: 0.2)

    static let one: History = {
        var history = History()
        history.add(blue)
        return history
    }()

    /// Twelve picks, the newest a blue over a near-white, so the contrast card has something to say.
    static let full: History = {
        var history = History()
        for hex: UInt32 in [
            0xf4f1ea, 0xd94f30, 0xf2b134, 0x4f9d69, 0x0e7c86, 0x6b4c9a, 0xffffff, 0x000000, 0x777777, 0xe8e0ff,
            0xfafafa,
        ] {
            history.add(srgb(hex))
        }
        history.add(blue)
        return history
    }()

    /// A Display P3 green, which sRGB can't hold, picked over white.
    static let wide: History = {
        var history = History()
        history.add(srgb(0xffffff))
        history.add(green)
        return history
    }()
}
