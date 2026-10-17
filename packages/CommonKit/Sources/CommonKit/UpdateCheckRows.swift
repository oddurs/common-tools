import CommonUI
import SwiftUI

/// "Check for updates daily", the row after Open at login in every app's General section. Off until
/// turned on; turning it on runs the first check at once rather than at the next launch.
///
///     Section {
///         OpenAtLoginToggle(problem: $loginProblem)
///         UpdateCheckToggle(updates: updates)
///     } header: { Text("General") } footer: {
///         OpenAtLoginFootnote(loginProblem)
///         UpdateCheckFootnote(updates: updates)
///     }
public struct UpdateCheckToggle: View {
    public static let label = "Check for updates daily"

    private let updates: UpdateCheck
    // Mirrored in state: `isEnabled` is a preference, not an observed property, so a binding straight
    // to it would leave the toggle's accessibility value behind what it shows.
    @State private var enabled: Bool

    public init(updates: UpdateCheck) {
        self.updates = updates
        _enabled = State(initialValue: updates.isEnabled)
    }

    public var body: some View {
        Toggle(Self.label, isOn: $enabled)
            .onChange(of: enabled) { _, on in Self.apply(on, to: updates) }
    }

    /// What flipping the toggle does: records the choice at once and, when it was turned on, checks
    /// now. Returns the check, so a test can wait for it; nil when nothing changed.
    @discardableResult
    static func apply(_ on: Bool, to updates: UpdateCheck) -> Task<Void, Never>? {
        guard on != updates.isEnabled else { return nil }
        updates.isEnabled = on
        return Task { await updates.checkIfDue() }
    }
}

/// Under the General footnote: the newer version once a check has found one, or why the last check
/// failed. Nothing while there is nothing to say.
public struct UpdateCheckFootnote: View {
    /// What the footnote shows, when it shows anything.
    enum Content: Equatable {
        /// A newer release: the line to show, and where it leads (the zip when the release has one).
        case available(String, URL)
        case problem(String)
    }

    private let updates: UpdateCheck

    public init(updates: UpdateCheck) {
        self.updates = updates
    }

    public var body: some View {
        switch Self.content(of: updates) {
        case .available(let line, let destination):
            Link(line, destination: destination).font(.callout)
        case .problem(let problem):
            SettingsFootnote(problem)
        case nil:
            EmptyView()
        }
    }

    static func content(of updates: UpdateCheck) -> Content? {
        if let update = updates.available {
            return .available("Version \(update.version) is available", update.download ?? update.page)
        }
        if let problem = updates.lastError {
            return .problem(problem)
        }
        return nil
    }
}
