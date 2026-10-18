import AppKit
import CommonKit
import CommonUI
import ShotKit
import SwiftUI

/// Laid out by the Common Tools Settings standard: the app's own sections, then General, then
/// `CommonToolsSection`, so every app's Settings window reads the same.
struct SettingsView: View {
    let controller: AppController
    @Bindable var preferences: Preferences
    @State private var loginProblem: LoginItem.Problem?
    @State private var hasAccess = Capture.hasAccess
    @State private var historyCount = 0

    var body: some View {
        Form {
            Section {
                LabeledRow("Take a screenshot") {
                    ShortcutRecorder(controller: controller, combo: $preferences.hotKey)
                }
            } header: {
                Text("Shortcut")
            } footer: {
                VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                    if let problem = controller.hotKeyProblem {
                        SettingsFootnote(problem, tone: .danger)
                    }
                    SettingsFootnote(
                        "Drag for an area, click for a window, Return for the whole screen, Escape to cancel.")
                }
            }

            Section {
                LabeledRow("Screen Recording") {
                    if hasAccess {
                        Label("Allowed", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(Tokens.Color.success.color)
                    } else {
                        Button("Open System Settings") { controller.openScreenRecordingSettings() }
                    }
                }
                if !hasAccess {
                    HStack {
                        Button("Reset and Ask Again") { controller.resetScreenRecording() }
                        Button("Quit and Reopen") { controller.reopen() }
                    }
                }
            } header: {
                Text("Access")
            } footer: {
                if !hasAccess {
                    SettingsFootnote(
                        "Turn on Common Shot under Screen & System Audio Recording. "
                            + [
                                AppController.permission.reopenNote(app: "Common Shot") ?? "",
                                AppController.permission.staleSwitchNote(app: "Common Shot"),
                            ].joined(separator: " ")
                    )
                }
            }

            Section {
                Picker("Size", selection: $preferences.imageSize) {
                    Text("For prompts").tag(ImageSize.prompt)
                    Text("Full resolution").tag(ImageSize.full)
                }
                .pickerStyle(.segmented)
                Toggle("Show a preview", isOn: $preferences.showsPreview)
                Toggle("Play the screenshot sound", isOn: $preferences.playsSound)
            } header: {
                Text("Image")
            } footer: {
                SettingsFootnote(
                    preferences.imageSize == .prompt
                        ? "Every shot is copied as PNG with its long edge at most \(ImageSize.promptLongEdge) px. A full screen costs Claude about 2,100 tokens instead of 4,800, and smaller crops are untouched."
                        : "Every shot is copied as PNG at the display's full resolution."
                )
            }

            Section {
                Picker("Keep", selection: $preferences.historyLimit) {
                    ForEach(Preferences.historyLimits, id: \.self) { limit in
                        Text(limit == 0 ? "None" : "Last \(limit) shots").tag(limit)
                    }
                }
                HStack {
                    Button("Show in Finder") { controller.showHistoryInFinder() }
                    Button("Clear History") {
                        controller.clearHistory()
                        historyCount = 0
                    }
                    .disabled(historyCount == 0)
                }
            } header: {
                Text("History")
            } footer: {
                SettingsFootnote("Recent shots appear in the menu bar menu. Click one to copy it again.")
            }

            Section {
                Toggle("Show in menu bar", isOn: $preferences.showsMenuBarItem)
                OpenAtLoginToggle(problem: $loginProblem)
                UpdateCheckToggle(updates: controller.updates)
            } header: {
                Text("General")
            } footer: {
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    OpenAtLoginFootnote(loginProblem)
                    UpdateCheckFootnote(updates: controller.updates)
                    if !preferences.showsMenuBarItem {
                        SettingsFootnote("Open Common Shot from Finder again to get back to Settings.")
                    }
                }
            }

            CommonToolsSection()
        }
        .settingsForm()
        .onChange(of: preferences.showsMenuBarItem) { controller.preferencesChanged() }
        .onChange(of: preferences.historyLimit) {
            controller.historyLimitChanged()
            historyCount = controller.history.shots.count
        }
        .onAppear { historyCount = controller.history.shots.count }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            hasAccess = Capture.hasAccess
        }
    }
}

/// Click, then press the new shortcut. Escape cancels, Delete restores ⇧⌘2.
struct ShortcutRecorder: View {
    let controller: AppController
    @Binding var combo: KeyCombo
    @State private var recording = false
    @State private var monitor: Any?
    @State private var hint: String?

    var body: some View {
        HStack(spacing: Tokens.Space.xs) {
            if let hint { Text(hint).font(.callout).foregroundStyle(.secondary) }
            Button {
                recording ? stop() : start()
            } label: {
                Text(recording ? "Type Shortcut…" : combo.displayName)
                    .monospacedDigit()
                    // Wide enough for "Type Shortcut…", so the button holds still while it records.
                    .frame(minWidth: 110)
            }
        }
        .onDisappear { stop() }
    }

    private func start() {
        controller.suspendHotKey()
        recording = true
        hint = nil
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let keyCode = event.keyCode
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
            MainActor.assumeIsolated { record(keyCode: keyCode, flags: flags) }
            // Swallowed, so the key doesn't also reach the Settings window.
            return nil
        }
    }

    private func record(keyCode: UInt16, flags: UInt) {
        switch keyCode {
        case 53:  // Escape
            stop()
        case 51, 117:  // Delete, Forward Delete
            combo = .standard
            stop()
        default:
            let candidate = KeyCombo(keyCode: keyCode, modifiers: KeyCombo.Modifiers(rawValue: flags))
            guard candidate.isUsable else {
                hint = "Add ⌘, ⌥, or ⌃"
                return
            }
            combo = candidate
            stop()
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        guard recording else { return }
        recording = false
        hint = nil
        controller.registerHotKey()
    }
}
