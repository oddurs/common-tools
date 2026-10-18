import CommonKit
import CommonUI
import SwiftUI

/// Laid out by the Common Tools Settings standard: the app's own sections, then General, then
/// `CommonToolsSection`, so the apps' Settings windows read the same.
struct SettingsView: View {
    @AppStorage(MenuBarController.showsFolderNamesKey) private var showsFolderNames = true
    @State private var loginProblem: LoginItem.Problem?
    let updates: UpdateCheck

    var body: some View {
        Form {
            Section {
                Toggle("Show folder names in the menu bar", isOn: $showsFolderNames)
                // Read each second: the switch is flipped in System Settings, not here.
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    let permission = MenuBarController.accessibility
                    LabeledContent(permission.name) {
                        if permission.isGranted {
                            Text("Allowed")
                        } else {
                            Button("Open System Settings…") { NSWorkspace.shared.open(permission.settingsURL) }
                        }
                    }
                }
            } header: {
                Text("Folders")
            } footer: {
                SettingsFootnote(
                    "Icons left of the More folder stay off-screen and wait in it. Common Bar needs Accessibility \(MenuBarController.accessibility.reason); it asks the first time you open the folder."
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
