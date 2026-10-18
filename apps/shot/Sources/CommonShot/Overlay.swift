import AppKit
import QuartzCore
import ShotKit

/// What the person picked on the overlay.
enum Pick {
    /// A dragged rectangle, in the points of the still's screen, from its bottom-left corner.
    case area(Still, CGRect)
    case screen(Still)
    case window(WindowFrame, on: Still)
}

/// The frozen displays, one window each, over everything including the menu bar. Drag for an area,
/// click for the window under the pointer, Return for the whole screen, Escape to cancel. Holding ⌥
/// copies the text in what's picked instead of the image.
@MainActor
final class Overlay {
    var onPick: ((pick: Pick, asText: Bool)?) -> Void = { _ in }
    /// The window under the pointer changed to this one.
    var onHover: (UInt32) -> Void = { _ in }
    private let freeze: Freeze
    /// One per display, in the order of `freeze.stills`. They draw without a window, which is how
    /// `--render` pictures them offscreen.
    let views: [OverlayView]
    private var windows: [OverlayWindow] = []
    private var dragging = false

    init(freeze: Freeze, imageSize: ImageSize) {
        self.freeze = freeze
        views = freeze.stills.map { still in
            OverlayView(
                still: still, imageSize: imageSize,
                windows: freeze.windows.map { Geometry.local($0.frame, displayBounds: still.displayBounds) })
        }
        for view in views { view.overlay = self }
    }

    func show() {
        windows = views.map(OverlayWindow.init)
        for window in windows { window.orderFrontRegardless() }
        let mouse = NSEvent.mouseLocation
        (windows.first { NSMouseInRect(mouse, $0.frame, false) } ?? windows.first)?.makeKey()
        pointerMoved(to: mouse)
        // The pieces show a plain tint until the blur is ready, a moment after the overlay is up.
        for view in views {
            let image = view.still.image
            Task {
                let backdrop = await Task.detached(priority: .userInitiated) { Backdrop.blurred(image) }.value
                view.backdrop = backdrop
            }
        }
    }

    /// The first overlay in a process takes about 55 ms longer to build than any after it, and the first
    /// blur about 40 ms longer, while AppKit, Core Animation and Core Image load what they need. One
    /// built at launch and never shown moves that out of the first shortcut.
    static func warmUp() {
        guard
            let context = CGContext(
                data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
            let image = context.makeImage()
        else { return }
        let frame = CGRect(x: 0, y: 0, width: 8, height: 8)
        let still = Still(frame: frame, displayBounds: frame, image: image, screen: nil)
        let overlay = Overlay(freeze: Freeze(stills: [still], windows: []), imageSize: .prompt)
        _ = overlay.views.map(OverlayWindow.init)
        overlay.pointerMoved(to: CGPoint(x: 4, y: 4))
        Task.detached(priority: .utility) { _ = Backdrop.blurred(image) }
    }

    /// The blur at once, for `--render`.
    func prepareBackdrops() {
        for view in views { view.backdrop = Backdrop.blurred(view.still.image) }
    }

    func close() {
        for window in windows { window.orderOut(nil) }
        windows = []
    }

    // MARK: Events from the views

    /// Highlights the window under the pointer, on whichever screens it spans, and moves the loupe.
    func pointerMoved(to mouse: NSPoint) {
        for view in views { view.pointerMoved(to: mouse) }
        guard !dragging else { return }
        let hovered = still(at: mouse).flatMap { still -> WindowFrame? in
            let local = NSPoint(x: mouse.x - still.frame.minX, y: mouse.y - still.frame.minY)
            return WindowFrame.topmost(
                at: Geometry.global(local, displayBounds: still.displayBounds), in: freeze.windows)
        }
        for view in views { view.show(hovered: hovered) }
        if let hovered { onHover(hovered.id) }
    }

    func modifiersChanged(_ flags: NSEvent.ModifierFlags) {
        let asText = flags.contains(.option)
        for view in views { view.asText = asText }
    }

    func dragBegan(in view: OverlayView) {
        guard !dragging else { return }
        dragging = true
        for other in views where other !== view { other.show(hovered: nil) }
    }

    func dragEnded(in view: OverlayView, selection: CGRect, asText: Bool) {
        let dragged = dragging
        dragging = false
        switch Gesture.from(selection: selection, dragged: dragged, overWindow: view.hovered != nil) {
        case .area(let rect): onPick((.area(view.still, rect), asText))
        case .window: if let hovered = view.hovered { onPick((.window(hovered, on: view.still), asText)) }
        case .nothing: pointerMoved(to: NSEvent.mouseLocation)
        }
    }

    func keyDown(_ event: NSEvent) {
        switch event.keyCode {
        case 53:  // Escape
            onPick(nil)
        case 36, 76:  // Return, Enter
            if let still = still(at: NSEvent.mouseLocation) {
                onPick((.screen(still), event.modifierFlags.contains(.option)))
            }
        default:
            NSSound.beep()
        }
    }

    func cancel() {
        onPick(nil)
    }

    /// As if `rect` had been dragged on the display at `index`, for `--overlay` and `--render`.
    func select(_ rect: CGRect, on index: Int = 0) {
        guard views.indices.contains(index) else { return }
        dragBegan(in: views[index])
        views[index].showSelection(rect)
    }

    private func still(at mouse: NSPoint) -> Still? {
        freeze.stills.first { NSMouseInRect(mouse, $0.frame, false) }
    }
}

final class OverlayWindow: NSPanel {
    let overlayView: OverlayView

    init(view: OverlayView) {
        overlayView = view
        let frame = view.still.frame
        super.init(
            contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = .screenSaver
        isOpaque = true
        hasShadow = false
        animationBehavior = .none
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        acceptsMouseMovedEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        contentView = overlayView
        setFrame(frame, display: false)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// The frozen picture with the dimming, outline, size, loupe, and hint in layers above it, so following
/// the pointer moves a few layers rather than redrawing a 5K image. Every layer renders at the display's
/// scale, and every edge is one device pixel, on a 2× panel and a 1× monitor alike.
final class OverlayView: NSView {
    let still: Still
    weak var overlay: Overlay?
    private let imageSize: ImageSize
    private(set) var hovered: WindowFrame?
    /// The windows on this display, front to back, in its points: the edges a drag settles on.
    private let windows: [CGRect]
    /// A drag's anchor and its moving corner, settled on edges and moved by the keys.
    private var start: CGPoint?
    private var end: CGPoint?
    /// Where the pointer was when Space went down, while it's held: the selection moves, not resizes.
    private var moving: CGPoint?
    private var selection: CGRect?
    /// Where the pointer is, in this view's points, or nil when it's on another display.
    private var pointer: CGPoint?
    var asText = false {
        didSet { if asText != oldValue { refresh() } }
    }
    var backdrop: CGImage? {
        didSet { for label in [pill, hint] { label.backdrop = backdrop } }
    }
    /// Read once per overlay, which lives for a few seconds; settable so `--render` can show them.
    var increaseContrast = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast {
        didSet { restyle() }
    }
    var reduceTransparency = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency {
        didSet { restyle() }
    }

    private let picture = CALayer()
    private let dim = CAShapeLayer()
    private let outline = CAShapeLayer()
    private let pill = MaterialLabel()
    private let hint = MaterialLabel()
    private let loupe = Loupe()

    private static let hintRuns: [(String, MaterialLabel.Style)] = [
        ("Drag", .primary), (" an area     ", .secondary), ("Click", .primary), (" a window     ", .secondary),
        ("↩", .primary), (" whole screen     ", .secondary), ("⌥", .primary), (" copy text     ", .secondary),
        ("esc", .primary), (" cancel", .secondary),
    ]
    /// The hint gives way when the pointer comes this close, so it never hides what you're aiming at.
    private static let hintClearance: CGFloat = 48

    /// Device pixels per point: the display's backing scale.
    private var scale: CGFloat { still.screen?.backingScaleFactor ?? still.scale }

    init(still: Still, imageSize: ImageSize, windows: [CGRect] = []) {
        self.still = still
        self.imageSize = imageSize
        self.windows = windows
        super.init(frame: NSRect(origin: .zero, size: still.frame.size))
        wantsLayer = true
        picture.contents = still.image
        picture.contentsGravity = .resize
        picture.frame = bounds
        dim.fillRule = .evenOdd
        outline.fillColor = nil
        loupe.prepare(image: still.image, scale: scale)
        hint.runs = Self.hintRuns
        for label in [pill, hint] { label.screen = bounds }
        for sublayer in [picture, dim, outline, pill, hint, loupe] as [CALayer] {
            sublayer.contentsScale = scale
            layer?.addSublayer(sublayer)
        }
        restyle()
        addTrackingArea(
            NSTrackingArea(rect: .zero, options: [.mouseMoved, .activeAlways, .inVisibleRect], owner: self))
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityLabel("Common Shot")
        setAccessibilityHelp(
            "Drag for an area, click for a window, Return for the whole screen. Hold Option to copy the text. "
                + "Escape cancels.")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        restyle()
    }

    // MARK: State

    func show(hovered window: WindowFrame?) {
        hovered = window
        guard start == nil else { return }
        refresh()
    }

    func showSelection(_ rect: CGRect) {
        selection = Geometry.snapped(rect, scale: scale)
        refresh()
    }

    /// `mouse` in AppKit's global coordinates.
    func pointerMoved(to mouse: NSPoint) {
        let point = NSPoint(x: mouse.x - still.frame.minX, y: mouse.y - still.frame.minY)
        pointer = bounds.contains(point) ? point : nil
        refresh()
    }

    // MARK: Drawing

    /// Colours follow the appearance, so they're resolved again when it changes.
    private func restyle() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            dim.fillColor = NSColor.black.withAlphaComponent(increaseContrast ? 0.5 : 0.3).cgColor
            loupe.restyle()
        }
        for label in [pill, hint] {
            label.appearance = effectiveAppearance
            label.increaseContrast = increaseContrast
            label.reduceTransparency = reduceTransparency
            label.restyle()
        }
        refresh()
    }

    /// Lays out every layer from the state: what's lit, its outline and size, the loupe, the hint.
    private func refresh() {
        let hole = selection ?? hovered.map { Geometry.snapped(local($0.frame), scale: scale) }
        let lit = hole.map { $0.intersection(bounds) }.flatMap { $0.isNull || $0.isEmpty ? nil : $0 }
        withoutAnimation {
            let path = CGMutablePath()
            path.addRect(bounds)
            if let hole { path.addRect(hole) }
            dim.path = path
            dim.frame = bounds

            // One device pixel just outside what's captured, so the line covers none of it.
            let width = (increaseContrast ? 2 : 1) / scale
            outline.lineWidth = width
            outline.path = hole.map { CGPath(rect: $0.insetBy(dx: -width / 2, dy: -width / 2), transform: nil) }
            outline.frame = bounds
            effectiveAppearance.performAsCurrentDrawingAppearance {
                outline.strokeColor = (asText ? NSColor.systemOrange : NSColor.controlAccentColor).cgColor
            }

            var obstacles = still.notch.map { [$0] } ?? []
            if let lit, let hole {
                pill.runs = sizeRuns(for: hole)
                pill.frame = Placement.pill(size: pill.fittingSize, for: lit, in: bounds, avoiding: obstacles)
                pill.isHidden = false
                obstacles.append(pill.frame)
                setAccessibilityValue(pill.runs.map(\.0).joined())
            } else {
                pill.isHidden = true
                setAccessibilityValue(nil)
            }

            let hintSize = hint.fittingSize
            hint.frame = CGRect(
                x: ((bounds.width - hintSize.width) / 2).rounded(), y: 24, width: hintSize.width,
                height: hintSize.height)
            hint.isHidden =
                selection != nil
                || pointer.map { hint.frame.insetBy(dx: -Self.hintClearance, dy: -Self.hintClearance).contains($0) }
                    ?? true

            if let pointer {
                loupe.frame = Placement.loupe(side: Loupe.side, at: pointer, in: bounds, avoiding: obstacles)
                loupe.show(pixelAt: pointer, in: bounds.size)
                loupe.isHidden = false
            } else {
                loupe.isHidden = true
            }
        }
    }

    /// "1040 × 480" and what it costs a prompt, or "Copy text" with ⌥.
    private func sizeRuns(for hole: CGRect) -> [(String, MaterialLabel.Style)] {
        guard !asText else { return [("Copy text", .primary)] }
        let width = Int((hole.width * scale).rounded())
        let height = Int((hole.height * scale).rounded())
        let fitted = imageSize.fit(width: width, height: height)
        let tokens = ImageSize.estimatedTokens(width: fitted.width, height: fitted.height)
        return [("\(width) × \(height)", .primary), ("  \(ImageSize.describe(tokens: tokens))", .secondary)]
    }

    private func local(_ frame: CGRect) -> CGRect {
        Geometry.local(frame, displayBounds: still.displayBounds)
    }

    private func withoutAnimation(_ change: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        change()
        CATransaction.commit()
    }

    // MARK: Events

    override func mouseMoved(with event: NSEvent) {
        overlay?.pointerMoved(to: NSEvent.mouseLocation)
    }

    override func flagsChanged(with event: NSEvent) {
        overlay?.modifiersChanged(event.modifierFlags)
    }

    override func mouseDown(with event: NSEvent) {
        start = settled(convert(event.locationInWindow, from: nil))
        end = start
    }

    override func mouseDragged(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        guard let start, let end else { return overlay?.pointerMoved(to: NSEvent.mouseLocation) ?? () }
        if let moving {
            let moved = Precision.moved(
                start: start, end: end, by: CGVector(dx: location.x - moving.x, dy: location.y - moving.y),
                within: bounds)
            self.start = moved.start
            self.end = moved.end
            self.moving = location
        } else {
            self.end = settled(location)
        }
        dragChanged()
    }

    override func mouseUp(with event: NSEvent) {
        guard let start else { return }
        let end = end ?? convert(event.locationInWindow, from: nil)
        self.start = nil
        self.end = nil
        moving = nil
        selection = nil
        let rect = Geometry.selection(from: start, to: end, within: bounds)
        overlay?.dragEnded(
            in: self, selection: Geometry.snapped(rect, scale: scale), asText: event.modifierFlags.contains(.option))
    }

    override func rightMouseDown(with event: NSEvent) {
        overlay?.cancel()
    }

    override func keyDown(with event: NSEvent) {
        let arrows: [UInt16: Precision.Arrow] = [123: .left, 124: .right, 125: .down, 126: .up]
        if let arrow = arrows[event.keyCode] {
            nudge(arrow, large: event.modifierFlags.contains(.shift))
        } else if event.keyCode == 49 {  // Space
            // Held during a drag, it moves the selection, as with the system's ⇧⌘4; otherwise it does nothing.
            if start != nil, !event.isARepeat {
                moving = convert(window?.mouseLocationOutsideOfEventStream ?? .zero, from: nil)
            }
        } else {
            overlay?.keyDown(event)
        }
    }

    override func keyUp(with event: NSEvent) {
        if event.keyCode == 49 { moving = nil }
    }

    /// The selection follows `start` and `end`, and the loupe follows the corner being dragged.
    private func dragChanged() {
        guard let start, let end else { return }
        let rect = Geometry.selection(from: start, to: end, within: bounds)
        if !Geometry.isClick(rect) {
            overlay?.dragBegan(in: self)
            selection = Geometry.snapped(rect, scale: scale)
        }
        overlay?.pointerMoved(to: NSPoint(x: still.frame.minX + end.x, y: still.frame.minY + end.y))
    }

    /// A drag's corner, settled on a window's or the display's edge when it comes near one.
    private func settled(_ point: CGPoint) -> CGPoint {
        Precision.snapped(point, toEdgesOf: windows, within: bounds)
    }

    /// Moves the pointer one device pixel, or ten with ⇧: the drag's corner while the button is down, the
    /// crosshair otherwise. The system pointer moves with it, so the next nudge of the mouse carries on
    /// from there. Never snapped: the keys are for the exact pixel.
    private func nudge(_ arrow: Precision.Arrow, large: Bool) {
        guard let from = end ?? pointer else { return }
        let to = Precision.nudge(from, arrow, large: large, scale: scale, within: bounds)
        CGWarpMouseCursorPosition(Geometry.global(to, displayBounds: still.displayBounds))
        // Without this, a warp holds the pointer still for a quarter of a second.
        CGAssociateMouseAndMouseCursorPosition(1)
        if start != nil {
            end = to
            dragChanged()
        } else {
            overlay?.pointerMoved(to: NSPoint(x: still.frame.minX + to.x, y: still.frame.minY + to.y))
        }
    }
}

/// The frozen pixels under the pointer, magnified so each device pixel is a whole number of them, on a
/// faint grid, with the one under the pointer ringed in black and white so it shows on any colour.
private final class Loupe: CALayer {
    /// The loupe shows this many image pixels across, an odd number so one sits in the middle.
    static let pixels: CGFloat = 21
    /// Six points a pixel: a whole number of device pixels at 1× and at 2×.
    static let side: CGFloat = pixels * 6

    private let image = CALayer()
    private let grid = CAShapeLayer()
    private let ringOuter = CAShapeLayer()
    private let ringInner = CAShapeLayer()
    private let rim = CALayer()
    private var picture: CGImage?

    func prepare(image picture: CGImage, scale: CGFloat) {
        self.picture = picture
        frame.size = CGSize(width: Self.side, height: Self.side)
        cornerRadius = 10
        cornerCurve = .continuous
        masksToBounds = true
        image.contents = picture
        image.magnificationFilter = .nearest
        image.frame = bounds

        let cell = Self.side / Self.pixels
        let hairline = 1 / scale
        let lines = CGMutablePath()
        for index in 1..<Int(Self.pixels) {
            let offset = CGFloat(index) * cell
            lines.move(to: CGPoint(x: offset, y: 0))
            lines.addLine(to: CGPoint(x: offset, y: Self.side))
            lines.move(to: CGPoint(x: 0, y: offset))
            lines.addLine(to: CGPoint(x: Self.side, y: offset))
        }
        grid.path = lines
        grid.lineWidth = hairline
        grid.frame = bounds

        let centre = CGRect(x: (Self.side - cell) / 2, y: (Self.side - cell) / 2, width: cell, height: cell)
        ringInner.path = CGPath(rect: centre.insetBy(dx: -hairline / 2, dy: -hairline / 2), transform: nil)
        ringOuter.path = CGPath(rect: centre.insetBy(dx: -hairline * 1.5, dy: -hairline * 1.5), transform: nil)
        for ring in [ringInner, ringOuter] {
            ring.fillColor = nil
            ring.lineWidth = hairline
            ring.frame = bounds
        }

        // A dark line outside a light one, one device pixel each, so the edge reads on any picture.
        borderWidth = hairline
        rim.frame = bounds.insetBy(dx: hairline, dy: hairline)
        rim.cornerRadius = cornerRadius - hairline
        rim.cornerCurve = .continuous
        rim.borderWidth = hairline
        for sublayer in [image, grid, ringOuter, ringInner, rim] as [CALayer] {
            sublayer.contentsScale = scale
            addSublayer(sublayer)
        }
        restyle()
    }

    func restyle() {
        grid.strokeColor = NSColor.gray.withAlphaComponent(0.25).cgColor
        ringOuter.strokeColor = NSColor.black.cgColor
        ringInner.strokeColor = NSColor.white.cgColor
        borderColor = NSColor.black.withAlphaComponent(0.45).cgColor
        rim.borderColor = NSColor.white.withAlphaComponent(0.7).cgColor
    }

    /// Centres the pixel under `point`, in a view of `size` points covering the whole picture.
    func show(pixelAt point: CGPoint, in size: CGSize) {
        guard let picture else { return }
        let width = CGFloat(picture.width)
        let height = CGFloat(picture.height)
        // Counted from the bottom left, in the image's unit square, as `contentsRect` is.
        let centerX = (point.x * width / size.width).rounded(.down) + 0.5
        let centerY = (point.y * height / size.height).rounded(.down) + 0.5
        let half = Self.pixels / 2
        image.contentsRect = CGRect(
            x: (centerX - half) / width, y: (centerY - half) / height, width: Self.pixels / width,
            height: Self.pixels / height)
    }
}
