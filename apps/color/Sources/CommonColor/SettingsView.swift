import ColorKit
import CommonKit
import CommonShortcut
import CommonUI
import SwiftUI

/// Laid out by the Common Tools Settings standard: the app's own sections, then General, then
/// `CommonToolsSection`, so every app's Settings window reads the same.
struct SettingsView: View {
    @Bindable var preferences: Preferences
    let updates: UpdateCheck
    /// While a new shortcut is recorded, the old one is let go of.
    var suspendShortcut: () -> Void = {}
    /// Registers the shortcut again and says what stood in the way, if anything did.
    var resumeShortcut: () -> String? = { nil }
    @State var hotKeyProblem: String?
    @State private var loginProblem: LoginItem.Problem?

    /// What the footnote shows the format with: a mid blue every format can hold exactly.
    private static let example = ColorValue(.sRGB, red: 58 / 255, green: 123 / 255, blue: 213 / 255)

    var body: some View {
        Form {
            Section {
                LabeledRow("Pick a color") {
                    ShortcutRecorder(
                        combo: $preferences.hotKey, standard: Preferences.standardHotKey,
                        suspend: suspendShortcut, resume: { hotKeyProblem = resumeShortcut() })
                }
            } header: {
                Text("Shortcut")
            } footer: {
                VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                    if let hotKeyProblem {
                        SettingsFootnote(hotKeyProblem, tone: .danger)
                    }
                    SettingsFootnote("Click any pixel to pick it, or press Escape to leave everything as it was.")
                }
            }

            Section {
                Picker("Copy as", selection: $preferences.format) {
                    ForEach(ColorFormat.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                Toggle("Show what was copied", isOn: $preferences.confirmsCopies)
            } header: {
                Text("Copying")
            } footer: {
                SettingsFootnote(
                    "A pick is copied as \(preferences.format.string(Self.example)). In the menu, press 1 to 7 for the other formats."
                )
            }

            Section {
                OpenAtLoginToggle(problem: $loginProblem)
                UpdateCheckToggle(updates: updates)
            } header: {
                Text("General")
            } footer: {
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    OpenAtLoginFootnote(loginProblem)
                    UpdateCheckFootnote(updates: updates)
                }
            }

            CommonToolsSection()
        }
        .settingsForm()
    }
}
