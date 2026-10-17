import AppKit
import ApplicationServices

/// A privacy permission an app needs before it can do its job, and why, in the app's words.
public struct Permission: Sendable, Equatable {
    public enum Kind: Sendable {
        case accessibility
        case screenRecording
    }

    public let kind: Kind
    /// Finishes "<App> needs <name> access …": "to see what you type and fix it".
    public let reason: String

    public init(_ kind: Kind, reason: String) {
        self.kind = kind
        self.reason = reason
    }

    public static func accessibility(reason: String) -> Permission { .init(.accessibility, reason: reason) }
    public static func screenRecording(reason: String) -> Permission { .init(.screenRecording, reason: reason) }

    /// As System Settings names the pane.
    public var name: String {
        switch kind {
        case .accessibility: "Accessibility"
        case .screenRecording: "Screen Recording"
        }
    }

    /// Asked of the system each time, so a window can poll it while the user flips the switch.
    public var isGranted: Bool {
        switch kind {
        case .accessibility: AXIsProcessTrusted()
        case .screenRecording: CGPreflightScreenCaptureAccess()
        }
    }

    /// The pane in System Settings › Privacy & Security.
    public var settingsURL: URL {
        let pane =
            switch kind {
            case .accessibility: "Privacy_Accessibility"
            case .screenRecording: "Privacy_ScreenCapture"
            }
        return URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)")!
    }

    /// The service's name to `tccutil`.
    var service: String {
        switch kind {
        case .accessibility: "Accessibility"
        case .screenRecording: "ScreenCapture"
        }
    }

    /// Screen Recording is read when the app starts: a switch turned on while it runs applies only
    /// after it reopens, and `isGranted` stays false until then.
    public var appliesAfterReopen: Bool { kind == .screenRecording }

    /// Why a switch can be on and still not work, in one sentence. macOS keeps a grant for the
    /// signature it was given to; a copy signed differently (an older build, an ad hoc one) leaves a
    /// record that shows the switch on but doesn't apply to this copy, and flipping it keeps the old one.
    public func staleSwitchNote(app: String) -> String {
        "If \(app) is already on in System Settings, that switch belongs to an earlier copy."
    }

    /// For Screen Recording, what to do once the switch is on; nil when it applies at once.
    public func reopenNote(app: String) -> String? {
        appliesAfterReopen ? "macOS applies the switch only after \(app) reopens." : nil
    }

    /// Runs a program to its end and returns its exit status. Injected so tests never touch the
    /// privacy database.
    public typealias Runner = @Sendable (_ executable: URL, _ arguments: [String]) throws -> Int32

    /// The command that removes every record of this permission for `bundleID`, stale ones included.
    func resetCommand(bundleID: String) -> (executable: URL, arguments: [String]) {
        (URL(fileURLWithPath: "/usr/bin/tccutil"), ["reset", service, bundleID])
    }

    /// Removes this app's own records of the permission, so a switch left by an earlier copy stops
    /// standing in for this one. Only the app's own bundle identifier is ever passed.
    public func reset(bundleID: String? = Bundle.main.bundleIdentifier, run: Runner = Self.runToEnd) throws {
        guard let bundleID else { throw ResetError.noBundleIdentifier }
        let command = resetCommand(bundleID: bundleID)
        let status = try run(command.executable, command.arguments)
        guard status == 0 else { throw ResetError.failed(status: status) }
    }

    /// Clears the stale record, then asks again: the system prompt, and the pane with the app back in
    /// its list and its switch off.
    public func resetAndRequest() throws {
        try reset()
        request()
    }

    public enum ResetError: LocalizedError, Equatable {
        case noBundleIdentifier
        case failed(status: Int32)

        public var errorDescription: String? {
            switch self {
            case .noBundleIdentifier: "This copy has no bundle identifier, so there is no record to reset."
            case .failed(let status): "tccutil couldn't reset the permission (exit status \(status))."
            }
        }
    }

    public static let runToEnd: Runner = { executable, arguments in
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }

    /// Puts the app in the pane's list (an app only appears there after it has asked once), shows the
    /// system's own prompt, and opens the pane so the switch is right there.
    public func request() {
        switch kind {
        case .accessibility:
            // kAXTrustedCheckOptionPrompt by its value: the global isn't concurrency-safe under Swift 6.
            AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        case .screenRecording:
            CGRequestScreenCaptureAccess()
        }
        NSWorkspace.shared.open(settingsURL)
    }
}
