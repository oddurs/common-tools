import AppKit
import CommonKit
import CommonUI
import GlyphKit
import SwiftUI
import UniformTypeIdentifiers

/// Keeps one status item for each visible glyph, adding and removing items as glyphs come and go.
@MainActor
final class MenuBarController: NSObject {
    let library: GlyphLibrary
    private let settings = SettingsWindowHost(title: "Common Glyph Settings")
    private let updates = UpdateCheck(tool: CommonTool.thisApp!)
    private var items: [UUID: GlyphItem] = [:]

    init(library: GlyphLibrary) {
        self.library = library
        super.init()
        library.onChange = { [weak self] in self?.sync() }
        sync()
    }

    private func sync() {
        let visible = library.visible
        let ids = Set(visible.map(\.id))
        for (id, item) in items where !ids.contains(id) {
            item.remove()
            items[id] = nil
        }
        for model in visible where items[model.id] == nil {
            items[model.id] = GlyphItem(model: model, controller: self)
        }
    }

    /// Opens Settings, with `glyph`'s editor on top of it if one is given.
    func showSettings(_ glyph: GlyphModel?) {
        if let glyph { library.editing = glyph.id }
        // A fresh view each time; the open editor lives in the library, so it survives the rebuild.
        settings.show { SettingsView(library: library, updates: updates) }
    }

    func newGlyph() {
        showSettings(library.add())
    }
}

extension MenuBarController: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Welcome.showIfNeeded(
            WelcomeInfo(line: "Put your own images in the menu bar: a character, a sticker, an emoji, or a word."))
        updates.start()
    }

    /// Opening the app again while it runs is how people look for its settings.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings(nil)
        return false
    }
}

/// One glyph's status item: draws it, plays it if it's animated, takes images dropped on it, and opens
/// its menu on click.
@MainActor
private final class GlyphItem: NSObject, NSMenuDelegate {
    /// Distance from the right edge of the screen where a new glyph first appears: beside the clock,
    /// right of where menu bar managers such as Common Bar keep their dividers, so it starts out visible.
    private static let startingPosition = 150.0

    private let model: GlyphModel
    private weak var controller: MenuBarController?
    private let item: NSStatusItem
    private var frameTimer: Timer?
    private var frameIndex = 0
    private var screensAsleep = false

    init(model: GlyphModel, controller: MenuBarController) {
        self.model = model
        self.controller = controller
        // macOS places a new item at the far left, where a menu bar manager would hide it. Its saved
        // position must exist before the item is named, or macOS ignores it.
        let positionKey = "NSStatusItem Preferred Position \(model.spec.autosaveName)"
        if UserDefaults.standard.object(forKey: positionKey) == nil {
            UserDefaults.standard.set(Self.startingPosition, forKey: positionKey)
        }
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        item.autosaveName = model.spec.autosaveName

        if let button = item.button {
            button.imagePosition = .imageOnly
            if let window = button.window {
                NotificationCenter.default.addObserver(
                    self, selector: #selector(occlusionChanged), name: NSWindow.didChangeOcclusionStateNotification,
                    object: window)
            }
            let drop = DropTarget(frame: button.bounds)
            drop.autoresizingMask = [.width, .height]
            drop.onDrop = { [weak self] pasteboard in self?.importImage { try await $0.importImage(from: pasteboard) } }
            drop.onHover = { [weak button] inside in button?.highlight(inside) }
            button.addSubview(drop)
        }
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        item.menu = menu

        model.onRender = { [weak self] in self?.update() }
        update()

        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(
            self, selector: #selector(accessibilityChanged),
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, object: nil)
        // Nothing to animate while the display sleeps.
        workspace.addObserver(
            self, selector: #selector(screensChanged), name: NSWorkspace.screensDidSleepNotification, object: nil)
        workspace.addObserver(
            self, selector: #selector(screensChanged), name: NSWorkspace.screensDidWakeNotification, object: nil)
    }

    func remove() {
        frameTimer?.invalidate()
        model.onRender = nil
        model.isOnScreen = true
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
        NSStatusBar.system.removeStatusItem(item)
    }

    // MARK: Drawing

    private func update() {
        frameTimer?.invalidate()
        frameTimer = nil
        frameIndex = 0
        item.button?.setAccessibilityLabel(model.spec.name)
        guard let glyph = model.glyph else {
            // Something always shows, so the menu stays in reach while the glyph is empty.
            item.button?.image = NSImage(systemSymbolName: "sparkle", accessibilityDescription: model.spec.name)
            return
        }
        item.button?.image = glyph.frames[0]
        if glyph.isAnimated && model.edit.animates && !screensAsleep
            && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        {
            scheduleNextFrame()
        }
    }

    private func scheduleNextFrame() {
        guard let glyph = model.glyph else { return }
        let timer = Timer(timeInterval: glyph.delays[frameIndex], repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let glyph = self.model.glyph, glyph.isAnimated else { return }
                self.frameIndex = (self.frameIndex + 1) % glyph.frames.count
                self.item.button?.image = glyph.frames[self.frameIndex]
                self.scheduleNextFrame()
            }
        }
        // Keeps playing while a menu is open, like the system's own items.
        RunLoop.main.add(timer, forMode: .common)
        frameTimer = timer
    }

    /// Lets Settings say when a glyph is running but can't be seen.
    @objc private func occlusionChanged() {
        model.isOnScreen = item.button?.window?.occlusionState.contains(.visible) ?? true
    }

    @objc private func accessibilityChanged() {
        update()
    }

    @objc private func screensChanged(_ notification: Notification) {
        screensAsleep = notification.name == NSWorkspace.screensDidSleepNotification
        update()
    }

    // MARK: Menu

    /// Built on each open, so the card and the actions reflect the glyph, the pasteboard, and how many
    /// glyphs are showing. The card's view exists only while the menu is open.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        item.button?.setAccessibilityLabel(model.spec.name)
        let others = (controller?.library.visible.count ?? 1) - 1
        menu.addItem(hosted(GlyphCard(model: model, others: others)))
        menu.addItem(.separator())

        add(to: menu, "Edit Glyph…", "slider.horizontal.3", #selector(edit))
        add(to: menu, "Choose Image…", "photo", #selector(chooseImage))
        let paste = add(to: menu, "Paste Image", "doc.on.clipboard", #selector(pasteImage))
        paste.isEnabled = GlyphModel.hasImage(.general)
        menu.addItem(.separator())

        add(to: menu, "New Glyph", "plus", #selector(newGlyph))
        let hide = add(to: menu, "Hide Glyph", "eye.slash", #selector(hide))
        let canHide = controller?.library.canHide(model) == true
        hide.isEnabled = canHide
        if #available(macOS 14.4, *) {
            hide.subtitle = canHide ? "Show it again in Settings" : "One glyph always stays in the menu bar"
        }
        menu.addItem(.separator())

        add(to: menu, "Settings…", "gearshape", #selector(settings), key: ",")
        let quit = NSMenuItem(
            title: "Quit Common Glyph", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.image = Self.symbol("power")
        menu.addItem(quit)
    }

    func menuDidClose(_ menu: NSMenu) {
        // Drop the hosting view; menuNeedsUpdate rebuilds it on the next open.
        for item in menu.items { item.view = nil }
    }

    private func hosted(_ view: some View) -> NSMenuItem {
        let host = NSHostingView(rootView: view)
        host.frame.size = host.fittingSize
        let item = NSMenuItem()
        item.view = host
        return item
    }

    @discardableResult
    private func add(
        to menu: NSMenu, _ title: String, _ symbol: String, _ action: Selector, key: String = ""
    ) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: key)
        menuItem.target = self
        menuItem.image = Self.symbol(symbol)
        menu.addItem(menuItem)
        return menuItem
    }

    /// Tahoe gives standard menu items icons; match them. Earlier releases show none.
    private static func symbol(_ name: String) -> NSImage? {
        guard #available(macOS 26, *) else { return nil }
        return NSImage(systemSymbolName: name, accessibilityDescription: nil)
    }

    @objc private func edit() { controller?.showSettings(model) }
    @objc private func settings() { controller?.showSettings(nil) }
    @objc private func newGlyph() { controller?.newGlyph() }
    @objc private func hide() { model.spec.isVisible = false }

    @objc private func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image, .pdf]
        panel.message = "Choose an image for “\(model.spec.name)”"
        NSApp.activate()
        guard panel.runModal() == .OK, let url = panel.url else { return }
        importImage { try await $0.importImage(at: url) }
    }

    @objc private func pasteImage() {
        importImage { try await $0.importImage(from: .general) }
    }

    private func importImage(_ work: @escaping @MainActor (GlyphModel) async throws -> Void) {
        let model = model
        Task {
            do {
                try await work(model)
            } catch {
                NSApp.activate()
                NSAlert(error: error).runModal()
            }
        }
    }
}

/// Covers a status item so an image dragged from Finder can be dropped straight onto the menu bar.
/// Clicks fall through to the button underneath.
private final class DropTarget: NSView {
    var onDrop: ((NSPasteboard) -> Void)?
    var onHover: ((Bool) -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        registerForDraggedTypes([.fileURL, .png, .tiff, NSPasteboard.PasteboardType(UTType.gif.identifier)])
    }

    required init?(coder: NSCoder) { fatalError("not used from a nib") }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard GlyphModel.hasImage(sender.draggingPasteboard) else { return [] }
        onHover?(true)
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        onHover?(false)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        onHover?(false)
        onDrop?(sender.draggingPasteboard)
        return true
    }
}
