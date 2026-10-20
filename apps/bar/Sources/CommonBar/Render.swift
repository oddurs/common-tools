import AppKit
import BarKit
import CommonUI
import SwiftUI

/// `CommonBar --render <folder>` draws the folder dropdown in every state, light and dark, offscreen,
/// so a change is judged from pictures. It shows nothing on screen, asks no app anything, and needs
/// no permission; the rows are made up, with apps that ship with macOS for their icons.
@MainActor
enum Render {
    static func run(into folder: URL) throws {
        _ = NSApplication.shared
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for (name, model) in states() {
            for (suffix, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
                let url = folder.appending(path: "dropdown-\(name)-\(suffix).png")
                try draw(MenuPanelSurface { FolderPanel(model: model) }, appearance: appearance, to: url)
            }
        }
        print("wrote \(states().count * 2) images to \(folder.path)")
    }

    private static let icons: [Int32: NSImage] = {
        let apps = [
            "/System/Applications/Mail.app", "/System/Applications/Music.app", "/System/Applications/Notes.app",
            "/System/Applications/Calendar.app", "/System/Applications/Messages.app", "/System/Applications/Photos.app",
            "/System/Applications/Reminders.app", "/System/Applications/Maps.app", "/System/Applications/Weather.app",
            "/System/Applications/Podcasts.app", "/System/Applications/Books.app", "/System/Applications/Stocks.app",
        ]
        var icons: [Int32: NSImage] = [:]
        for (i, path) in apps.enumerated() {
            let icon = NSWorkspace.shared.icon(forFile: path)
            icon.size = NSSize(width: 16, height: 16)
            icons[Int32(i + 1)] = icon
        }
        return icons
    }()

    private static func row(
        _ id: UInt32, _ name: String, pid: Int32, _ group: FolderGroup, status: String? = nil, symbol: String? = nil
    )
        -> FolderPanelModel.Row
    {
        FolderPanelModel.Row(id: id, name: name, status: status, symbol: symbol, pid: pid, group: group)
    }

    private static func model(_ rows: [FolderPanelModel.Row], folder: String = "More") -> FolderPanelModel {
        let model = FolderPanelModel()
        model.folderName = folder
        model.rows = rows
        model.icons = { icons[$0] }
        return model
    }

    private static let few = [
        row(1, "Mail", pid: 1, .apps), row(2, "Music", pid: 2, .apps), row(3, "Notes", pid: 3, .apps),
    ]

    private static let many =
        [
            row(1, "Mail", pid: 1, .apps), row(2, "Music", pid: 2, .apps), row(3, "Notes", pid: 3, .apps),
            row(4, "Calendar", pid: 4, .apps), row(5, "Messages", pid: 5, .apps), row(6, "Photos", pid: 6, .apps),
            row(7, "Reminders", pid: 7, .apps), row(8, "Maps", pid: 8, .apps), row(9, "Podcasts", pid: 10, .apps),
            row(10, "Weather", pid: 9, .commonTools), row(11, "Books", pid: 11, .commonTools),
        ] + [
            row(20, "Wi‑Fi", pid: 99, .system, status: "connected, 3 bars", symbol: "wifi"),
            row(21, "Battery", pid: 99, .system, status: "86%", symbol: "battery.100percent"),
            row(22, "Now Playing", pid: 99, .system, symbol: "play.circle"),
            row(23, "Focus", pid: 99, .system, symbol: "moon"),
            row(24, "Siri", pid: 98, .system, symbol: "waveform"),
        ]

    static func states() -> [(String, FolderPanelModel)] {
        let selected = model(many)
        selected.selection = Dropdown.Selection(index: 4)

        let filtering = model(many)
        filtering.type("ma")

        let noMatch = model(many)
        noMatch.type("zz")

        let busy = model(few)
        busy.busy = 2
        busy.selection = Dropdown.Selection(index: 1)

        let failed = model(few)
        failed.failure = (2, "Couldn't open Music")

        let copied = model(many)
        copied.copy = FolderPanelModel.Copy(
            title: "Music", pid: 2, symbol: nil,
            levels: [
                (
                    "Music",
                    MenuCopy.tidy(
                        [
                            MenuNode(title: "Play", key: "P"), MenuNode(title: "Next Track"),
                            MenuNode(title: "Previous Track"), .separator, MenuNode(title: "Shuffle", checked: true),
                            MenuNode(title: "Repeat", enabled: false),
                            MenuNode(title: "Playlists", children: [MenuNode(title: "Favourites")]), .separator,
                            MenuNode(title: "Open Music…"),
                        ].enumerated().map { ($0.element, $0.offset) }), []
                )
            ])
        copied.selection = Dropdown.Selection(index: 0)

        let empty = model([], folder: "Work")
        empty.notice = .empty("Nothing in this folder yet. Choose its icons in Settings.")

        let permission = model([])
        permission.notice = .permission(asked: false, waiting: 14)

        let askedBefore = model([])
        askedBefore.notice = .permission(asked: true, waiting: 14)

        return [
            ("few", model(few)), ("many", model(many)), ("selected", selected), ("filtering", filtering),
            ("no-match", noMatch), ("busy", busy), ("failed", failed), ("copied-menu", copied), ("empty", empty),
            ("permission", permission), ("permission-asked", askedBefore),
        ]
    }

    /// The view at 2x on a window of the given appearance, never shown.
    private static func draw<V: View>(_ view: V, appearance: NSAppearance.Name, to url: URL) throws {
        let host = NSHostingView(rootView: view.padding(Tokens.Space.lg).background(Tokens.Surface.base.color))
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: host.fittingSize), styleMask: .borderless, backing: .buffered,
            defer: false)
        window.appearance = NSAppearance(named: appearance)
        window.contentView = host
        window.setContentSize(host.fittingSize)
        host.layoutSubtreeIfNeeded()
        let scale: CGFloat = 2
        guard
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: Int(host.bounds.width * scale),
                pixelsHigh: Int(host.bounds.height * scale), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
        else { return }
        rep.size = host.bounds.size
        host.cacheDisplay(in: host.bounds, to: rep)
        try rep.representation(using: .png, properties: [:])?.write(to: url)
    }
}
