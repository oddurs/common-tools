import AppKit
import CommonKit
import CommonUI
import OSLog
import ScreenCaptureKit
import ShotKit

/// Wires the shortcut, the overlay, the menu bar item, and Settings together, and sends each shot to
/// the clipboard.
@MainActor
final class AppController: NSObject {
    static let permission = Permission.screenRecording(reason: "to capture what is on your screen")
    private static let askedForAccessKey = "askedForAccess"
    private static let screenRecordingSettings = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!

    let preferences: Preferences
    private let hotKey = HotKey()
    private let toast = Toast()
    private let shutter = Shutter()
    let history = History()
    private let settings = SettingsWindowHost(title: "Common Shot Settings")
    let updates = UpdateCheck(tool: CommonTool.thisApp!)
    private var statusItem: NSStatusItem?
    private(set) var hotKeyProblem: String?

    /// Set from the shortcut until the shot is on the clipboard, so a second press can't start another.
    private var busy = false
    private var overlay: Overlay?
    private var previousApp: NSRunningApplication?
    /// What ScreenCaptureKit saw when the overlay froze, and each hovered window's capture, already
    /// under way so a click copies at once.
    private var frozenContent: SCShareableContent?
    private var windowShots: [UInt32: Task<CGImage?, Error>] = [:]
    /// How long the shortcut and the copy take, for `log stream --level info --predicate
    /// 'subsystem == "com.oddurs.commonshot"'`. Times only; nothing about what was captured.
    private static let latency = Logger(subsystem: "com.oddurs.commonshot", category: "latency")

    init(preferences: Preferences = Preferences(), interactive: Bool = true) {
        self.preferences = preferences
        super.init()
        guard interactive else { return }
        hotKey.onPress = { [weak self] in self?.shortcutPressed() }
        registerHotKey()
        updateStatusItem()
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
        let pressed = ContinuousClock.now
        Task {
            do {
                let freeze = try await Capture.freeze()
                let captured = ContinuousClock.now
                let overlay = Overlay(freeze: freeze, imageSize: preferences.imageSize)
                overlay.onPick = { [weak self] in self?.finish($0) }
                overlay.onHover = { [weak self] in self?.prefetch($0) }
                frozenContent = freeze.content
                self.overlay = overlay
                // Active, so the crosshair cursor shows and Escape and Return reach the overlay.
                NSApp.activate()
                overlay.show()
                let shown = ContinuousClock.now
                Self.latency.info(
                    "overlay up \(Self.milliseconds(shown - pressed)) ms after the shortcut: \(freeze.stills.count) displays captured in \(Self.milliseconds(captured - pressed)) ms"
                )
            } catch {
                busy = false
                Self.present(error)
            }
        }
    }

    private func finish(_ choice: (pick: Pick, asText: Bool)?) {
        let picked = ContinuousClock.now
        overlay?.close()
        overlay = nil
        let windowShots = windowShots
        self.windowShots = [:]
        let content = frozenContent
        frozenContent = nil
        let fromTerminal = previousApp?.bundleIdentifier.map(Self.terminals.contains) ?? false
        if let previousApp, previousApp != .current { previousApp.activate() }
        previousApp = nil
        guard let choice else {
            for shot in windowShots.values { shot.cancel() }
            busy = false
            return
        }
        // The shutter as the overlay goes, the moment of the shot; cancelling makes no sound.
        if preferences.playsSound { shutter.play() }
        Task {
            defer { busy = false }
            do {
                let (image, still) = try await Self.image(for: choice.pick, windowShots: windowShots, content: content)
                let source = Self.source(of: choice.pick)
                if choice.asText {
                    try await deliverText(from: image, scale: still.scale, screen: still.screen, from: source)
                } else {
                    try await deliver(
                        image, scale: still.scale, screen: still.screen,
                        detail: fromTerminal ? "Paste with Ctrl+V in Claude Code" : nil, from: source)
                }
                Self.latency.info(
                    "\(choice.asText ? "text" : "image") on the clipboard \(Self.milliseconds(.now - picked)) ms after the pick"
                )
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

    /// Starts capturing a window as soon as the pointer is over it; a window passed over twice is
    /// captured once.
    private func prefetch(_ id: UInt32) {
        guard windowShots[id] == nil else { return }
        let content = frozenContent
        windowShots[id] = Task { try await Capture.image(ofWindow: id, in: content) }
    }

    private static func image(
        for pick: Pick, windowShots: [UInt32: Task<CGImage?, Error>], content: SCShareableContent?
    ) async throws -> (CGImage, Still) {
        switch pick {
        case .screen(let still):
            return (still.image, still)
        case .area(let still, let rect):
            return (try frozen(rect, of: still), still)
        case .window(let window, let still):
            let shot = windowShots[window.id] ?? Task { try await Capture.image(ofWindow: window.id, in: content) }
            if let image = try await shot.value { return (image, still) }
            // Closed since: what was on screen is still in the frozen picture, which is what was picked.
            let local = Geometry.local(window.frame, displayBounds: still.displayBounds)
            return (try frozen(local.intersection(CGRect(origin: .zero, size: still.frame.size)), of: still), still)
        }
    }

    /// Where the pick was on screen, in AppKit's global coordinates, for the preview to fly from.
    private static func source(of pick: Pick) -> CGRect {
        switch pick {
        case .screen(let still):
            return still.frame
        case .area(let still, let rect):
            return rect.offsetBy(dx: still.frame.minX, dy: still.frame.minY)
        case .window(let window, let still):
            return Geometry.local(window.frame, displayBounds: still.displayBounds)
                .offsetBy(dx: still.frame.minX, dy: still.frame.minY)
        }
    }

    /// `rect`, in the still's points from its bottom-left corner, cut from the frozen picture.
    private static func frozen(_ rect: CGRect, of still: Still) throws -> CGImage {
        let pixels = Geometry.pixels(
            of: rect, viewSize: still.frame.size, imageWidth: still.image.width, imageHeight: still.image.height)
        guard let image = still.image.cropping(to: pixels) else { throw PNG.Failure.encoding }
        return image
    }

    private static func milliseconds(_ duration: Duration) -> Int {
        Int((duration / .milliseconds(1)).rounded())
    }

    /// The preview starts at once, from the picture as it was picked, while the PNG is sized and encoded
    /// off the main thread; the clipboard follows within tens of milliseconds, and the preview becomes
    /// draggable once the file it would drag exists.
    func deliver(
        _ image: CGImage, scale: CGFloat, screen: NSScreen?, detail: String? = nil, from source: CGRect? = nil
    ) async throws {
        let size = preferences.imageSize
        let fit = size.fit(width: image.width, height: image.height)
        // The density shrinks with the pixels, so a shot opens at its on-screen size, down to 1×.
        let density = max(1, scale * CGFloat(fit.width) / CGFloat(image.width))
        let showsPreview = preferences.showsPreview && screen != nil
        if showsPreview {
            toast.show(
                image, scale: scale, on: screen, caption: Self.caption(width: fit.width, height: fit.height),
                detail: detail, from: source)
        }
        do {
            let (sized, png) = try await Task.detached(priority: .userInitiated) {
                let sized = try PNG.prepared(image, size: size)
                return (sized, try PNG.data(sized, scale: density))
            }.value
            let date = Date()
            // Saved first, so the clipboard can point at the file.
            let file =
                try history.add(
                    png, width: sized.width, height: sized.height, at: date, keeping: preferences.historyLimit)
                ?? Output.temporaryFile(png, at: date)
            Output.copy(png, file: file)
            if showsPreview { toast.attach(file: file) }
            Self.announce("Copied \(sized.width) by \(sized.height)")
        } catch {
            // Nothing was copied, so the preview mustn't say it was.
            toast.dismiss()
            throw error
        }
    }

    /// For VoiceOver, which can't see the preview's corner.
    private static func announce(_ text: String) {
        NSAccessibility.post(
            element: NSApp as Any, notification: .announcementRequested,
            userInfo: [.announcement: text, .priority: NSAccessibilityPriorityLevel.high.rawValue])
    }

    /// Copies the text in `image` rather than the image: exact, searchable, and far fewer tokens.
    private func deliverText(
        from image: CGImage, scale: CGFloat, screen: NSScreen?, from source: CGRect? = nil
    ) async throws {
        let text = try await Task.detached(priority: .userInitiated) { try Recognize.text(in: image) }.value
        guard !text.isEmpty else {
            toast.show(
                image, scale: scale, on: screen, caption: "No text found", detail: "The clipboard is unchanged",
                from: source)
            Self.announce("No text found")
            return
        }
        Output.copy(text: text)
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).count
        let caption = "Copied text · \(lines) \(lines == 1 ? "line" : "lines")"
        if preferences.showsPreview {
            toast.show(
                image, scale: scale, on: screen, caption: caption,
                detail: text.count > 60 ? String(text.prefix(57)) + "…" : text, from: source)
        }
        Self.announce(caption)
    }

    private static func caption(width: Int, height: Int) -> String {
        let tokens = ImageSize.estimatedTokens(width: width, height: height)
        return "Copied · \(width) × \(height) · \(ImageSize.describe(tokens: tokens))"
    }

    /// A shot from the menu goes back on the clipboard exactly as it was first copied.
    @objc private func copyFromHistory(_ item: NSMenuItem) {
        guard let url = item.representedObject as? URL else { return }
        do {
            let png = try Data(contentsOf: url)
            Output.copy(png, file: url)
            if preferences.showsPreview, let screen = NSScreen.main,
                let source = CGImageSourceCreateWithData(png as CFData, nil),
                let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
            {
                toast.show(
                    image, scale: screen.backingScaleFactor, on: screen,
                    caption: Self.caption(width: image.width, height: image.height), file: url)
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
        alert.informativeText = """
            Turn on Common Shot in System Settings › Privacy & Security › Screen & System Audio Recording. \
            \(Self.permission.reopenNote(app: "Common Shot") ?? "")

            \(Self.permission.staleSwitchNote(app: "Common Shot")) Reset and Ask Again clears it.
            """
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Reset and Ask Again")
        alert.addButton(withTitle: "Quit and Reopen")
        alert.addButton(withTitle: "Cancel")
        switch alert.runModal() {
        case .alertFirstButtonReturn: openScreenRecordingSettings()
        case .alertSecondButtonReturn: resetScreenRecording()
        case .alertThirdButtonReturn: reopen()
        default: break
        }
        return false
    }

    func openScreenRecordingSettings() {
        NSWorkspace.shared.open(Self.screenRecordingSettings)
    }

    /// Clears a record left by an earlier copy, whose switch shows on but doesn't apply to this one,
    /// and asks again.
    func resetScreenRecording() {
        do {
            try Self.permission.resetAndRequest()
        } catch {
            Self.present(error)
        }
    }

    /// macOS applies a Screen Recording switch only when the app starts.
    func reopen() {
        do {
            try Relaunch.now()
        } catch {
            Self.present(error)
        }
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
        let item = statusItem ?? NSStatusBar.system.commonItem(autosaveName: "shot", length: NSStatusItem.squareLength)
        statusItem = item
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
        Welcome.showIfNeeded(
            WelcomeInfo(
                line: "Screenshots straight to the clipboard: press ⇧⌘2, drag, paste.", permission: Self.permission))
        updates.start()
        Overlay.warmUp()
        Task {
            do {
                try await Capture.warmUp()
            } catch {
                // The shortcut asks again and reports a real failure; this was only to save it time.
                Self.latency.error("warming up ScreenCaptureKit failed: \(error.localizedDescription)")
            }
        }
    }

    /// Opening the app again while it runs is how people look for its settings.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }
}
