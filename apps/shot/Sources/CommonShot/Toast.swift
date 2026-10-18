import AppKit
import CommonUI

/// A thumbnail of the last shot in the screen's corner for a moment, so you know what's on the clipboard
/// without pasting to find out. Hovering keeps it; dragging the thumbnail drops the PNG as a file, which
/// a terminal turns into its path; clicking dismisses it.
@MainActor
final class Toast {
    private var panel: NSPanel?
    private var hideTask: Task<Void, Never>?

    private static let maximumSide: CGFloat = 180
    private static let margin = Tokens.Space.lg
    private static let shownFor = Duration.milliseconds(2000)

    func show(
        _ image: CGImage, scale: CGFloat, on screen: NSScreen?, caption: String, detail: String? = nil,
        file: URL? = nil
    ) {
        hideTask?.cancel()
        panel?.orderOut(nil)
        guard let screen = screen ?? NSScreen.main else { return }

        let card = Self.card(image, scale: scale, caption: caption, detail: detail, file: file) { [weak self] in
            self?.dismiss()
        }
        card.onHover = { [weak self] inside in
            guard let self else { return }
            if inside {
                hideTask?.cancel()
                self.panel?.alphaValue = 1
            } else {
                scheduleHide(after: .milliseconds(800))
            }
        }
        let size = card.fittingSize

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false)
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.contentView = card
        let visible = screen.visibleFrame
        panel.setFrameOrigin(NSPoint(x: visible.maxX - size.width - Self.margin, y: visible.minY + Self.margin))
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup {
            $0.duration = Tokens.Motion.duration(Tokens.Motion.fast); panel.animator().alphaValue = 1
        }
        self.panel = panel
        scheduleHide(after: Self.shownFor)
    }

    /// The preview's content, without the panel that floats it, so it can also be rendered offscreen.
    static func card(
        _ image: CGImage, scale: CGFloat, caption: String, detail: String?, file: URL?,
        onFinish: @escaping () -> Void
    ) -> HoverView {
        let points = CGSize(width: CGFloat(image.width) / scale, height: CGFloat(image.height) / scale)
        let fit = min(1, Self.maximumSide / max(points.width, points.height, 1))
        let thumbnail = CGSize(width: max(points.width * fit, 40), height: max(points.height * fit, 24))

        let imageView = Thumbnail(image: NSImage(cgImage: image, size: points))
        imageView.file = file
        imageView.onFinish = onFinish
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = Tokens.Radius.sm
        imageView.layer?.cornerCurve = .continuous
        imageView.layer?.masksToBounds = true
        if file != nil { imageView.toolTip = "Drag into a terminal, a chat, or Finder" }
        var views: [NSView] = [imageView, Self.label(caption, color: Tokens.Text.primary)]
        if let detail { views.append(Self.label(detail, color: Tokens.Text.secondary)) }
        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.spacing = Tokens.Space.xxs
        stack.setCustomSpacing(Tokens.Space.xs, after: imageView)
        let inset = Tokens.Space.sm
        stack.edgeInsets = NSEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        imageView.widthAnchor.constraint(equalToConstant: thumbnail.width).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: thumbnail.height).isActive = true

        let background = HoverView()
        background.material = .popover
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = Tokens.Radius.md
        background.layer?.cornerCurve = .continuous
        background.layer?.masksToBounds = true
        background.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: background.trailingAnchor),
            stack.topAnchor.constraint(equalTo: background.topAnchor),
            stack.bottomAnchor.constraint(equalTo: background.bottomAnchor),
        ])
        return background
    }

    private func scheduleHide(after delay: Duration) {
        hideTask?.cancel()
        guard let panel else { return }
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await NSAnimationContext.runAnimationGroup {
                $0.duration = Tokens.Motion.duration(Tokens.Motion.base); panel.animator().alphaValue = 0
            }
            guard !Task.isCancelled else { return }
            panel.orderOut(nil)
            if self?.panel === panel { self?.panel = nil }
        }
    }

    private func dismiss() {
        hideTask?.cancel()
        panel?.orderOut(nil)
        panel = nil
    }

    private static func label(_ text: String, color: SemanticColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        // The subheadline's size, a little heavier so it reads over the blurred material.
        label.font = .systemFont(ofSize: NSFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .medium)
        label.textColor = color.nsColor
        return label
    }
}

final class HoverView: NSVisualEffectView {
    var onHover: ((Bool) -> Void)?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(
            NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self))
    }

    override func mouseEntered(with event: NSEvent) { onHover?(true) }
    override func mouseExited(with event: NSEvent) { onHover?(false) }
}

/// Drags out as the shot's file; a plain click puts the preview away.
private final class Thumbnail: NSImageView, NSDraggingSource {
    var file: URL?
    var onFinish: (() -> Void)?
    private var downAt: NSPoint?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        downAt = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        guard let file, let downAt, hypot(event.locationInWindow.x - downAt.x, event.locationInWindow.y - downAt.y) > 3
        else { return }
        self.downAt = nil
        let item = NSDraggingItem(pasteboardWriter: file as NSURL)
        item.setDraggingFrame(bounds, contents: image)
        beginDraggingSession(with: [item], event: event, source: self)
    }

    override func mouseUp(with event: NSEvent) {
        if downAt != nil { onFinish?() }
        downAt = nil
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext)
        -> NSDragOperation
    {
        .copy
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        onFinish?()
    }
}
