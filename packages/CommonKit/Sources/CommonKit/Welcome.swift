import AppKit
import CommonUI
import SwiftUI

/// What the Welcome window says about this app. Everything else in it is the same for every app.
public struct WelcomeInfo: Sendable {
    public let name: String
    /// What the app does, in one line.
    public let line: String
    public let permission: Permission?

    /// - Parameter name: the app's display name; Info.plist's by default.
    public init(name: String? = nil, line: String, permission: Permission? = nil) {
        self.name =
            name ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
        self.line = line
        self.permission = permission
    }
}

/// The window every app shows on its first launch: what it does, the permission it needs with a
/// live check, Open at login, and the rest of the family.
@MainActor
public enum Welcome {
    static let shownKey = "CommonKit.welcomed"
    private static var window: NSWindow?

    /// Shows the window the first time the app runs, and never again. Call it from
    /// `applicationDidFinishLaunching`.
    public static func showIfFirstLaunch(_ info: WelcomeInfo, defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: shownKey) else { return }
        defaults.set(true, forKey: shownKey)
        show(info)
    }

    /// Shows the window now, for a Welcome… menu item or a button in Settings.
    public static func show(_ info: WelcomeInfo) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }
        let window = NSWindow(
            contentRect: .zero, styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        window.title = "Welcome to \(info.name)"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        let content = NSHostingView(rootView: WelcomeView(info: info) { [weak window] in window?.close() })
        window.contentView = content
        window.setContentSize(content.fittingSize)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
        self.window = window
    }
}

public struct WelcomeView: View {
    let info: WelcomeInfo
    let done: () -> Void
    @State private var granted: Bool
    @State private var openAtLogin = LoginItem.isEnabled
    @State private var loginProblem: String?

    public init(info: WelcomeInfo, done: @escaping () -> Void) {
        self.info = info
        self.done = done
        _granted = State(initialValue: info.permission?.isGranted ?? true)
    }

    public var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 96, height: 96)
                Text("Welcome to \(info.name)").font(.title2.weight(.semibold))
                Text(info.line).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            // The family's promise, in the same words as docs/install.md.
            VStack(alignment: .leading, spacing: 3) {
                Text("Completely free, forever: no trial, no subscription, no paid tier.")
                Text("Open source under MIT: every line is on GitHub.")
                Text(
                    "Private: no analytics, no crash reports, no account. Nothing you do is ever reported. The only network request is the update check, off until you turn it on, which asks GitHub for the latest version and sends nothing about you."
                )
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                if let permission = info.permission {
                    row(
                        title: permission.name,
                        detail: "\(info.name) needs \(permission.name) access \(permission.reason).",
                        status: granted
                    ) {
                        if granted {
                            Label("Granted", systemImage: "checkmark").foregroundStyle(.secondary)
                        } else {
                            Button("Open System Settings") { permission.request() }
                        }
                    }
                    Divider()
                }
                row(title: "Open at login", detail: "Starts \(info.name) when you log in.") {
                    Toggle("Open at login", isOn: $openAtLogin).labelsHidden().toggleStyle(.switch)
                }
                if let loginProblem {
                    Text(loginProblem)
                        .font(.caption).foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.horizontal, .bottom], 12)
                }
            }
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 10) {
                Text("Common Tools").font(.headline)
                HStack(alignment: .top, spacing: 6) {
                    ForEach(CommonTool.all) { tool in FamilyTile(tool: tool, host: info.name) }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button("Done", action: done).keyboardShortcut(.defaultAction)
        }
        .padding(24)
        .frame(width: 460)
        .onChange(of: openAtLogin) { _, enabled in
            do {
                try LoginItem.setEnabled(enabled)
                loginProblem = nil
            } catch {
                loginProblem = error.localizedDescription
                openAtLogin = LoginItem.isEnabled
            }
        }
        .task {
            // The switch is flipped in System Settings, not here, so watch for it.
            guard let permission = info.permission else { return }
            while !granted, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                granted = permission.isGranted
            }
        }
    }

    private func row<Trailing: View>(
        title: String, detail: String, status: Bool? = nil, @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 12) {
            if let status {
                Circle().fill(status ? Color.green : Color.orange).frame(width: 8, height: 8)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                // Wraps instead of truncating beside the trailing control.
                Text(detail).font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            trailing()
        }
        .padding(12)
    }
}

private struct FamilyTile: View {
    let tool: CommonTool
    /// The name of the app showing the window, which isn't offered to itself.
    let host: String

    var body: some View {
        Button {
            if let url = tool.installedURL {
                NSWorkspace.shared.openApplication(at: url, configuration: .init())
            } else {
                NSWorkspace.shared.open(tool.page)
            }
        } label: {
            VStack(spacing: 4) {
                Group {
                    if let icon = tool.icon {
                        Image(nsImage: icon).resizable()
                    } else {
                        RoundedRectangle(cornerRadius: 9).fill(.quaternary)
                    }
                }
                .frame(width: 40, height: 40)
                Text(tool.name.replacingOccurrences(of: "Common ", with: ""))
                    .font(.caption2)
                    .foregroundStyle(tool.name == host ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(tool.name == host)
        .help(tool.name == host ? "This app" : tool.summary)
    }
}
