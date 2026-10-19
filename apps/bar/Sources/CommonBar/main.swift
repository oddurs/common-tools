import AppKit
import CommonKit

MainActor.assumeIsolated {
    // `--render <folder>` draws the dropdown offscreen and exits, without starting the app.
    if let flag = CommandLine.arguments.firstIndex(of: "--render") {
        let folder = CommandLine.arguments.dropFirst(flag + 1).first ?? "render"
        do {
            try Render.run(into: URL(fileURLWithPath: folder))
            exit(0)
        } catch {
            FileHandle.standardError.write(Data("render failed: \(error)\n".utf8))
            exit(1)
        }
    }
    // Common Bar was Reasonal: carry its settings and item positions over before anything reads
    // them. Whether it was asked for Accessibility stays behind: the new identity has no grant, and
    // must ask the system again so it appears in the pane.
    LegacyIdentity.migrate(
        from: LegacyIdentity(bundleIdentifier: "com.oddurs.reasonal", droppedKeys: ["askedForAccessibility"]))
    let app = NSApplication.shared
    let controller = MenuBarController()
    app.delegate = controller
    app.setActivationPolicy(.accessory)
    withExtendedLifetime(controller) { app.run() }
}
