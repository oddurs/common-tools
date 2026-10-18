import AppKit
import CommonKit

MainActor.assumeIsolated {
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
