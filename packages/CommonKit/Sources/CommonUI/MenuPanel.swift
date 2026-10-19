import AppKit
import SwiftUI

/// What a menu bar item opens when a plain `NSMenu` can't hold its job: a grid to walk with the arrow
/// keys, items to drag out, a context menu on each. It looks and behaves like the system's own menu
/// bar panels (Control Center, Wi-Fi): the menu's material under the status item, a click outside or
/// Escape closes it, and it takes the keyboard without making the app active, so the app you were in
/// keeps its place.
///
///     let panel = MenuPanelHost()
///     button.action = #selector(toggle)
///     @objc func toggle() {
///         panel.toggle(below: statusItem.button!) { ShotsPanel(…) }
///     }
@MainActor
public final class MenuPanelHost {
    public private(set) var isShown = false
    /// After the panel closes, however it closed.
    public var onClose: (() -> Void)?

    private var panel: KeyPanel?
    private weak var button: NSStatusBarButton?
    private var monitors: [Any] = []
    private var resizing: NSObjectProtocol?
    /// The panel's top-left corner, which stays put as its content grows or shrinks.
    private var anchor = NSPoint.zero

    public init() {}

    public func toggle<Content: View>(below button: NSStatusBarButton, @ViewBuilder content: () -> Content) {
        if isShown { close() } else { show(below: button, content: content) }
    }

    public func show<Content: View>(below button: NSStatusBarButton, @ViewBuilder content: () -> Content) {
        close()
        guard let window = button.window, let screen = window.screen ?? NSScreen.main else { return }
        let buttonFrame = window.convertToScreen(button.convert(button.bounds, to: nil))
        let visible = screen.visibleFrame
        let controller = NSHostingController(
            rootView: MenuPanelSurface(content: content)
                .environment(\.menuPanelMaxHeight, visible.height - Self.gap - Tokens.Space.xs))
        controller.sizingOptions = .preferredContentSize

        let panel = KeyPanel(
            contentRect: NSRect(origin: .zero, size: controller.view.fittingSize),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.contentViewController = controller
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.onCancel = { [weak self] in self?.close() }
        self.panel = panel
        self.button = button

        // Under the item, its left edge with the item's as a menu's is, and never past the screen's edge.
        let width = controller.view.fittingSize.width
        anchor = NSPoint(
            x: min(max(buttonFrame.minX, visible.minX + Tokens.Space.xs), visible.maxX - width - Tokens.Space.xs),
            y: buttonFrame.minY - Self.gap)
        place()
        resizing = NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification, object: panel, queue: .main
        ) { [weak self] _ in MainActor.assumeIsolated { self?.place() } }

        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        Tokens.Motion.animate(Tokens.Motion.fast, changes: { panel.animator().alphaValue = 1 })
        button.highlight(true)
        isShown = true
        watchForClicksOutside()
    }

    public func close() {
        guard let panel else { return }
        for monitor in monitors { NSEvent.removeMonitor(monitor) }
        monitors = []
        if let resizing { NotificationCenter.default.removeObserver(resizing) }
        resizing = nil
        panel.orderOut(nil)
        self.panel = nil
        button?.highlight(false)
        isShown = false
        onClose?()
    }

    /// Between the menu bar and the panel, as the system leaves under its own.
    private static let gap: CGFloat = Tokens.Space.xxs

    private func place() {
        guard let panel else { return }
        panel.setFrameTopLeftPoint(anchor)
    }

    /// A click anywhere else closes the panel, as it would a menu: in another app (a global monitor,
    /// which mouse clicks need no permission for) or in another of this app's windows. A click on the
    /// status item itself is left to its action, which toggles.
    private func watchForClicksOutside() {
        let clicks: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        if let global = NSEvent.addGlobalMonitorForEvents(
            matching: clicks, handler: { [weak self] _ in MainActor.assumeIsolated { self?.close() } })
        {
            monitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(
            matching: clicks,
            handler: { [weak self] event in
                MainActor.assumeIsolated {
                    guard let self, let panel = self.panel else { return }
                    if event.window !== panel, event.window !== self.button?.window { self.close() }
                }
                return event
            })
        {
            monitors.append(local)
        }
    }
}

/// Takes the keyboard without activating the app, and closes on Escape when nothing inside used it.
private final class KeyPanel: NSPanel {
    var onCancel: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}

/// The panel's face: content at the menu panel width, on the menu's own material, with the system
/// menu's corner and a hairline. `MenuPanelHost` puts it in a window; offscreen renders draw it alone.
public struct MenuPanelSurface<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
        content
            .padding(Tokens.Space.xs)
            .frame(width: Tokens.Layout.menuPanelWidth + 2 * Tokens.Space.xs)
            .background(MenuMaterial())
            .clipShape(shape)
            .overlay(shape.strokeBorder(Tokens.Color.border.color, lineWidth: 0.5))
    }
}

extension EnvironmentValues {
    /// The most a panel's content may be tall on the screen it opens on; a long list scrolls inside it.
    public var menuPanelMaxHeight: CGFloat {
        get { self[MenuPanelMaxHeightKey.self] }
        set { self[MenuPanelMaxHeightKey.self] = newValue }
    }
}

private struct MenuPanelMaxHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 640
}

/// The system menu material, so Reduce Transparency and Increase Contrast apply as they do to menus.
private struct MenuMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .menu
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

/// A row that acts like a menu item: an optional symbol, a title, and the shortcut on the right in the
/// secondary colour, highlighted in the accent colour under the pointer as a menu item is.
///
///     MenuRow("Take Screenshot", symbol: "camera.viewfinder", shortcut: "⇧⌘2") { capture() }
///     MenuRow("Settings…", shortcut: "⌘,") { showSettings() }
public struct MenuRow: View {
    private let title: String
    private let symbol: String?
    private let shortcut: String?
    private let action: () -> Void
    @State private var hovering = false

    public init(_ title: String, symbol: String? = nil, shortcut: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.shortcut = shortcut
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Tokens.Space.xs) {
                if let symbol {
                    Image(systemName: symbol).frame(width: 16)
                }
                Text(title)
                Spacer(minLength: Tokens.Space.sm)
                if let shortcut {
                    Text(shortcut).foregroundStyle(hovering ? Tokens.Text.inverse.color : Tokens.Text.secondary.color)
                }
            }
            .foregroundStyle(hovering ? Tokens.Text.inverse.color : Tokens.Text.primary.color)
            .padding(.horizontal, Tokens.Space.xs)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
            .background(
                hovering ? AnyShapeStyle(Tokens.Color.accentFill.color) : AnyShapeStyle(.clear),
                in: RoundedRectangle(cornerRadius: Tokens.Radius.xs, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .accessibilityLabel(shortcut.map { "\(title), \($0)" } ?? title)
    }
}

/// The header of a group in a list or grid: its name in the system's section-header style, and an
/// optional count or action at the trailing edge.
///
///     SectionHeader("Today", detail: "3 shots")
///     SectionHeader("Recent") { Button("Clear") { clear() } }
public struct SectionHeader<Trailing: View>: View {
    private let title: String
    private let detail: String?
    private let trailing: Trailing

    public init(_ title: String, detail: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.detail = detail
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.xs) {
            Text(title).font(.subheadline.weight(Tokens.Weight.semibold)).foregroundStyle(.secondary)
            if let detail {
                Text(detail).font(.subheadline).foregroundStyle(.tertiary)
            }
            Spacer()
            trailing.font(.subheadline)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

extension SectionHeader where Trailing == EmptyView {
    public init(_ title: String, detail: String? = nil) {
        self.init(title, detail: detail) { EmptyView() }
    }
}

/// A picture with a caption under it, in a grid: the picture whole (letterboxed in the media surface,
/// never cropped, since a cropped shot misleads), a title with an optional leading accessory such as an
/// app's icon, and a secondary line. Hover lifts it with a faint wash; selection rings it in the
/// accent colour, so the keyboard's place is plain.
///
///     ThumbnailTile(image: thumbnail, title: "2:03 PM", subtitle: "1280 × 760 · ≈ 1.3k tokens",
///                   isSelected: selected == index) { Image(nsImage: appIcon).resizable() }
public struct ThumbnailTile<Accessory: View>: View {
    private let image: Image?
    private let title: String
    private let subtitle: String?
    private let aspect: CGFloat
    private let isSelected: Bool
    private let accessory: Accessory
    @State private var hovering = false

    public init(
        image: Image?, title: String, subtitle: String? = nil, aspect: CGFloat = 16 / 10, isSelected: Bool = false,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.aspect = aspect
        self.isSelected = isSelected
        self.accessory = accessory()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous)
        VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
            Tokens.Surface.media.color
                .aspectRatio(aspect, contentMode: .fit)
                .overlay {
                    if let image {
                        image.resizable().interpolation(.high).aspectRatio(contentMode: .fit)
                    }
                }
                .clipShape(shape)
                .overlay(shape.strokeBorder(Tokens.Color.borderCard.color, lineWidth: 1))
                .overlay {
                    if hovering { shape.fill(Tokens.Text.primary.color.opacity(0.06)) }
                }
                .padding(2)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: Tokens.Radius.sm + 2, style: .continuous)
                            .strokeBorder(Tokens.Color.accent.color, lineWidth: 2)
                    }
                }
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: Tokens.Space.xxs) {
                    if Accessory.self != EmptyView.self {
                        accessory.frame(width: 14, height: 14)
                    }
                    Text(title).font(.subheadline.weight(Tokens.Weight.semibold)).lineLimit(1)
                }
                if let subtitle {
                    Text(subtitle).font(.footnote.monospacedDigit()).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            .padding(.horizontal, 2)
        }
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

extension ThumbnailTile where Accessory == EmptyView {
    public init(
        image: Image?, title: String, subtitle: String? = nil, aspect: CGFloat = 16 / 10, isSelected: Bool = false
    ) {
        self.init(image: image, title: title, subtitle: subtitle, aspect: aspect, isSelected: isSelected) {
            EmptyView()
        }
    }
}
