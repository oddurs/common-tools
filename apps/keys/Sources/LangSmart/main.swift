import AppKit
import CommonUI
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let engine = Engine(prefs: Preferences())
    private var statusMenu: StatusMenu?
    private let settings = SettingsWindowHost(title: "Common Keys Settings")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = Self.mainMenu()
        engine.start()
        statusMenu = StatusMenu(engine: engine) { [weak self] in self?.showSettings() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        engine.flush()
    }

    /// Opening the app again while it runs, from Finder or Spotlight, shows Settings: a menu bar app
    /// has no other window to bring forward.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }

    @objc func showSettings(_ sender: Any? = nil) {
        settings.show { SettingsView().environment(engine) }
    }

    /// Never shown, since this is a menu bar app, but it gives the settings window ⌘, ⌘W and ⌘Q.
    private static func mainMenu() -> NSMenu {
        let app = NSMenu()
        app.addItem(
            withTitle: "Settings…", action: #selector(AppDelegate.showSettings(_:)), keyEquivalent: ",")
        app.addItem(
            withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        app.addItem(
            withTitle: "Quit Common Keys", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let root = NSMenu()
        let item = NSMenuItem(title: "Common Keys", action: nil, keyEquivalent: "")
        item.submenu = app
        root.addItem(item)
        return root
    }
}

if let index = CommandLine.arguments.firstIndex(of: "--snapshot") {
    let path = CommandLine.arguments.dropFirst(index + 1).first ?? "snapshot.png"
    MainActor.assumeIsolated { SnapshotCommand.run(path: path) }
    exit(0)
}

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.setActivationPolicy(.accessory)
NSApplication.shared.run()
