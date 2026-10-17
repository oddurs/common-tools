import BatteryKit
import Foundation
import UserNotifications

/// Posts the low and charged alerts. Notification Center needs an app bundle; run bare from
/// `.build`, the app has none and `UNUserNotificationCenter.current()` traps, so it stays quiet.
@MainActor
final class Notifier {
    private var center: UNUserNotificationCenter? {
        Bundle.main.bundleURL.pathExtension == "app" ? .current() : nil
    }

    /// Set when macOS refuses to even ask, which it does for some builds (seen with an ad hoc
    /// signature on macOS 26) without listing the app in System Settings › Notifications.
    private var refused = false

    /// Asks once; macOS remembers the answer and later calls return it without a prompt.
    func requestAccess() {
        guard let center else { return }
        Task {
            do {
                _ = try await center.requestAuthorization(options: [.alert, .sound])
            } catch {
                refused = (error as? UNError)?.code == .notificationsNotAllowed
                NSLog("Common Battery: notification access failed: \(error.localizedDescription)")
            }
        }
    }

    func isBlocked() async -> Bool {
        guard let center else { return false }
        if refused { return true }
        return await center.notificationSettings().authorizationStatus == .denied
    }

    func post(_ alert: AlertTracker.Alert) {
        let content = UNMutableNotificationContent()
        switch alert {
        case .low(let percent):
            content.title = "Battery Low"
            content.body = "\(Format.percent(percent)) left. Connect your Mac to power."
        case .charged(let percent):
            content.title = percent >= 100 ? "Battery Charged" : "Battery at \(Format.percent(percent))"
            content.body = "You can unplug your Mac."
        }
        content.sound = .default
        // One identifier per kind, so a new alert replaces the last instead of stacking.
        let id = if case .low = alert { "low" } else { "charged" }
        center?.add(UNNotificationRequest(identifier: id, content: content, trigger: nil)) { error in
            if let error { NSLog("Common Battery: could not post notification: \(error.localizedDescription)") }
        }
    }
}
