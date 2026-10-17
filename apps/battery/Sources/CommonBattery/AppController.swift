import AppKit
import BatteryKit
import CommonKit
import CommonUI
import IOKit.ps
import SwiftUI

/// What the menu and Settings show. Reading it from a view is what makes an open menu redraw.
@MainActor @Observable
final class BatteryState {
    var reading: BatteryReading?
    var history = ChargeHistory()
    /// False while the item can't be seen: behind the camera housing, collapsed by a menu bar
    /// manager, or under a full-screen app.
    var barVisible = true
}

/// Owns the status item, its menu, and sampling. The battery is read when macOS says a power
/// source changed, once a minute for the history, and every two seconds while the menu is open,
/// so the watts it shows are live.
@MainActor
final class AppController: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let preferences = Preferences()
    let state = BatteryState()
    private let sampler = BatterySampler()
    private let notifier = Notifier()
    private var alerts = AlertTracker()
    private var estimator = TimeEstimator(state: AppController.loadEstimator())
    private var savedLabels = 0
    private let settings = SettingsWindowHost(title: "Common Battery Settings")
    let updates = UpdateCheck(tool: CommonTool.thisApp!)

    private var item: NSStatusItem!
    private let menu = NSMenu()
    private var renderer: BarRenderer?
    private var menuOpen = false
    private var timer: Timer?
    private var powerSource: CFRunLoopSource?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Two copies (say, a build folder and /Applications) would draw two batteries. The newer one
        // leaves; ordering by launch date then PID means two copies starting at once can't both quit.
        if let id = Bundle.main.bundleIdentifier,
            NSRunningApplication.runningApplications(withBundleIdentifier: id).contains(where: isOlder)
        {
            NSLog("Common Battery: an older copy is already running; exiting")
            NSApp.terminate(nil)
            return
        }

        item = NSStatusBar.system.commonItem(autosaveName: "CommonBattery", length: NSStatusItem.variableLength)
        item.button?.imagePosition = .imageOnly
        menu.delegate = self
        item.menu = menu
        if let window = item.button?.window {
            NotificationCenter.default.addObserver(
                self, selector: #selector(occlusionChanged), name: NSWindow.didChangeOcclusionStateNotification,
                object: window)
        }

        observePowerSources()
        let center = NotificationCenter.default
        center.addObserver(forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        // Nobody can see the menu bar while the displays sleep; stop waking the CPU for it.
        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) {
            [weak self] _ in
            MainActor.assumeIsolated { self?.timer?.invalidate() }
        }
        workspace.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) {
            [weak self] _ in
            MainActor.assumeIsolated {
                self?.refresh()
                self?.schedule()
            }
        }

        refresh()
        schedule()
        // Asking to post notifications raises a prompt of its own; it waits for Welcome to close.
        Welcome.showIfNeeded(
            WelcomeInfo(
                line:
                    "The battery in the menu bar: level, time left, what it's doing, and alerts at the levels you choose."
            )
        ) { [weak self] in
            guard let self, preferences.notifies else { return }
            notifier.requestAccess()
        }
        updates.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        saveEstimator()
    }

    /// Launching the app again while it runs is the way back to Settings if the item is hidden.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showSettings()
        return false
    }

    /// A fresh view each time, so Open at login reflects a change made elsewhere.
    private func showSettings() {
        settings.show { SettingsView(controller: self, preferences: preferences, state: state) }
    }

    func preferencesChanged() {
        if preferences.notifies { notifier.requestAccess() }
        render()
    }

    var notificationsBlocked: Bool {
        get async { await notifier.isBlocked() }
    }

    // MARK: Sampling

    /// macOS calls this on the main run loop whenever a power source changes: plugged in,
    /// unplugged, a percent gained or lost, a new time estimate.
    private func observePowerSources() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        guard
            let source = IOPSNotificationCreateRunLoopSource(
                { context in
                    guard let context else { return }
                    let controller = Unmanaged<AppController>.fromOpaque(context).takeUnretainedValue()
                    MainActor.assumeIsolated { controller.refresh() }
                }, context)?.takeRetainedValue()
        else { return }
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        powerSource = source
    }

    private func schedule() {
        timer?.invalidate()
        let interval: TimeInterval = menuOpen ? 2 : ChargeHistory.spacing
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        // Tolerance lets macOS batch the wakeup with other work.
        timer.tolerance = interval / 5
        // Common modes, so the open menu's tracking loop doesn't stall it.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func refresh() {
        var reading = sampler.sample()
        if let sampled = reading { reading?.minutesRemaining = estimator.update(sampled, at: Date()) }
        saveEstimatorIfLearned()
        state.reading = reading
        if let reading { state.history.record(reading, at: Date()) }
        let low = preferences.lowAlert > 0 ? preferences.lowAlert : nil
        let charged = preferences.chargedAlert > 0 ? preferences.chargedAlert : nil
        for alert in alerts.update(reading, low: low, charged: charged) { notifier.post(alert) }
        render()
    }

    private func render() {
        guard let button = item?.button else { return }
        let appearance = preferences.appearance
        let height = NSStatusBar.system.thickness
        let resized = renderer?.appearance != appearance || renderer?.height != height
        let visible = button.window?.occlusionState.contains(.visible) ?? true
        guard
            BarRenderer.mustDraw(
                hasImage: button.image != nil, resized: resized, visible: visible, menuOpen: menuOpen)
        else { return }
        if resized { renderer = BarRenderer(appearance: appearance, height: height) }
        button.image = renderer?.image(state.reading)
        button.setAccessibilityLabel(BarRenderer.accessibilityText(state.reading))
    }

    @objc private func occlusionChanged() {
        state.barVisible = item.button?.window?.occlusionState.contains(.visible) ?? true
        render()
    }

    // MARK: Learning

    private static let estimatorKey = "timeEstimator"

    private static func loadEstimator() -> TimeEstimator.State {
        guard let data = UserDefaults.standard.data(forKey: estimatorKey) else { return .init() }
        do {
            return try JSONDecoder().decode(TimeEstimator.State.self, from: data)
        } catch {
            // Unreadable state starts the learning over; macOS's estimate shows meanwhile.
            NSLog("Common Battery: discarding unreadable time estimator: \(error)")
            return .init()
        }
    }

    /// Every 30 lessons, so a crash costs at most half an hour of learning without a write a minute.
    private func saveEstimatorIfLearned() {
        if estimator.state.labels - savedLabels >= 30 { saveEstimator() }
    }

    private func saveEstimator() {
        do {
            UserDefaults.standard.set(try JSONEncoder().encode(estimator.state), forKey: Self.estimatorKey)
            savedLabels = estimator.state.labels
        } catch {
            NSLog("Common Battery: could not save time estimator: \(error)")
        }
    }

    // MARK: NSMenuDelegate

    /// The panel exists only while the menu is open, so a closed menu costs nothing.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let host = NSHostingView(rootView: BatteryPanel(state: state))
        host.frame.size = host.fittingSize
        let panel = NSMenuItem()
        panel.view = host
        menu.addItem(panel)
        menu.addItem(.separator())

        let battery = NSMenuItem(title: "Battery Settings…", action: #selector(openBatterySettings), keyEquivalent: "")
        battery.target = self
        // Tahoe gives standard items icons; match them. Earlier releases show none.
        if #available(macOS 26, *) {
            battery.image = NSImage(systemSymbolName: "battery.100percent", accessibilityDescription: nil)
        }
        menu.addItem(battery)
        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(
            NSMenuItem(title: "Quit Common Battery", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        )
    }

    func menuWillOpen(_ menu: NSMenu) {
        menuOpen = true
        refresh()
        schedule()
    }

    func menuDidClose(_ menu: NSMenu) {
        menuOpen = false
        schedule()
        // Drop the hosting view; menuNeedsUpdate rebuilds it on the next open.
        for item in menu.items { item.view = nil }
    }

    @objc private func openSettings() { showSettings() }

    @objc private func openBatterySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Battery-Settings.extension")!)
    }

    func openControlCenterSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension")!)
    }

    // MARK: Launch

    private func isOlder(_ other: NSRunningApplication) -> Bool {
        let me = NSRunningApplication.current
        guard other.processIdentifier != me.processIdentifier, !other.isTerminated else { return false }
        let mine = me.launchDate ?? .distantFuture, theirs = other.launchDate ?? .distantFuture
        return theirs != mine ? theirs < mine : other.processIdentifier < me.processIdentifier
    }
}
