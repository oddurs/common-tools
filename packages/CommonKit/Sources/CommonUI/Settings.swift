import AppKit
import ServiceManagement
import SwiftUI

/// The window every app's Settings opens in: titled and closable only, sized by its content,
/// centred the first time, and kept so it reopens where it was. The view is rebuilt on each show,
/// so a toggle that mirrors state kept elsewhere (Open at login) is read afresh.
///
/// The host tells the form how tall it may grow: the visible height of the screen the window is
/// on, less the title bar, so a long Settings scrolls instead of running off the bottom. The
/// window is sized by SwiftUI after it is placed, and grows downward, so the host also moves it
/// back up whenever a resize would push its bottom edge off the screen.
///
///     let settings = SettingsWindowHost(title: "Common Bar Settings")
///     settings.show { SettingsView() }
@MainActor
public final class SettingsWindowHost: NSObject, NSWindowDelegate {
    private static let styleMask: NSWindow.StyleMask = [.titled, .closable]
    private let title: String
    private var window: NSWindow?

    public init(title: String) {
        self.title = title
        super.init()
    }

    public func show<Content: View>(@ViewBuilder content: () -> Content) {
        // A reopened window is on its own screen; a new one is centred on the main screen.
        let screen = window?.screen ?? NSScreen.main ?? NSScreen.screens.first
        let host = NSHostingController(
            rootView: content().environment(\.settingsFormHeightLimit, Self.fittingHeight(on: screen)))
        host.sizingOptions = .preferredContentSize
        if let window {
            window.contentViewController = host
        } else {
            let window = NSWindow(contentViewController: host)
            window.title = title
            window.styleMask = Self.styleMask
            window.isReleasedWhenClosed = false
            window.delegate = self
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

    public func windowDidResize(_ notification: Notification) {
        guard let window, let visible = window.screen?.visibleFrame else { return }
        var frame = window.frame
        frame.origin.y = max(visible.minY, min(frame.minY, visible.maxY - frame.height))
        if frame.origin != window.frame.origin { window.setFrameOrigin(frame.origin) }
    }

    /// How tall a form may be on `screen`: what is left of the visible frame (under the menu bar,
    /// above the Dock) once the title bar has its share.
    static func fittingHeight(on screen: NSScreen?) -> CGFloat? {
        guard let screen else { return nil }
        let titleBar = NSWindow.frameRect(forContentRect: .zero, styleMask: styleMask).height
        return screen.visibleFrame.height - titleBar
    }
}

private struct SettingsFormHeightLimitKey: EnvironmentKey {
    static let defaultValue: CGFloat? = nil
}

extension EnvironmentValues {
    /// The tallest a Settings form may be, set by `SettingsWindowHost` from the window's screen.
    var settingsFormHeightLimit: CGFloat? {
        get { self[SettingsFormHeightLimitKey.self] }
        set { self[SettingsFormHeightLimitKey.self] = newValue }
    }
}

extension View {
    /// The shape of every Common Tools Settings form: System Settings' grouped style at the family's
    /// width, as tall as its sections until that would run off the screen the window is on, when it
    /// scrolls instead. `maxHeight` caps it lower. Apply it to the `Form` itself.
    ///
    ///     Form {
    ///         Section("Shortcuts") { … }
    ///         Section("General") { OpenAtLoginToggle(problem: $loginProblem) }
    ///         CommonToolsSection()
    ///     }
    ///     .settingsForm()
    public func settingsForm(maxHeight: CGFloat? = nil) -> some View {
        modifier(SettingsFormModifier(maxHeight: maxHeight))
    }
}

private struct SettingsFormModifier: ViewModifier {
    @Environment(\.settingsFormHeightLimit) private var screenLimit
    let maxHeight: CGFloat?

    func body(content: Content) -> some View {
        content
            .formStyle(.grouped)
            .frame(width: Tokens.Layout.settingsWidth)
            .frame(maxHeight: [maxHeight, screenLimit].compactMap { $0 }.min())
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A section's explanatory footer, in the one style the apps share: the callout text style, in
/// the secondary colour, or in the danger colour for something the user must put right. A symbol
/// sits before the first line, as the system's own footers do.
///
///     Section { … } footer: { SettingsFootnote("Kept on this Mac only.") }
///     SettingsFootnote("Can’t be seen in the menu bar.", symbol: "eye.slash")
///     SettingsFootnote(problem, tone: .danger)
public struct SettingsFootnote: View {
    public enum Tone: Sendable {
        case secondary
        case danger
    }

    private let text: String
    private let symbol: String?
    private let tone: Tone

    public init(_ text: String, symbol: String? = nil, tone: Tone = .secondary) {
        self.text = text
        self.symbol = symbol
        self.tone = tone
    }

    public var body: some View {
        Group {
            if let symbol {
                Label {
                    Text(text)
                } icon: {
                    Image(systemName: symbol)
                }
            } else {
                Text(text)
            }
        }
        .font(.callout)
        .foregroundStyle(tone == .danger ? AnyShapeStyle(Tokens.Color.danger.color) : AnyShapeStyle(.secondary))
    }
}

/// "Open at login", the first row of every app's General section. It registers the app as a login
/// item and reports, through `problem`, what stands in the way when something does: macOS waiting
/// for the user to allow it, or a refusal. The toggle always shows what is true.
///
///     Section {
///         OpenAtLoginToggle(problem: $loginProblem)
///     } header: { Text("General") } footer: {
///         OpenAtLoginFootnote(loginProblem)
///     }
public struct OpenAtLoginToggle: View {
    /// What the General section's footer says when nothing stands in the way.
    public static let footnote = "Starts when you log in."

    @Binding private var problem: LoginItem.Problem?
    @State private var enabled = LoginItem.isEnabled

    public init(problem: Binding<LoginItem.Problem?>) {
        _problem = problem
    }

    public var body: some View {
        Toggle("Open at login", isOn: $enabled)
            .onAppear { problem = LoginItem.problem }
            .onChange(of: enabled) { _, wanted in
                guard wanted != LoginItem.isEnabled else { return }
                do {
                    try LoginItem.setEnabled(wanted)
                    problem = LoginItem.problem
                } catch {
                    problem = .failed(error.localizedDescription)
                }
                // Off until macOS agrees, so the footnote's advice matches what the toggle shows.
                enabled = LoginItem.isEnabled
            }
    }
}

/// The footer under `OpenAtLoginToggle`: the problem when there is one, else the family's line, so
/// every app's General section reads the same. An app with more to say adds its own
/// `SettingsFootnote` under this one.
public struct OpenAtLoginFootnote: View {
    private let problem: LoginItem.Problem?

    public init(_ problem: LoginItem.Problem?) {
        self.problem = problem
    }

    public var body: some View {
        if let problem {
            // Waiting for approval is a hint; a refusal is something to put right.
            SettingsFootnote(problem.message, tone: problem == .needsApproval ? .secondary : .danger)
        } else {
            SettingsFootnote(OpenAtLoginToggle.footnote)
        }
    }
}

/// The app as a login item, through `SMAppService`, which needs no helper and no permission.
public enum LoginItem {
    /// Why the item is off when the user turned it on.
    public enum Problem: Equatable, Sendable {
        /// macOS has the item but waits for the user to allow it in System Settings.
        case needsApproval
        /// `SMAppService` refused, for this reason.
        case failed(String)

        /// What to tell the user, as a footer under the toggle.
        public var message: String {
            switch self {
            case .needsApproval: "Allow \(LoginItem.appName) in System Settings › General › Login Items."
            case .failed(let reason): reason
            }
        }
    }

    public static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    /// What stands in the way right now, if anything. A refusal is only known when it happens.
    public static var problem: Problem? {
        SMAppService.mainApp.status == .requiresApproval ? .needsApproval : nil
    }

    public static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    /// The name System Settings lists the app under.
    static var appName: String {
        let info = Bundle.main
        return info.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? info.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? ProcessInfo.processInfo.processName
    }
}
