import AppKit
import ColorKit
import CommonKit
import CommonShortcut
import CommonUI
import SwiftUI

/// Owns the status item and its panel, the shortcut, and the recent picks. A pick goes through the
/// system's colour sampler, which shows its own loupe and reads the pixel for the app, so Common
/// Color needs no permission.
@MainActor
final class AppController: NSObject, NSApplicationDelegate {
    let preferences = Preferences()
    let updates = UpdateCheck(tool: CommonTool.thisApp!)
    private let settings = SettingsWindowHost(title: "Common Color Settings")
    private let hotKey = HotKey(signature: "CCol")
    private(set) var hotKeyProblem: String?
    private let picks = Picks(AppController.loadHistory(), save: AppController.saveHistory)
    private let panel = MenuPanelHost()
    private let confirmation = ConfirmationHost()
    private var item: NSStatusItem!
    /// Held while the loupe is up, so a second press doesn't open another.
    private var sampler: NSColorSampler?

    private static let historyKey = "history"

    func applicationDidFinishLaunching(_ notification: Notification) {
        item = NSStatusBar.system.commonItem(autosaveName: "CommonColor", length: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "eyedropper", accessibilityDescription: "Common Color")
        item.button?.target = self
        item.button?.action = #selector(togglePanel)
        // On the press, as a menu opens, not on the release.
        item.button?.sendAction(on: [.leftMouseDown, .rightMouseDown])
        hotKey.onPress = { [weak self] in self?.pick() }
        registerHotKey()
        Welcome.showIfNeeded(
            WelcomeInfo(line: "Pick a color from anywhere on screen and paste it as code: hex, CSS, SwiftUI or AppKit.")
        )
        updates.start()
    }

    /// Opening the app again while it runs is how people look for its settings.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showSettings()
        return false
    }

    // MARK: Shortcut

    func registerHotKey() {
        do {
            try hotKey.register(preferences.hotKey)
            hotKeyProblem = nil
        } catch {
            hotKeyProblem = error.localizedDescription
        }
    }

    /// While a new shortcut is being recorded, the old one mustn't fire.
    func suspendHotKey() {
        hotKey.unregister()
    }

    // MARK: Picking

    @objc func pick() {
        guard sampler == nil else { return }
        panel.close()
        let sampler = NSColorSampler()
        self.sampler = sampler
        // nil when the user presses Escape: nothing is recorded, the clipboard is left alone, and
        // nothing is shown.
        sampler.show { [weak self] picked in
            MainActor.assumeIsolated {
                self?.sampler = nil
                guard let picked else { return }
                self?.picked(picked)
            }
        }
    }

    private func picked(_ color: NSColor) {
        guard let value = ColorValue(color) else {
            NSLog("Common Color: the sampler returned a colour with no RGB form: \(color)")
            return
        }
        picks.add(value)
        // Beside the pointer, which is where the pixel was.
        copy(preferences.format, value, near: NSEvent.mouseLocation)
    }

    /// Puts `color` on the clipboard as `format`, and says so beside `point` for a moment.
    private func copy(_ format: ColorFormat, _ color: ColorValue, near point: NSPoint) {
        let text = format.string(color)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        guard preferences.confirmsCopies else { return }
        confirmation.show(near: point, announcing: "Copied \(text) as \(format.title)") {
            CopyConfirmation(format: format, color: color)
        }
    }

    // MARK: History

    private static func loadHistory() -> History {
        let (history, error) = History.load(from: .standard, key: historyKey)
        if let error { NSLog("Common Color: set aside unreadable recent colors: \(error)") }
        return history
    }

    private static func saveHistory(_ history: History) {
        do {
            try history.save(to: .standard, key: historyKey)
        } catch {
            NSLog("Common Color: could not save recent colors: \(error)")
        }
    }

    // MARK: The panel

    /// Opens under the menu bar item, or closes when it's open.
    @objc func togglePanel() {
        guard let button = item.button else { return }
        panel.toggle(below: button) {
            ColorPanel(
                picks: picks, format: preferences.format,
                showsAllFormats: Binding(
                    get: { [preferences] in preferences.showsAllFormats },
                    set: { [preferences] in preferences.showsAllFormats = $0 }),
                shortcut: preferences.hotKey.displayName, shortcutProblem: hotKeyProblem, actions: panelActions)
        }
    }

    private var panelActions: ColorPanel.Actions {
        ColorPanel.Actions(
            pick: { [weak self] in
                // The loupe waits for the panel to go, or the panel would be what it magnifies.
                self?.panel.close()
                DispatchQueue.main.async { self?.pick() }
            },
            copy: { [weak self] format, color, reuse in
                guard let self else { return }
                let below = item.button?.window.map { NSPoint(x: $0.frame.minX, y: $0.frame.minY) }
                panel.close()
                if reuse { picks.add(color) }
                copy(format, color, near: below ?? NSEvent.mouseLocation)
            },
            settings: { [weak self] in
                self?.panel.close()
                self?.showSettings()
            },
            quit: { NSApp.terminate(nil) },
            close: { [weak self] in self?.panel.close() })
    }

    // MARK: Settings

    /// A fresh view each time, so Open at login reflects a change made elsewhere.
    @objc func showSettings() {
        settings.show {
            SettingsView(
                preferences: preferences, updates: updates, suspendShortcut: { [weak self] in self?.suspendHotKey() },
                resumeShortcut: { [weak self] in
                    self?.registerHotKey()
                    return self?.hotKeyProblem
                }, hotKeyProblem: hotKeyProblem)
        }
    }
}

/// "Copied as Hex", the swatch, and exactly what went to the clipboard.
struct CopyConfirmation: View {
    let format: ColorFormat
    let color: ColorValue

    var body: some View {
        ConfirmationCard(
            title: "Copied as \(format.title)" + (format.isExact(color) ? "" : " (nearest)"),
            detail: format.string(color), detailIsCode: true
        ) {
            Swatch(color: color, size: 32, radius: Tokens.Radius.sm)
        }
    }
}
