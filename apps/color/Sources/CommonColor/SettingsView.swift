import CommonKit
import CommonUI
import SwiftUI

/// Laid out by the Common Tools Settings standard: the app's own sections, then General, then
/// `CommonToolsSection`, so every app's Settings window reads the same.
struct SettingsView: View {
    let controller: AppController
    @State private var loginProblem: LoginItem.Problem?

    var body: some View {
        Form {
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
    }
}
