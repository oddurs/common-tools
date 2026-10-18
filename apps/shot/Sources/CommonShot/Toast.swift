import AppKit
import CommonUI

/// A thumbnail of the last shot in the screen's corner for a moment, so you know what's on the clipboard
/// without pasting to find out. Like the system's floating thumbnail it slides in from the right, a
/// swipe to the right sends it away, hovering keeps it, and dragging the thumbnail drops the PNG as a
/// file, which a terminal turns into its path; a click dismisses it. Unlike the system's, the clipboard
/// never waits for it. A shot just taken flies into it from where it was picked. Under Reduce Motion
/// it appears and goes without moving.
@MainActor
final class Toast {
    private var panel: NSPanel?
    private var flight: NSPanel?
    private var thumbnail: Thumbnail?
    private var hideTask: Task<Void, Never>?
    /// Where the panel rests, and how far a swipe has carried it to the right of there.
    private var home = NSPoint.zero
    private var swiped: CGFloat = 0

    private static let maximumSide: CGFloat = 180
    private static let margin = Tokens.Space.lg
    private static let shownFor = Duration.milliseconds(2000)
    /// A swipe this far, or a flick, sends the preview away; less and it springs back.
    private static let swipeAway: CGFloat = 60

    /// Shows `image`. `source`, in AppKit's global coordinates, is where it was picked on screen; the
    /// shot shrinks from there into the thumbnail. Without one, the preview slides in from the edge.
    func show(
        _ image: CGImage, scale: CGFloat, on screen: NSScreen?, caption: String, detail: String? = nil,
        file: URL? = nil, from source: CGRect? = nil
    ) {
        hideTask?.cancel()
        panel?.orderOut(nil)
        flight?.orderOut(nil)
        flight = nil
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
        card.onSwipe = { [weak self] delta, ended in self?.swipe(by: delta, ended: ended) }
        thumbnail = card.thumbnail
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
        panel.animationBehavior = .none
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.contentView = card
        let visible = screen.visibleFrame
        home = NSPoint(x: visible.maxX - size.width - Self.margin, y: visible.minY + Self.margin)
        swiped = 0
        self.panel = panel

        let moves = Tokens.Motion.duration(Tokens.Motion.base) > 0
        if moves, let source, let thumbnail {
            panel.setFrameOrigin(home)
            panel.alphaValue = 0
            panel.orderFrontRegardless()
            card.layoutSubtreeIfNeeded()
            let landing = thumbnail.convert(thumbnail.bounds, to: nil).offsetBy(dx: home.x, dy: home.y)
            fly(image, from: source, to: landing, revealing: panel)
        } else if moves {
            // In from just past the screen's right edge, as the system's thumbnail comes.
            panel.setFrameOrigin(NSPoint(x: screen.frame.maxX, y: home.y))
            panel.orderFrontRegardless()
            Tokens.Motion.animate(
                Tokens.Motion.base, easing: Tokens.Motion.Easing.decelerate,
                changes: { panel.animator().setFrameOrigin(self.home) })
        } else {
            panel.setFrameOrigin(home)
            panel.orderFrontRegardless()
        }
        scheduleHide(after: Self.shownFor)
    }

    /// The PNG behind the preview, once it's written, so the thumbnail can be dragged out as a file.
    func attach(file: URL) {
        thumbnail?.file = file
        thumbnail?.toolTip = "Drag into a terminal, a chat, or Finder"
    }

    func dismiss() {
        hideTask?.cancel()
        panel?.orderOut(nil)
        panel = nil
        flight?.orderOut(nil)
        flight = nil
    }

    /// The picked area as a borderless picture, shrinking from where it was to the thumbnail's place,
    /// where `panel` fades in around it before the picture goes.
    private func fly(_ image: CGImage, from source: CGRect, to landing: CGRect, revealing panel: NSPanel) {
        let view = NSView(frame: NSRect(origin: .zero, size: source.size))
        view.wantsLayer = true
        view.layer?.contents = image
        view.layer?.contentsGravity = .resizeAspect
        view.layer?.cornerCurve = .continuous
        view.layer?.masksToBounds = true
        let flight = NSPanel(
            contentRect: source, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        flight.level = .statusBar
        flight.isOpaque = false
        flight.backgroundColor = .clear
        flight.hasShadow = true
        flight.ignoresMouseEvents = true
        flight.isReleasedWhenClosed = false
        flight.animationBehavior = .none
        flight.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        flight.contentView = view
        flight.orderFrontRegardless()
        self.flight = flight
        view.autoresizingMask = [.width, .height]
        Tokens.Motion.animate(
            Tokens.Motion.base, easing: Tokens.Motion.Easing.standard,
            changes: {
                flight.animator().setFrame(landing, display: true)
                view.layer?.cornerRadius = Tokens.Radius.sm
            },
            completion: { [weak self] in
                // The picture stays until the card has faded in over it, so nothing blinks between the two.
                Tokens.Motion.animate(
                    Tokens.Motion.fast, changes: { panel.animator().alphaValue = 1 },
                    completion: {
                        flight.orderOut(nil)
                        if self?.flight === flight { self?.flight = nil }
                    })
            })
    }

    /// Follows a two-finger swipe or a drag of the card to the right; on release it goes, or comes back.
    private func swipe(by delta: CGFloat, ended: Bool) {
        guard let panel else { return }
        if !ended {
            hideTask?.cancel()
            // To the right only; a pull to the left gives a little, then stops.
            swiped = max(swiped + delta, -8)
            panel.setFrameOrigin(NSPoint(x: home.x + swiped, y: home.y))
            return
        }
        if swiped > Self.swipeAway || delta > 12 {
            hideTask?.cancel()
            let screen = panel.screen?.frame.maxX ?? home.x + panel.frame.width * 2
            Tokens.Motion.animate(
                Tokens.Motion.fast, easing: Tokens.Motion.Easing.accelerate,
                changes: {
                    panel.animator().setFrameOrigin(NSPoint(x: screen, y: home.y))
                    panel.animator().alphaValue = 0
                },
                completion: { [weak self] in
                    panel.orderOut(nil)
                    if self?.panel === panel { self?.panel = nil }
                })
        } else {
            swiped = 0
            Tokens.Motion.animate(
                Tokens.Motion.fast, easing: Tokens.Motion.Easing.decelerate,
                changes: { panel.animator().setFrameOrigin(self.home) })
            scheduleHide(after: .milliseconds(800))
        }
    }

    private func scheduleHide(after delay: Duration) {
        hideTask?.cancel()
        guard let panel else { return }
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            // Back out the way it came, to the right, as the system's does; a fade under Reduce Motion.
            let away = NSPoint(x: (panel.screen?.frame.maxX ?? panel.frame.maxX), y: panel.frame.minY)
            let moves = Tokens.Motion.duration(Tokens.Motion.base) > 0
            await NSAnimationContext.runAnimationGroup {
                $0.duration = Tokens.Motion.duration(Tokens.Motion.base)
                $0.timingFunction = CAMediaTimingFunction(name: .easeIn)
                if moves { panel.animator().setFrameOrigin(away) }
                panel.animator().alphaValue = 0
            }
            guard !Task.isCancelled else { return }
            panel.orderOut(nil)
            if self?.panel === panel { self?.panel = nil }
        }
    }

    /// The preview's content, without the panel that floats it, so it can also be rendered offscreen.
    static func card(
        _ image: CGImage, scale: CGFloat, caption: String, detail: String?, file: URL?,
        onFinish: @escaping () -> Void
    ) -> HoverView {
        let points = CGSize(width: CGFloat(image.width) / scale, height: CGFloat(image.height) / scale)
        let fit = min(1, Self.maximumSide / max(points.width, points.height, 1))
        let thumbnail = CGSize(width: max(points.width * fit, 40), height: max(points.height * fit, 24))

        let background = HoverView()
        let imageView = Thumbnail(image: NSImage(cgImage: image, size: points))
        imageView.file = file
        imageView.onFinish = onFinish
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = Tokens.Radius.sm
        imageView.layer?.cornerCurve = .continuous
        imageView.layer?.masksToBounds = true
        imageView.setAccessibilityLabel("Screenshot")
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
        background.thumbnail = imageView
        imageView.heightAnchor.constraint(equalToConstant: thumbnail.height).isActive = true

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

    private static func label(_ text: String, color: SemanticColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        // The subheadline's size, a little heavier so it reads over the blurred material.
        label.font = .systemFont(ofSize: NSFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .medium)
        label.textColor = color.nsColor
        return label
    }
}

/// The card: reports hovering, and a horizontal swipe or drag as it happens and when it ends.
final class HoverView: NSVisualEffectView {
    var onHover: ((Bool) -> Void)?
    /// Points moved to the right since the last call, and whether the gesture just ended.
    var onSwipe: ((CGFloat, Bool) -> Void)?
    fileprivate(set) var thumbnail: Thumbnail?
    private var dragFrom: CGFloat?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(
            NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self))
    }

    override func mouseEntered(with event: NSEvent) { onHover?(true) }
    override func mouseExited(with event: NSEvent) { onHover?(false) }

    override func scrollWheel(with event: NSEvent) {
        // Two fingers on a trackpad only; a mouse wheel has no phase. The fingers' direction, whichever
        // way the person has scrolling set.
        guard event.phase != [] || event.momentumPhase != [] else { return super.scrollWheel(with: event) }
        guard abs(event.scrollingDeltaX) >= abs(event.scrollingDeltaY) || event.phase == .ended else { return }
        let fingers = event.isDirectionInvertedFromDevice ? event.scrollingDeltaX : -event.scrollingDeltaX
        if event.phase == .ended || event.phase == .cancelled {
            onSwipe?(fingers, true)
        } else if event.momentumPhase == [] {
            onSwipe?(fingers, false)
        }
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        dragFrom = NSEvent.mouseLocation.x
    }

    override func mouseDragged(with event: NSEvent) {
        guard let from = dragFrom else { return }
        let x = NSEvent.mouseLocation.x
        onSwipe?(x - from, false)
        dragFrom = x
    }

    override func mouseUp(with event: NSEvent) {
        guard dragFrom != nil else { return }
        dragFrom = nil
        onSwipe?(0, true)
    }
}

/// Drags out as the shot's file; a plain click puts the preview away.
final class Thumbnail: NSImageView, NSDraggingSource {
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
