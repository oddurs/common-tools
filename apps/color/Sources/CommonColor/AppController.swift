import AppKit
import CommonKit
import CommonUI
import SwiftUI

/// Owns the status item, its menu, and Settings.
@MainActor
final class AppController: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let updates = UpdateCheck(tool: CommonTool.thisApp!)
    private let settings = SettingsWindowHost(title: "Common Color Settings")
    private var item: NSStatusItem!
    private let menu = NSMenu()

    func applicationDidFinishLaunching(_ notification: Notification) {
        item = NSStatusBar.system.commonItem(autosaveName: "CommonColor", length: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "eyedropper", accessibilityDescription: "Common Color")
        menu.delegate = self
        item.menu = menu
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

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let settings = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(
            NSMenuItem(title: "Quit Common Color", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    /// A fresh view each time, so Open at login reflects a change made elsewhere.
    @objc func showSettings() {
        settings.show { SettingsView(controller: self) }
    }
}
