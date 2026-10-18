import AppKit
import BatteryKit
import CommonKit
import CommonUI
import SwiftUI

/// Laid out by the Common Tools Settings standard: the app's own sections, then General, then
/// `CommonToolsSection`, so every app's Settings window reads the same.
struct SettingsView: View {
    let controller: AppController
    @Bindable var preferences: Preferences
    let state: BatteryState
    @State private var loginProblem: LoginItem.Problem?
    @State private var notificationsBlocked = false

    var body: some View {
        Form {
            Section {
                BarEditor(preferences: preferences, reading: state.reading)
                Toggle("Color when low or in Low Power Mode", isOn: $preferences.appearance.colorsAlerts)
            } header: {
                Text("Menu Bar")
            } footer: {
                VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                    if !state.barVisible {
                        SettingsFootnote(
                            "Common Battery is running but can’t be seen in the menu bar. It may be behind the camera housing or hidden by a menu bar manager. Hold ⌘ and drag other menu bar items out of the way.",
                            symbol: "eye.slash"
                        )
                    }
                    SettingsFootnote(
                        "Time remaining shows while the battery charges or drains. On power, the icon shows a plug; without the icon, a plug takes the time’s place."
                    )
                    SettingsFootnote(
                        "Time remaining learns from how you use your Mac, so it holds steady when you start something brief and knows your usual day. What it learns stays on this Mac."
                    )
                }
            }

            Section {
                LabeledRow("System battery icon") {
                    Button("Open Control Center Settings…") { controller.openControlCenterSettings() }
                }
            } footer: {
                SettingsFootnote("To keep one battery in the menu bar, set Battery to Don’t Show in Menu Bar there.")
            }

            Section {
                Picker("Warn at", selection: $preferences.lowAlert) {
                    ForEach(Preferences.lowAlerts, id: \.self) { Text($0 == 0 ? "Never" : Format.percent($0)) }
                }
                Picker("Tell me when charged to", selection: $preferences.chargedAlert) {
                    ForEach(Preferences.chargedAlerts, id: \.self) { Text($0 == 0 ? "Never" : Format.percent($0)) }
                }
            } header: {
                Text("Notifications")
            } footer: {
                if notificationsBlocked {
                    SettingsFootnote(
                        "macOS isn’t delivering Common Battery’s notifications. If Common Battery is listed in System Settings › Notifications, allow it there."
                    )
                } else {
                    SettingsFootnote(
                        "Each notification comes once, and again only after the battery has moved back past its level.")
                }
            }

            Section {
                OpenAtLoginToggle(problem: $loginProblem)
                UpdateCheckToggle(updates: controller.updates)
            } header: {
                Text("General")
            } footer: {
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    OpenAtLoginFootnote(loginProblem)
                    UpdateCheckFootnote(updates: controller.updates)
                }
            }

            CommonToolsSection()
        }
        .settingsForm()
        .onChange(of: preferences.appearance) { controller.preferencesChanged() }
        .onChange(of: preferences.notifies) { controller.preferencesChanged() }
        .task { notificationsBlocked = await controller.notificationsBlocked }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { notificationsBlocked = await controller.notificationsBlocked }
        }
    }
}
