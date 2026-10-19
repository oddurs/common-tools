import AppKit
import SwiftUI

/// A small card that says what just happened, beside where it happened, for a moment: "Copied as Hex"
/// after a pick, with the colour and the text that went to the clipboard. It never takes a click or
/// the keyboard, so it can't get in the way, and VoiceOver hears the same words.
///
///     let confirmation = ConfirmationHost()
///     confirmation.show(near: NSEvent.mouseLocation, announcing: "Copied #3a7bd5 as Hex") {
///         ConfirmationCard(title: "Copied as Hex", detail: "#3a7bd5", detailIsCode: true) { swatch }
///     }
@MainActor
public final class ConfirmationHost {
    private var panel: NSPanel?
    private var hideTask: Task<Void, Never>?

    /// Long enough to read a short line of code; a new confirmation replaces the last at once.
    public static let shownFor = Duration.milliseconds(1400)
    /// From the point to the card's corner, so the card sits beside the pointer, not under it.
    nonisolated static let offset = CGSize(width: Tokens.Space.md, height: Tokens.Space.md)

    public init() {}

    /// `point` is in AppKit's global coordinates. The card goes below and to the right of it, flipped
    /// to stay on the point's screen.
    public func show<Content: View>(near point: NSPoint, announcing: String, @ViewBuilder content: () -> Content) {
        dismiss()
        let host = NSHostingView(rootView: content())
        let size = host.fittingSize
        let screen = NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false)
        panel.contentView = host
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.setFrameOrigin(Self.origin(for: size, near: point, in: screen?.visibleFrame))
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        Tokens.Motion.animate(Tokens.Motion.fast, changes: { panel.animator().alphaValue = 1 })
        self.panel = panel

        NSAccessibility.post(
            element: NSApp as Any, notification: .announcementRequested,
            userInfo: [.announcement: announcing, .priority: NSAccessibilityPriorityLevel.high.rawValue])

        hideTask = Task { [weak self] in
            try? await Task.sleep(for: Self.shownFor)
            guard !Task.isCancelled else { return }
            Tokens.Motion.animate(
                Tokens.Motion.base, changes: { panel.animator().alphaValue = 0 },
                completion: { [weak self] in
                    panel.orderOut(nil)
                    if self?.panel === panel { self?.panel = nil }
                })
        }
    }

    public func dismiss() {
        hideTask?.cancel()
        panel?.orderOut(nil)
        panel = nil
    }

    /// Below and right of `point`, or above and left of it where that would leave the screen.
    nonisolated static func origin(for size: CGSize, near point: NSPoint, in visible: NSRect?) -> NSPoint {
        var x = point.x + offset.width
        var y = point.y - offset.height - size.height
        if let visible {
            if x + size.width > visible.maxX { x = point.x - offset.width - size.width }
            if y < visible.minY { y = point.y + offset.height }
            x = min(max(x, visible.minX), visible.maxX - size.width)
            y = min(max(y, visible.minY), visible.maxY - size.height)
        }
        return NSPoint(x: x.rounded(), y: y.rounded())
    }
}

/// The confirmation's face: a leading picture (a swatch, a thumbnail, a symbol), what happened, and
/// the detail under it, on the popover material with the system's corner and a hairline.
public struct ConfirmationCard<Leading: View>: View {
    private let title: String
    private let detail: String?
    private let detailIsCode: Bool
    private let leading: Leading
    @Environment(\.colorSchemeContrast) private var contrast

    public init(
        title: String, detail: String? = nil, detailIsCode: Bool = false, @ViewBuilder leading: () -> Leading
    ) {
        self.title = title
        self.detail = detail
        self.detailIsCode = detailIsCode
        self.leading = leading()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
        HStack(alignment: .center, spacing: Tokens.Space.sm) {
            leading.frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(Tokens.Weight.semibold))
                if let detail {
                    Text(detail)
                        .font(detailIsCode ? .footnote.monospaced() : .footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, Tokens.Space.sm)
        .padding(.vertical, Tokens.Space.xs)
        .frame(maxWidth: Self.maxWidth, alignment: .leading)
        .fixedSize()
        .background(PopoverMaterial())
        .clipShape(shape)
        .overlay(
            shape.strokeBorder(
                contrast == .increased ? Tokens.Color.border.color : Tokens.Color.borderCard.color,
                lineWidth: contrast == .increased ? 1 : 0.5)
        )
        .accessibilityElement(children: .combine)
    }

    /// A line of code fits; a longer one wraps rather than running off.
    static var maxWidth: CGFloat { Tokens.Layout.menuPanelWidth - Tokens.Space.lg }
}

extension ConfirmationCard where Leading == EmptyView {
    public init(title: String, detail: String? = nil, detailIsCode: Bool = false) {
        self.init(title: title, detail: detail, detailIsCode: detailIsCode) { EmptyView() }
    }
}

/// The popover material, as the system's own transient cards use, so Reduce Transparency and Increase
/// Contrast apply.
private struct PopoverMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}
