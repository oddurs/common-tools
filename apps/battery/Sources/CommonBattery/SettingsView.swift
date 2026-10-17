import AppKit
import BatteryKit
import CommonKit
import SwiftUI

/// Laid out by the Common Tools Settings standard: the app's own sections, then General, then
/// `CommonToolsSection`, so every app's Settings window reads the same.
struct SettingsView: View {
    let controller: AppController
    @Bindable var preferences: Preferences
    let state: BatteryState
    @State private var openAtLogin = LoginItem.isEnabled
    @State private var loginError: String?
    @State private var notificationsBlocked = false

    var body: some View {
        Form {
            Section {
                BarPreview(appearance: preferences.appearance, reading: state.reading)
                Picker("Style", selection: $preferences.style) {
                    ForEach(BarStyle.allCases, id: \.self) { Text($0.name) }
                }
                Toggle("Show time remaining", isOn: $preferences.showsTime)
                Toggle("Color when low or in Low Power Mode", isOn: $preferences.colorsAlerts)
            } header: {
                Text("Menu Bar")
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    if !state.barVisible {
                        Label {
                            Text(
                                "Common Battery is running but can’t be seen in the menu bar. It may be behind the camera housing or hidden by a menu bar manager. Hold ⌘ and drag other menu bar items out of the way."
                            )
                        } icon: {
                            Image(systemName: "eye.slash")
                        }
                    }
                    Text(
                        "Time remaining learns from how you use your Mac, so it holds steady when you start something brief and knows your usual day. What it learns stays on this Mac."
                    )
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent("System battery icon") {
                    Button("Open Control Center Settings…") { controller.openControlCenterSettings() }
                }
            } footer: {
                Text("To keep one battery in the menu bar, set Battery to Don’t Show in Menu Bar there.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
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
                Group {
                    if notificationsBlocked {
                        Text(
                            "macOS isn’t delivering Common Battery’s notifications. If Common Battery is listed in System Settings › Notifications, allow it there."
                        )
                    } else {
                        Text(
                            "Each notification comes once, and again only after the battery has moved back past its level."
                        )
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Open at login", isOn: $openAtLogin)
            } header: {
                Text("General")
            } footer: {
                if let loginError {
                    Text(loginError).font(.callout).foregroundStyle(.secondary)
                }
            }

            CommonToolsSection()
        }
        .formStyle(.grouped)
        // Fixed, and scrolling past it: seven Common Tools rows make the form taller than a 13-inch screen.
        .frame(width: 460, height: 720)
        .onChange(of: preferences.appearance) { controller.preferencesChanged() }
        .onChange(of: preferences.notifies) { controller.preferencesChanged() }
        .task { notificationsBlocked = await controller.notificationsBlocked }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { notificationsBlocked = await controller.notificationsBlocked }
        }
        .onChange(of: openAtLogin) { _, enabled in
            guard enabled != LoginItem.isEnabled else { return }
            do {
                try LoginItem.setEnabled(enabled)
                loginError = nil
            } catch {
                loginError = error.localizedDescription
                openAtLogin = LoginItem.isEnabled
            }
        }
    }
}

/// The item as it looks right now, on a strip of menu bar, so a style can be judged before leaving Settings.
private struct BarPreview: View {
    let appearance: BarAppearance
    let reading: BatteryReading?

    var body: some View {
        HStack {
            Spacer()
            Image(nsImage: BarRenderer(appearance: appearance, height: 24).image(reading))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .accessibilityElement()
        .accessibilityLabel("Preview: \(BarRenderer.accessibilityText(reading))")
    }
}
