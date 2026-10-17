import AppKit
import SwiftUI

@MainActor
final class SettingsWindow {
    private let library: GlyphLibrary
    private var window: NSWindow?

    init(library: GlyphLibrary) {
        self.library = library
    }

    func show() {
        // A fresh view each time, so Open at login reflects a change made elsewhere. The open editor lives
        // in the library, so it survives.
        let content = NSHostingController(rootView: SettingsView(library: library))
        content.sizingOptions = .preferredContentSize

        if let window {
            window.contentViewController = content
        } else {
            let window = NSWindow(contentViewController: content)
            window.styleMask = [.titled, .closable]
            window.title = "Common Glyph Settings"
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        // Activation is cooperative since macOS 14: the system may decline it, and an accessory app's
        // window would then open behind the frontmost app. Ordering front regardless keeps it visible.
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
    }
}
