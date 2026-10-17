import AppKit
import CommonKit
import CommonUI
import ShotKit

/// Wires the shortcut, the overlay, the menu bar item, and Settings together, and sends each shot to
/// the clipboard.
@MainActor
final class AppController: NSObject {
    private static let onboardedKey = "onboarded"
    private static let askedForAccessKey = "askedForAccess"
    private static let screenRecordingSettings = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!

    let preferences: Preferences
    private let hotKey = HotKey()
    private let toast = Toast()
    let history = History()
    private let settings = SettingsWindowHost(title: "Common Shot Settings")
    let updates = UpdateCheck(tool: CommonTool.thisApp!)
    private var statusItem: NSStatusItem?
    private(set) var hotKeyProblem: String?

    /// Set from the shortcut until the shot is on the clipboard, so a second press can't start another.
    private var busy = false
    private var overlay: Overlay?
    private var previousApp: NSRunningApplication?

    init(preferences: Preferences = Preferences(), interactive: Bool = true) {
        self.preferences = preferences
        super.init()
        guard interactive else { return }
        hotKey.onPress = { [weak self] in self?.shortcutPressed() }
        registerHotKey()
        updateStatusItem()

        if !UserDefaults.standard.bool(forKey: Self.onboardedKey) {
            UserDefaults.standard.set(true, forKey: Self.onboardedKey)
            DispatchQueue.main.async { [weak self] in
                MainActor.assumeIsolated { self?.showSettings() }
            }
        }
    }

    // MARK: Shortcut

    func registerHotKey() {
        do {
            try hotKey.register(preferences.hotKey)
            hotKeyProblem = nil
        } catch {
            hotKeyProblem = error.localizedDescription
        }
        updateStatusItem()
    }

    /// While a new shortcut is being recorded, the old one mustn't fire.
    func suspendHotKey() {
        hotKey.unregister()
    }

    /// Pressing it again while the overlay is up puts it away, as Escape does.
    private func shortcutPressed() {
        if overlay != nil {
            finish(nil)
        } else {
            capture()
        }
    }

    // MARK: Capturing

    @objc func capture() {
        guard !busy, ensureAccess() else { return }
        busy = true
        previousApp = NSWorkspace.shared.frontmostApplication
        Task {
            do {
                let overlay = Overlay(freeze: try await Capture.freeze())
                overlay.onPick = { [weak self] in self?.finish($0) }
                self.overlay = overlay
                // Active, so the crosshair cursor shows and Escape and Return reach the overlay.
                NSApp.activate()
                overlay.show()
            } catch {
                busy = false
                Self.present(error)
            }
        }
    }

    private func finish(_ choice: (pick: Pick, asText: Bool)?) {
        overlay?.close()
        overlay = nil
        let fromTerminal = previousApp?.bundleIdentifier.map(Self.terminals.contains) ?? false
        if let previousApp, previousApp != .current { previousApp.activate() }
        previousApp = nil
        guard let choice else {
            busy = false
            return
        }
        Task {
            defer { busy = false }
            do {
                let (image, still) = try await Self.image(for: choice.pick)
                if choice.asText {
                    try await deliverText(from: image, scale: still.scale, screen: still.screen)
                } else {
                    try await deliver(
                        image, scale: still.scale, screen: still.screen,
                        detail: fromTerminal ? "Paste with Ctrl+V in Claude Code" : nil)
                }
            } catch {
                Self.present(error)
            }
        }
    }

    /// Terminals paste an image with Ctrl+V in Claude Code, not ⌘V, which only pastes text, so a shot
    /// taken from one says so.
    private static let terminals: Set = [
        "com.apple.Terminal", "com.mitchellh.ghostty", "com.googlecode.iterm2", "dev.warp.Warp-Stable",
        "net.kovidgoyal.kitty", "org.alacritty", "com.github.wez.wezterm", "co.zeit.hyper",
    ]

    private static func image(for pick: Pick) async throws -> (CGImage, Still) {
        switch pick {
        case .screen(let still):
            return (still.image, still)
        case .area(let still, let rect):
            let pixels = Geometry.pixels(
                of: rect, viewSize: still.screen.frame.size, imageWidth: still.image.width,
                imageHeight: still.image.height)
            guard let image = still.image.cropping(to: pixels) else { throw OutputError.encoding }
            return (image, still)
        case .window(let id, let still):
            return (try await Capture.image(ofWindow: id), still)
        }
    }

    /// Sizes and encodes off the main thread: a 5K PNG takes long enough to notice.
    func deliver(_ image: CGImage, scale: CGFloat, screen: NSScreen?, detail: String? = nil) async throws {
        let size = preferences.imageSize
        let (sized, density, png) = try await Task.detached(priority: .userInitiated) {
            let sized = try Output.resized(image, to: size)
            // The density shrinks with the pixels, so a shot opens at its on-screen size, down to 1×.
            let density = max(1, scale * CGFloat(sized.width) / CGFloat(image.width))
            return (sized, density, try Output.png(sized, scale: density))
        }.value
        Output.copy(png)
        let date = Date()
        let file =
            try history.add(png, width: sized.width, height: sized.height, at: date, keeping: preferences.historyLimit)
            ?? Output.temporaryFile(png, at: date)
        if preferences.showsPreview, let screen {
            toast.show(sized, scale: density, on: screen, caption: Self.caption(sized), detail: detail, file: file)
        }
    }

    /// Copies the text in `image` rather than the image: exact, searchable, and far fewer tokens.
    private func deliverText(from image: CGImage, scale: CGFloat, screen: NSScreen) async throws {
        let text = try await Task.detached(priority: .userInitiated) { try Recognize.text(in: image) }.value
        guard !text.isEmpty else {
            toast.show(image, scale: scale, on: screen, caption: "No text found", detail: "The clipboard is unchanged")
            return
        }
        Output.copy(text: text)
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).count
        if preferences.showsPreview {
            toast.show(
                image, scale: scale, on: screen, caption: "Copied text · \(lines) \(lines == 1 ? "line" : "lines")",
                detail: text.count > 60 ? String(text.prefix(57)) + "…" : text)
        }
    }

    private static func caption(_ image: CGImage) -> String {
        let tokens = ImageSize.estimatedTokens(width: image.width, height: image.height)
        return "Copied · \(image.width) × \(image.height) · \(ImageSize.describe(tokens: tokens))"
    }

    /// A shot from the menu goes back on the clipboard exactly as it was first copied.
    @objc private func copyFromHistory(_ item: NSMenuItem) {
        guard let url = item.representedObject as? URL else { return }
        do {
            let png = try Data(contentsOf: url)
            Output.copy(png)
            if preferences.showsPreview, let screen = NSScreen.main,
                let source = CGImageSourceCreateWithData(png as CFData, nil),
                let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
            {
                toast.show(
                    image, scale: screen.backingScaleFactor, on: screen, caption: Self.caption(image), file: url)
            }
        } catch {
            Self.present(error)
        }
    }

    @objc func clearHistory() {
        do {
            try history.clear()
        } catch {
            Self.present(error)
        }
    }

    func historyLimitChanged() {
        do {
            try history.keep(preferences.historyLimit)
        } catch {
            Self.present(error)
        }
    }

    @objc func showHistoryInFinder() {
        do {
            try FileManager.default.createDirectory(at: History.directory, withIntermediateDirectories: true)
            NSWorkspace.shared.open(History.directory)
        } catch {
            Self.present(error)
        }
    }

    /// The first time, macOS asks on our behalf. After that it stays silent, so explain and point the way.
    private func ensureAccess() -> Bool {
        if Capture.hasAccess { return true }
        if !UserDefaults.standard.bool(forKey: Self.askedForAccessKey) {
            UserDefaults.standard.set(true, forKey: Self.askedForAccessKey)
            CGRequestScreenCaptureAccess()
            return false
        }
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = "Common Shot needs Screen Recording access"
        // A switch that's already on usually belongs to an earlier build: macOS ties the grant to the
        // signature, and a rebuilt app signed ad hoc has a new one.
        alert.informativeText = """
            Turn on Common Shot in System Settings › Privacy & Security › Screen & System Audio Recording, then \
            quit and reopen it.

            If it's already on, that switch is for an earlier copy of the app. Select Common Shot, remove it \
            with −, then turn on the copy you're running.
            """
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn { NSWorkspace.shared.open(Self.screenRecordingSettings) }
        return false
    }

    func openScreenRecordingSettings() {
        NSWorkspace.shared.open(Self.screenRecordingSettings)
    }

    // MARK: Settings

    /// A fresh view each time, so Open at login reflects a change made elsewhere.
    @objc func showSettings() {
        settings.show { SettingsView(controller: self, preferences: preferences) }
    }

    func preferencesChanged() {
        updateStatusItem()
    }

    // MARK: Menu bar

    private func updateStatusItem() {
        guard preferences.showsMenuBarItem else {
            if let statusItem { NSStatusBar.system.removeStatusItem(statusItem) }
            statusItem = nil
            return
        }
        let item = statusItem ?? NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item
        item.autosaveName = "shot"
        item.button?.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "Common Shot")

        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
    }

    static func present(_ error: Error) {
        NSApp.activate()
        NSAlert(error: error).runModal()
    }
}

extension AppController: NSMenuDelegate {
    /// Built as it opens, so the recent shots are always current.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let capture = NSMenuItem(title: "Take Screenshot", action: #selector(capture), keyEquivalent: "")
        capture.target = self
        menu.addItem(capture)
        let shortcut = NSMenuItem(
            title: hotKeyProblem ?? "Shortcut: \(preferences.hotKey.displayName)", action: nil, keyEquivalent: "")
        shortcut.isEnabled = false
        menu.addItem(shortcut)

        if preferences.historyLimit > 0 {
            menu.addItem(.separator())
            menu.addItem(.sectionHeader(title: history.shots.isEmpty ? "No Recent Shots" : "Recent Shots"))
            let recent = history.shots.prefix(Self.shotsInMenu)
            for shot in recent { menu.addItem(historyItem(shot, side: Self.thumbnailSide)) }
            if history.shots.count > recent.count {
                let older = NSMenu()
                for shot in history.shots.dropFirst(recent.count) { older.addItem(historyItem(shot, side: 80)) }
                menu.addItem(withTitle: "Older Shots", action: nil, keyEquivalent: "").submenu = older
            }
            if !history.shots.isEmpty {
                let show = NSMenuItem(
                    title: "Show History in Finder", action: #selector(showHistoryInFinder), keyEquivalent: "")
                show.target = self
                menu.addItem(show)
                let clear = NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: "")
                clear.target = self
                menu.addItem(clear)
            }
        }

        menu.addItem(.separator())
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(title: "Quit Common Shot", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    /// Big enough to tell one shot of code from another at a glance; the rest go in a submenu, so a long
    /// history doesn't make a menu taller than the screen.
    private static let thumbnailSide: CGFloat = 160
    private static let shotsInMenu = 6

    private func historyItem(_ shot: History.Shot, side: CGFloat) -> NSMenuItem {
        let item = NSMenuItem(title: Self.caption(for: shot), action: #selector(copyFromHistory), keyEquivalent: "")
        item.target = self
        item.representedObject = shot.url
        item.image = history.thumbnail(for: shot, fitting: side, scale: NSScreen.main?.backingScaleFactor ?? 2)
        item.toolTip = "Copy this shot again"
        return item
    }

    /// "2:03 PM · 1280 × 760 · ≈ 1.3k tokens", with the date too once it's not today's.
    private static func caption(for shot: History.Shot) -> String {
        let when = shot.date.formatted(
            date: Calendar.current.isDateInToday(shot.date) ? .omitted : .abbreviated, time: .shortened)
        let tokens = ImageSize.describe(tokens: ImageSize.estimatedTokens(width: shot.width, height: shot.height))
        return "\(when) · \(shot.width) × \(shot.height) · \(tokens)"
    }
}

extension AppController: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Welcome.showIfFirstLaunch(
            WelcomeInfo(
                line: "Screenshots straight to the clipboard: press ⇧⌘2, drag, paste.",
                permission: .screenRecording(reason: "to capture what is on your screen")))
        updates.start()
    }

    /// Opening the app again while it runs is how people look for its settings.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }
}
