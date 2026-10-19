import AppKit
import CommonKit
import CommonUI
import CryptoKit
import SwiftUI

/// Draws each CommonUI primitive offscreen, in light and in dark, into `site/static/design/`, where the
/// site's design page shows them:
///
///     swift run --package-path packages/CommonKit DesignRender
///
/// Nothing appears on screen and nothing takes focus: each view is hosted in a window that is never
/// ordered in, as the apps' `--snapshot` modes do it. `renders.json` beside the images lists them with
/// the hash of the Swift sources they were drawn from; `DesignRenderTests` fails when a source changes
/// and nobody drew them again.
@main
@MainActor
enum DesignRender {
    nonisolated static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
    nonisolated static let output = root.appending(path: "site/static/design")
    nonisolated static let manifest = output.appending(path: "renders.json")
    nonisolated static let command = "swift run --package-path packages/CommonKit DesignRender"

    /// What the images show: every CommonUI file, the Common Tools section and the family it lists, and
    /// this renderer. Paths are relative to the repository, sorted, so the hash is the same on every Mac.
    nonisolated static func sources() throws -> [String] {
        let kit = "packages/CommonKit/Sources"
        let ui = try FileManager.default.contentsOfDirectory(atPath: root.appending(path: "\(kit)/CommonUI").path)
            .filter { $0.hasSuffix(".swift") }
            .map { "\(kit)/CommonUI/\($0)" }
        return
            (ui + [
                "\(kit)/CommonKit/CommonToolsSection.swift", "\(kit)/CommonKit/CommonTool.swift",
                "\(kit)/DesignRender/DesignRender.swift",
            ]).sorted()
    }

    /// SHA-256 over each source's path and contents, in order.
    nonisolated static func sourceHash() throws -> String {
        var hash = SHA256()
        for path in try sources() {
            hash.update(data: Data("\(path)\0".utf8))
            hash.update(data: try Data(contentsOf: root.appending(path: path)))
            hash.update(data: Data([0]))
        }
        return hash.finalize().map { String(format: "%02x", $0) }.joined()
    }

    struct Manifest: Codable, Equatable {
        struct Render: Codable, Equatable {
            /// The file stem: `<name>-light.png` and `<name>-dark.png`.
            var name: String
            /// Size in points; the images are drawn at 2x.
            var width: Int
            var height: Int
        }
        var command: String
        var sourceHash: String
        var renders: [Render]
    }

    static func main() throws {
        // Controls look up the app's appearance and accent, so there must be an app, though it never runs.
        _ = NSApplication.shared
        // CommonTool.icon reads the family icons from a CommonTools folder beside the executable, as
        // it does from an app bundle's resources.
        let icons = Bundle.main.bundleURL.appending(path: "CommonTools")
        if !FileManager.default.fileExists(atPath: icons.path) {
            try FileManager.default.copyItem(at: root.appending(path: "shared/CommonTools"), to: icons)
        }
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

        let renders = [
            try render("card") { CardExample().frame(width: Tokens.Layout.menuPanelWidth) },
            try render("icon-badge") { IconBadgeExample() },
            try render("labeled-row", padded: false) { LabeledRowExample() },
            try render("settings-footnote", padded: false) { FootnoteExample() },
            try render("settings", padded: false, titled: "Common UI Settings") { SettingsExample() },
            try render("menu-panel") { MenuPanelExample() },
        ]
        let data = try encoder.encode(Manifest(command: command, sourceHash: try sourceHash(), renders: renders))
        try (data + Data("\n".utf8)).write(to: manifest)
        print("wrote \(renders.count * 2) images and renders.json to \(output.path)")
    }

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }()

    /// Draws `view` once per appearance into `<name>-light.png` and `<name>-dark.png`. A primitive that
    /// sits in a window is drawn on the window's background; a form brings its own. `titled` draws the
    /// whole window, title bar included.
    static func render<V: View>(
        _ name: String, padded: Bool = true, titled title: String? = nil, @ViewBuilder _ view: () -> V
    ) throws -> Manifest.Render {
        var size = CGSize.zero
        for (suffix, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
            let content = view()
                .padding(padded ? Tokens.Space.lg : 0)
                .background(Tokens.Surface.base.color)
            let host = NSHostingView(rootView: content)
            let style: NSWindow.StyleMask = title == nil ? .borderless : [.titled, .closable]
            // Never shown: the window gives the view its appearance and lays it out.
            let window = NSWindow(
                contentRect: NSRect(origin: .zero, size: host.fittingSize), styleMask: style, backing: .buffered,
                defer: false)
            window.title = title ?? ""
            window.appearance = NSAppearance(named: appearance)
            window.contentView = host
            window.setContentSize(host.fittingSize)
            host.layoutSubtreeIfNeeded()
            // The frame view draws the title bar; the content view alone stops under it.
            let target = title == nil ? host : (host.superview ?? host)
            target.layoutSubtreeIfNeeded()
            size = target.bounds.size
            try write(target, to: output.appending(path: "\(name)-\(suffix).png"))
        }
        return Manifest.Render(name: name, width: Int(size.width.rounded()), height: Int(size.height.rounded()))
    }

    /// The view at 2x, whatever this Mac's screens are.
    static func write(_ view: NSView, to url: URL) throws {
        let scale: CGFloat = 2
        guard
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: Int(view.bounds.width * scale),
                pixelsHigh: Int(view.bounds.height * scale), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
        else { throw RenderError("could not allocate a bitmap for \(url.lastPathComponent)") }
        rep.size = view.bounds.size
        view.cacheDisplay(in: view.bounds, to: rep)
        guard let png = rep.representation(using: .png, properties: [:]) else {
            throw RenderError("could not encode \(url.lastPathComponent)")
        }
        try png.write(to: url)
    }

    struct RenderError: Error, CustomStringConvertible {
        let description: String
        init(_ description: String) { self.description = description }
    }
}

// MARK: - What each image shows

/// A card as Common Stats draws one in its menu.
private struct CardExample: View {
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                HStack {
                    Label("CPU", systemImage: "cpu").font(.headline)
                    Spacer()
                    Text("12%").font(.title3.monospacedDigit())
                }
                Text("Two of ten cores busy").font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}

/// The badge at its two sizes, in a few system tints.
private struct IconBadgeExample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            ForEach([20, 32] as [CGFloat], id: \.self) { size in
                HStack(spacing: Tokens.Space.sm) {
                    IconBadge(symbol: "cpu", tint: .blue, size: size)
                    IconBadge(symbol: "keyboard", tint: .indigo, size: size)
                    IconBadge(symbol: "battery.75percent", tint: .green, size: size)
                    IconBadge(symbol: "eyedropper", tint: .orange, size: size)
                    IconBadge(symbol: "camera.viewfinder", tint: .pink, size: size)
                }
            }
        }
    }
}

/// The row's three shapes: icon, title, subtitle and action; a title and a control; a dimmed title.
private struct LabeledRowExample: View {
    var body: some View {
        Form {
            Section {
                LabeledRow("Common Stats", subtitle: "System stats in the menu bar") {
                    IconBadge(symbol: "cpu", tint: .blue, size: 32)
                } trailing: {
                    Button("Open") {}
                }
                LabeledRow("Take a screenshot") { Text("⇧⌘2").foregroundStyle(.secondary) }
                LabeledRow(Text("Hidden items").foregroundStyle(.secondary), subtitle: "3 icons", leadingSize: 20) {
                    IconBadge(symbol: "eye.slash", tint: .gray)
                }
            }
        }
        .settingsForm()
    }
}

/// A footer in each tone: secondary, with a symbol, and in the danger colour.
private struct FootnoteExample: View {
    var body: some View {
        Form {
            Section {
                Toggle("Show labels", isOn: .constant(true))
            } footer: {
                VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                    SettingsFootnote("Kept on this Mac only.")
                    SettingsFootnote("Can’t be seen in the menu bar.", symbol: "eye.slash")
                    SettingsFootnote("The login item could not be registered.", tone: .danger)
                }
            }
        }
        .settingsForm()
    }
}

/// A menu bar panel as Common Shot opens one: menu rows around a card holding a group of tiles under
/// its header, the second tile selected as the keyboard leaves it.
private struct MenuPanelExample: View {
    var body: some View {
        MenuPanelSurface {
            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                MenuRow("Take Screenshot", symbol: "camera.viewfinder", shortcut: "⇧⌘2") {}
                Card {
                    VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                        SectionHeader("Today", detail: "2 shots")
                        HStack(alignment: .top, spacing: Tokens.Space.xs) {
                            ThumbnailTile(
                                image: Self.picture(.systemIndigo, .systemTeal), title: "2:30 PM",
                                subtitle: "1280 × 800 · ≈ 1.4k tokens"
                            ) { Image(systemName: "terminal").foregroundStyle(.secondary) }
                            ThumbnailTile(
                                image: Self.picture(.systemOrange, .systemPink), title: "1:05 PM",
                                subtitle: "640 × 900 · ≈ 768 tokens", aspect: 16 / 10, isSelected: true
                            ) { Image(systemName: "safari").foregroundStyle(.secondary) }
                        }
                    }
                }
                Divider().padding(.horizontal, Tokens.Space.xs)
                MenuRow("Settings…", symbol: "gearshape", shortcut: "⌘,") {}
            }
        }
    }

    /// A stand-in for a shot: a diagonal wash between two system colours.
    static func picture(_ from: NSColor, _ to: NSColor) -> Image {
        let size = NSSize(width: 160, height: 100)
        let image = NSImage(size: size, flipped: false) { rect in
            NSGradient(starting: from, ending: to)?.draw(in: rect, angle: 30)
            return true
        }
        return Image(nsImage: image)
    }
}

/// A Settings window laid out as every app's is: the app's own sections, General opening with Open
/// at login, and the Common Tools section last.
private struct SettingsExample: View {
    @State private var loginProblem: LoginItem.Problem?

    var body: some View {
        Form {
            Section("Appearance") {
                Toggle("Show labels", isOn: .constant(true))
                LabeledRow("Take a screenshot") { Text("⇧⌘2").foregroundStyle(.secondary) }
            }
            Section {
                OpenAtLoginToggle(problem: $loginProblem)
            } header: {
                Text("General")
            } footer: {
                OpenAtLoginFootnote(loginProblem)
            }
            CommonToolsSection()
        }
        .settingsForm()
    }
}
