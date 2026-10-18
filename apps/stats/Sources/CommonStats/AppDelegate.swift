import AppKit
import CommonKit
import CommonUI
import StatKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel!
    private var statusItem: StatusItemController!
    private let settings = SettingsWindowHost(title: "Common Stats Settings")
    private let updates = UpdateCheck(tool: CommonTool.thisApp!)

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Two copies (say, a build folder and /Applications) would draw two bars.
        // The newer one leaves; ordering by launch date then PID means two
        // copies starting at the same instant can't both quit.
        if let id = Bundle.main.bundleIdentifier,
            NSRunningApplication.runningApplications(withBundleIdentifier: id).contains(where: isOlder)
        {
            NSLog("Common Stats: an older copy is already running; exiting")
            NSApp.terminate(nil)
            return
        }

        LegacyIdentity.followLoginItem()
        model = AppModel()
        statusItem = StatusItemController(model: model) { [unowned self] in showSettings() }
        model.onUpdate = { [weak statusItem] in statusItem?.render() }
        model.start()
        Welcome.showIfNeeded(
            WelcomeInfo(line: "System stats in the menu bar: CPU, GPU, memory, network, disk, storage, and battery."))
        updates.start()

        // Nobody can see the menu bar while the displays sleep; stop waking the CPU for it.
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [model] _ in
            MainActor.assumeIsolated { model?.stop() }
        }
        center.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [model] _ in
            MainActor.assumeIsolated { model?.start() }
        }
    }

    private func showSettings() {
        settings.show { SettingsView(model: model, updates: updates) }
    }

    private func isOlder(_ other: NSRunningApplication) -> Bool {
        let me = NSRunningApplication.current
        guard other.processIdentifier != me.processIdentifier, !other.isTerminated else { return false }
        let mine = me.launchDate ?? .distantFuture, theirs = other.launchDate ?? .distantFuture
        return theirs != mine ? theirs < mine : other.processIdentifier < me.processIdentifier
    }

    /// Launching the app again while it runs is the only way back to
    /// Settings if the menu bar item is hidden behind the notch.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showSettings()
        return false
    }
}
