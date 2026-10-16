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
        if window == nil {
            let content = NSHostingController(rootView: SettingsView(library: library))
            content.sizingOptions = .minSize
            let window = NSWindow(contentViewController: content)
            // A sidebar window, like System Settings: the list runs up under the title bar.
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            window.toolbar = NSToolbar()
            window.toolbarStyle = .unified
            window.title = "Common Glyph"
            window.isReleasedWhenClosed = false
            window.setContentSize(NSSize(width: 820, height: 720))
            window.setFrameAutosaveName("Settings")
            if !window.setFrameUsingName("Settings") { window.center() }
            self.window = window
        }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }
}
