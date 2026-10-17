import AppKit
import ServiceManagement
import SwiftUI

/// The window every app's Settings opens in: titled and closable only, sized by its content,
/// centred the first time, and kept so it reopens where it was. The view is rebuilt on each show,
/// so a toggle that mirrors state kept elsewhere (Open at login) is read afresh.
///
///     let settings = SettingsWindowHost(title: "Common Bar Settings")
///     settings.show { SettingsView() }
@MainActor
public final class SettingsWindowHost {
    private let title: String
    private var window: NSWindow?

    public init(title: String) {
        self.title = title
    }

    public func show<Content: View>(@ViewBuilder content: () -> Content) {
        let host = NSHostingController(rootView: content())
        host.sizingOptions = .preferredContentSize
        if let window {
            window.contentViewController = host
        } else {
            let window = NSWindow(contentViewController: host)
            window.title = title
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        // Activation is cooperative since macOS 14: the system may decline it, and an accessory
        // app's window would then open behind the frontmost app. Ordering front regardless keeps
        // it visible either way.
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
    }
}

extension View {
    /// The shape of every Common Tools Settings form: System Settings' grouped style at the family's
    /// width, as tall as its sections. Apply it to the `Form` itself.
    ///
    ///     Form {
    ///         Section("Shortcuts") { … }
    ///         Section("General") { OpenAtLoginToggle() }
    ///         CommonToolsSection()
    ///     }
    ///     .settingsForm()
    public func settingsForm() -> some View {
        formStyle(.grouped)
            .frame(width: Tokens.Layout.settingsWidth)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A section's explanatory footer, in the one style the apps share.
///
///     Section { … } footer: { SettingsFootnote("Kept on this Mac only.") }
public struct SettingsFootnote: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text).font(.callout).foregroundStyle(.secondary)
    }
}

/// "Open at login", the first row of every app's General section. It registers the app as a login
/// item and, when macOS declines, puts the reason where the row's footer would be and leaves the
/// toggle showing what is true.
///
///     Section {
///         OpenAtLoginToggle(error: $loginError)
///     } header: { Text("General") } footer: {
///         SettingsFootnote(loginError ?? "Starts when you log in.")
///     }
public struct OpenAtLoginToggle: View {
    @Binding private var error: String?
    @State private var enabled = LoginItem.isEnabled

    public init(error: Binding<String?>) {
        _error = error
    }

    public var body: some View {
        Toggle("Open at login", isOn: $enabled)
            .onChange(of: enabled) { _, wanted in
                guard wanted != LoginItem.isEnabled else { return }
                do {
                    try LoginItem.setEnabled(wanted)
                    error = nil
                } catch {
                    self.error = error.localizedDescription
                    enabled = LoginItem.isEnabled
                }
            }
    }
}

/// The app as a login item, through `SMAppService`, which needs no helper and no permission.
public enum LoginItem {
    public static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    public static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
