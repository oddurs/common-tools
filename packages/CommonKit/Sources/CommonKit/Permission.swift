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
