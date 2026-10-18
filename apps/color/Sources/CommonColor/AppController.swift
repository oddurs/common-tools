import AppKit
import ColorKit
import CommonKit
import CommonShortcut
import CommonUI
import SwiftUI

/// Owns the status item, its menu, the shortcut, and the recent picks. A pick goes through the
/// system's colour sampler, which shows its own loupe and reads the pixel for the app, so Common
/// Color needs no permission.
@MainActor
final class AppController: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let preferences = Preferences()
    let updates = UpdateCheck(tool: CommonTool.thisApp!)
    private let settings = SettingsWindowHost(title: "Common Color Settings")
    private let hotKey = HotKey(signature: "CCol")
    private(set) var hotKeyProblem: String?
    private var history = History()
    private var item: NSStatusItem!
    private let menu = NSMenu()
    /// Held while the loupe is up, so a second press doesn't open another.
    private var sampler: NSColorSampler?

    private static let historyKey = "history"

    func applicationDidFinishLaunching(_ notification: Notification) {
        history = Self.loadHistory()
        item = NSStatusBar.system.commonItem(autosaveName: "CommonColor", length: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "eyedropper", accessibilityDescription: "Common Color")
        menu.delegate = self
        item.menu = menu
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
        let sampler = NSColorSampler()
        self.sampler = sampler
        // nil when the user presses Escape: nothing is recorded and the clipboard is left alone.
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
        history.add(value)
        saveHistory()
        copy(preferences.format, value)
    }

    private func copy(_ format: ColorFormat, _ color: ColorValue) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(format.string(color), forType: .string)
    }

    // MARK: History

    private static func loadHistory() -> History {
        let (history, error) = History.load(from: .standard, key: historyKey)
        if let error { NSLog("Common Color: set aside unreadable recent colors: \(error)") }
        return history
    }

    private func saveHistory() {
        do {
            try history.save(to: .standard, key: Self.historyKey)
        } catch {
            NSLog("Common Color: could not save recent colours: \(error)")
        }
    }

    // MARK: Menu

    /// The panel exists only while the menu is open, so a closed menu costs nothing.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let pick = NSMenuItem(title: "Pick Color", action: #selector(pickFromMenu), keyEquivalent: "")
        pick.target = self
        if #available(macOS 26, *) {
            pick.image = NSImage(systemSymbolName: "eyedropper", accessibilityDescription: nil)
        }
        menu.addItem(pick)
        let shortcut = NSMenuItem(
            title: hotKeyProblem ?? "Shortcut: \(preferences.hotKey.displayName)", action: nil, keyEquivalent: "")
        shortcut.isEnabled = false
        menu.addItem(shortcut)
        menu.addItem(.separator())

        let host = NSHostingView(
            rootView: ColorPanel(
                history: history, format: preferences.format, shortcut: preferences.hotKey.displayName,
                copy: { [weak self] format, color in self?.copyFromMenu(format, color) },
                choose: { [weak self] color in self?.choose(color) },
                clear: { [weak self] in self?.clearHistory() }))
        host.frame.size = host.fittingSize
        let panel = NSMenuItem()
        panel.view = host
        menu.addItem(panel)
        menu.addItem(.separator())

        let settings = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(
            NSMenuItem(title: "Quit Common Color", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    func menuDidClose(_ menu: NSMenu) {
        // Drop the hosting view; menuNeedsUpdate rebuilds it on the next open.
        for item in menu.items { item.view = nil }
    }

    /// From the menu, the loupe waits for the menu to finish closing, or the menu's own window
    /// would be what it magnifies.
    @objc private func pickFromMenu() {
        DispatchQueue.main.async { [weak self] in self?.pick() }
    }

    private func copyFromMenu(_ format: ColorFormat, _ color: ColorValue) {
        copy(format, color)
        menu.cancelTracking()
    }

    /// A recent colour becomes the current one again, and is copied as a fresh pick would be.
    private func choose(_ color: ColorValue) {
        history.add(color)
        saveHistory()
        copy(preferences.format, color)
        menu.cancelTracking()
    }

    private func clearHistory() {
        history.clear()
        saveHistory()
        menu.cancelTracking()
    }

    // MARK: Settings

    /// A fresh view each time, so Open at login reflects a change made elsewhere.
    @objc func showSettings() {
        settings.show { SettingsView(controller: self, preferences: preferences) }
    }
}
