import AppKit
import CommandKit
import CommonKit
import CommonUI
import SwiftUI

/// Laid out by the Common Tools Settings standard: the app's own sections, then General, then
/// `CommonToolsSection`, so every app's Settings window reads the same.
struct SettingsView: View {
    let controller: AppController
    @Bindable var preferences: Preferences
    @State private var loginError: String?

    private static let height: CGFloat = 720
    private static let commandSpace = KeyCombo(keyCode: 49, modifiers: .command)
    private static let keyboardShortcuts = URL(
        string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension")!

    var body: some View {
        Form {
            Section {
                PanelPreview(
                    panel: controller.panel, size: preferences.size, translucent: preferences.translucent,
                    theme: preferences.theme, visibleRows: preferences.visibleRows, width: 400
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, Tokens.Space.xs)
                .listRowBackground(Color.clear)
            }

            Section {
                LabeledContent("Open Common Command") {
                    ShortcutRecorder(controller: controller, combo: $preferences.hotKey)
                }
            } header: {
                Text("Shortcut")
            } footer: {
                VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                    if let conflict = Conflicts.holder(of: preferences.hotKey, among: controller.otherShortcuts) {
                        Text(
                            "\(preferences.hotKey.displayName) also opens \(conflict.owner), so only one of them will. Change it in \(conflict.whereToChange), or choose another shortcut here."
                        )
                        .foregroundStyle(.orange)
                    } else if let problem = controller.hotKeyProblem {
                        Text(problem).foregroundStyle(Tokens.Color.danger.color)
                    }
                    if let spaceHolder = Conflicts.holder(of: Self.commandSpace, among: controller.otherShortcuts),
                        preferences.hotKey != Self.commandSpace
                    {
                        SettingsFootnote(
                            "⌘Space belongs to \(spaceHolder.owner). To use it here, change it in \(spaceHolder.whereToChange) first."
                        )
                    }
                    // The button only helps when the clash is Spotlight's; Alfred's is changed in Alfred.
                    let involved = [preferences.hotKey, Self.commandSpace].compactMap {
                        Conflicts.holder(of: $0, among: controller.otherShortcuts)
                    }
                    if involved.contains(where: { $0.owner.hasPrefix("Spotlight") }) {
                        Button("Open Keyboard Shortcuts…") { NSWorkspace.shared.open(Self.keyboardShortcuts) }
                            .buttonStyle(.link)
                    }
                }
                .font(.callout)
            }

            Section("Appearance") {
                Picker("Theme", selection: $preferences.theme) {
                    Text("System").tag(Theme.system)
                    Text("Light").tag(Theme.light)
                    Text("Dark").tag(Theme.dark)
                }
                .pickerStyle(.segmented)
                Picker("Size", selection: $preferences.size) {
                    Text("Small").tag(PanelSize.small)
                    Text("Medium").tag(PanelSize.medium)
                    Text("Large").tag(PanelSize.large)
                }
                .pickerStyle(.segmented)
                Toggle("Translucent", isOn: $preferences.translucent)
                LabeledContent("Results shown") {
                    Stepper(value: $preferences.visibleRows, in: Preferences.visibleRowsRange) {
                        Text("\(preferences.visibleRows)").monospacedDigit()
                    }
                }
            }

            Section {
                Toggle("System Settings", isOn: $preferences.searchesSettings)
                Toggle("Files and folders", isOn: $preferences.searchesFiles)
                Toggle("Calculator and conversions", isOn: $preferences.calculates)
                Toggle("Shortcuts and app actions", isOn: $preferences.searchesActions)
                Toggle("Web search", isOn: $preferences.searchesWeb)
                Picker("Search engine", selection: $preferences.engine) {
                    ForEach(SearchEngine.allCases) { Text($0.name).tag($0) }
                }
                .disabled(!preferences.searchesWeb)
            } header: {
                Text("Search")
            } footer: {
                SettingsFootnote(
                    "Apps are always searched. Files come from the Spotlight index of your home folder. ⌘1, ⌘2, and ⌘3 search only apps, files, or actions, whatever is switched off here."
                )
            }

            Section {
                OpenAtLoginToggle(error: $loginError)
                Toggle("Show in menu bar", isOn: $preferences.showsMenuBarItem)
            } header: {
                Text("General")
            } footer: {
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    if let loginError { SettingsFootnote(loginError) }
                    if !preferences.showsMenuBarItem {
                        SettingsFootnote("Open Common Command from Finder again to get back to Settings.")
                    }
                }
            }

            CommonToolsSection()
        }
        // Not `.settingsForm()`: that sizes the window to its sections, and with the preview on top these run
        // to about 1,700 points, taller than any screen. The family's width, and a height that scrolls.
        .formStyle(.grouped)
        .frame(width: Tokens.Layout.settingsWidth, height: Self.height)
        .onChange(of: preferences.theme) { controller.preferencesChanged() }
        .onChange(of: preferences.size) { controller.preferencesChanged() }
        .onChange(of: preferences.translucent) { controller.preferencesChanged() }
        .onChange(of: preferences.showsMenuBarItem) { controller.preferencesChanged() }
    }
}

/// Click, then press the new shortcut. Escape cancels, Delete restores the default.
struct ShortcutRecorder: View {
    let controller: AppController
    @Binding var combo: KeyCombo
    @State private var recording = false
    @State private var monitor: Any?
    @State private var hint: String?

    var body: some View {
        HStack(spacing: Tokens.Space.xs) {
            if let hint { SettingsFootnote(hint) }
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
