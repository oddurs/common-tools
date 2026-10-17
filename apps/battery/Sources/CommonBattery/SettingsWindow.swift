import AppKit
import SwiftUI

@MainActor
final class SettingsWindow {
    private unowned let controller: AppController
    private var window: NSWindow?

    init(controller: AppController) {
        self.controller = controller
    }

    func show() {
        // A fresh view each time, so Open at login reflects a change made elsewhere.
        let content = NSHostingController(
            rootView: SettingsView(controller: controller, preferences: controller.preferences, state: controller.state)
        )
        content.sizingOptions = .preferredContentSize

        if let window {
            window.contentViewController = content
        } else {
            let window = NSWindow(contentViewController: content)
            window.styleMask = [.titled, .closable]
            window.title = "Common Battery Settings"
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
