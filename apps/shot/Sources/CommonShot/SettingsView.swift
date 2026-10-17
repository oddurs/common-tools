import AppKit
import ShotKit
import SwiftUI

/// Laid out by the Common Tools Settings standard: the app's own sections, then General, then
/// `CommonToolsSection`, so every app's Settings window reads the same.
struct SettingsView: View {
    let controller: AppController
    @Bindable var preferences: Preferences
    @State private var openAtLogin = LoginItem.isEnabled
    @State private var loginError: String?
    @State private var hasAccess = Capture.hasAccess
    @State private var historyCount = 0

    var body: some View {
        Form {
            Section {
                LabeledContent("Take a screenshot") {
                    ShortcutRecorder(controller: controller, combo: $preferences.hotKey)
                }
            } header: {
                Text("Shortcut")
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    if let problem = controller.hotKeyProblem {
                        Text(problem).foregroundStyle(.red)
                    }
                    Text("Drag for an area, click for a window, Return for the whole screen, Escape to cancel.")
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
            }

            Section {
                LabeledContent("Screen Recording") {
                    if hasAccess {
                        Label("Allowed", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("Open Privacy & Security…") { controller.openScreenRecordingSettings() }
                    }
                }
            } header: {
                Text("Access")
            } footer: {
                if !hasAccess {
                    Text(
                        "Turn on Common Shot under Screen & System Audio Recording, then quit and reopen it. If it's already on, remove it with − and add it again: that switch is for an earlier copy."
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
            }

            Section {
                Picker("Size", selection: $preferences.imageSize) {
                    Text("For prompts").tag(ImageSize.prompt)
                    Text("Full resolution").tag(ImageSize.full)
                }
                .pickerStyle(.segmented)
                Toggle("Show a preview", isOn: $preferences.showsPreview)
            } header: {
                Text("Image")
            } footer: {
                Text(
                    preferences.imageSize == .prompt
                        ? "Every shot is copied as PNG with its long edge at most \(ImageSize.promptLongEdge) px. A full screen costs Claude about 2,100 tokens instead of 4,800, and smaller crops are untouched."
                        : "Every shot is copied as PNG at the display's full resolution."
                )
                .font(.callout)
                .foregroundStyle(.secondary)
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
                Text("Recent shots appear in the menu bar menu. Click one to copy it again.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Show in menu bar", isOn: $preferences.showsMenuBarItem)
                Toggle("Open at login", isOn: $openAtLogin)
            } header: {
                Text("General")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    if !preferences.showsMenuBarItem {
                        Text("Open Common Shot from Finder again to get back to Settings.")
                    }
                    if let loginError { Text(loginError) }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            CommonToolsSection()
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 720)
        .onChange(of: preferences.showsMenuBarItem) { controller.preferencesChanged() }
        .onChange(of: preferences.historyLimit) {
            controller.historyLimitChanged()
            historyCount = controller.history.shots.count
        }
        .onAppear { historyCount = controller.history.shots.count }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            hasAccess = Capture.hasAccess
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

/// Click, then press the new shortcut. Escape cancels, Delete restores ⇧⌘2.
struct ShortcutRecorder: View {
    let controller: AppController
    @Binding var combo: KeyCombo
    @State private var recording = false
    @State private var monitor: Any?
    @State private var hint: String?

    var body: some View {
        HStack(spacing: 8) {
            if let hint { Text(hint).font(.callout).foregroundStyle(.secondary) }
            Button {
                recording ? stop() : start()
            } label: {
                Text(recording ? "Type Shortcut…" : combo.displayName)
                    .monospacedDigit()
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
