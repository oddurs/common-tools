import CommonKit
import CommonUI
import SwiftUI

// The same two views in every app, until CommonKit's UpdateCheck offers a Settings row of its own.

/// "Check for updates daily", the row after Open at login in General. Off until turned on; turning it
/// on runs the first check at once rather than at the next launch.
struct UpdateCheckToggle: View {
    private let updates: UpdateCheck
    // Mirrored in state: `isEnabled` is a preference, not an observed property, so a binding straight
    // to it would leave the toggle's accessibility value behind what it shows.
    @State private var enabled: Bool

    init(updates: UpdateCheck) {
        self.updates = updates
        _enabled = State(initialValue: updates.isEnabled)
    }

    var body: some View {
        Toggle("Check for updates daily", isOn: $enabled)
            .onChange(of: enabled) { _, on in
                guard on != updates.isEnabled else { return }
                updates.isEnabled = on
                Task { await updates.checkIfDue() }
            }
    }
}

/// Under the General footnote: the newer version once a check has found one, or why the last check
/// failed. Nothing while there is nothing to say.
struct UpdateCheckFootnote: View {
    let updates: UpdateCheck

    var body: some View {
        if let update = updates.available {
            Link("Version \(update.version.description) is available", destination: update.download ?? update.page)
                .font(.callout)
        } else if let problem = updates.lastError {
            SettingsFootnote(problem)
        }
    }
}
