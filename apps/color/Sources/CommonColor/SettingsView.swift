import ColorKit
import CommonKit
import CommonShortcut
import CommonUI
import SwiftUI

/// Laid out by the Common Tools Settings standard: the app's own sections, then General, then
/// `CommonToolsSection`, so every app's Settings window reads the same.
struct SettingsView: View {
    let controller: AppController
    @Bindable var preferences: Preferences
    @State private var loginProblem: LoginItem.Problem?
    @State private var hotKeyProblem: String?

    /// What the footnote shows each format with: a mid blue every format can hold exactly.
    private static let example = ColorValue(.sRGB, red: 58 / 255, green: 123 / 255, blue: 213 / 255)

    var body: some View {
        Form {
            Section {
                LabeledRow("Pick a color") {
                    ShortcutRecorder(
                        combo: $preferences.hotKey, standard: Preferences.standardHotKey,
                        suspend: { controller.suspendHotKey() },
                        resume: {
                            controller.registerHotKey()
                            hotKeyProblem = controller.hotKeyProblem
                        })
                }
                Picker("Copy as", selection: $preferences.format) {
                    ForEach(ColorFormat.allCases, id: \.self) { Text($0.title).tag($0) }
                }
            } header: {
                Text("Picking")
            } footer: {
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    if let hotKeyProblem {
                        SettingsFootnote(hotKeyProblem, tone: .danger)
                    }
                    SettingsFootnote(
                        "Click any pixel to pick it; Escape cancels. A pick is copied as \(preferences.format.string(Self.example)), and the menu has every other format."
                    )
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
        .onAppear { hotKeyProblem = controller.hotKeyProblem }
    }
}
