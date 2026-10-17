import AppKit
import QuartzCore
import ShotKit

/// What the person picked on the overlay.
enum Pick {
    /// A dragged rectangle, in the points of the still's screen, from its bottom-left corner.
    case area(Still, CGRect)
    case screen(Still)
    case window(UInt32, on: Still)
}

/// The frozen displays, one window each, over everything including the menu bar. Drag for an area,
/// click for the window under the pointer, Return for the whole screen, Escape to cancel. Holding ⌥
/// copies the text in what's picked instead of the image.
@MainActor
final class Overlay {
    var onPick: ((pick: Pick, asText: Bool)?) -> Void = { _ in }
    private let freeze: Freeze
    private var windows: [OverlayWindow] = []
    private var dragging = false

    init(freeze: Freeze) {
        self.freeze = freeze
    }

    func show() {
        windows = freeze.stills.map { still in
            let window = OverlayWindow(still: still)
            window.overlayView.overlay = self
            return window
        }
        for window in windows { window.orderFrontRegardless() }
        let mouse = NSEvent.mouseLocation
        (windows.first { NSMouseInRect(mouse, $0.frame, false) } ?? windows.first)?.makeKey()
        pointerMoved(to: mouse)
    }

    func close() {
        for window in windows { window.orderOut(nil) }
        windows = []
    }

    // MARK: Events from the views

    /// Highlights the window under the pointer, on whichever screens it spans, and moves the loupe.
    func pointerMoved(to mouse: NSPoint) {
        for window in windows { window.overlayView.showLoupe(at: mouse) }
        guard !dragging else { return }
        let hovered = still(at: mouse).flatMap { still -> WindowFrame? in
            let local = NSPoint(x: mouse.x - still.screen.frame.minX, y: mouse.y - still.screen.frame.minY)
            return WindowFrame.topmost(
                at: Geometry.global(local, displayBounds: still.displayBounds), in: freeze.windows)
        }
        for window in windows { window.overlayView.show(hovered: hovered) }
    }

    func modifiersChanged(_ flags: NSEvent.ModifierFlags) {
        let asText = flags.contains(.option)
        for window in windows { window.overlayView.asText = asText }
    }

    func dragBegan(in view: OverlayView) {
        guard !dragging else { return }
        dragging = true
        for window in windows where window.overlayView !== view { window.overlayView.show(hovered: nil) }
    }

    func dragEnded(in view: OverlayView, selection: CGRect, asText: Bool) {
        let dragged = dragging
        dragging = false
        switch Gesture.from(selection: selection, dragged: dragged, overWindow: view.hovered != nil) {
        case .area(let rect): onPick((.area(view.still, rect), asText))
        case .window: if let hovered = view.hovered { onPick((.window(hovered.id, on: view.still), asText)) }
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

    /// As if `rect` had been dragged on the main display, for `--overlay`.
    func select(_ rect: CGRect) {
        guard let view = windows.first?.overlayView else { return }
        dragBegan(in: view)
        view.showSelection(rect)
    }

    private func still(at mouse: NSPoint) -> Still? {
        freeze.stills.first { NSMouseInRect(mouse, $0.screen.frame, false) }
    }
}

final class OverlayWindow: NSPanel {
    let overlayView: OverlayView

    init(still: Still) {
        overlayView = OverlayView(still: still)
        super.init(
            contentRect: still.screen.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered,
            defer: false)
        level = .screenSaver
        isOpaque = true
        hasShadow = false
        animationBehavior = .none
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        acceptsMouseMovedEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        contentView = overlayView
        setFrame(still.screen.frame, display: false)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// The frozen picture with the dimming, outline, badge, loupe, and hint in layers above it, so following
/// the pointer moves a few layers rather than redrawing a 5K image.
final class OverlayView: NSView {
    let still: Still
    weak var overlay: Overlay?
    private(set) var hovered: WindowFrame?
    private var start: CGPoint?
    private var selection: CGRect?
    var asText = false {
        didSet {
            guard asText != oldValue else { return }
            if let selection { showSelection(selection) } else { show(hovered: hovered) }
        }
    }

    private let picture = CALayer()
    private let dim = CAShapeLayer()
    private let outline = CAShapeLayer()
    private let badge = Label()
    private let hint = Label()
    private let loupe = CALayer()
    private let loupeImage = CALayer()
    private let loupeCenter = CAShapeLayer()

    /// The loupe shows this many image pixels across, an odd number so one sits in the middle.
    private static let loupePixels: CGFloat = 21
    private static let loupeSide: CGFloat = 126
    private static let hintText = "Drag for an area   Click for a window   ↩ Whole screen   ⌥ Copy text   Esc Cancel"

    init(still: Still) {
        self.still = still
        super.init(frame: NSRect(origin: .zero, size: still.screen.frame.size))
        wantsLayer = true
        let scale = still.screen.backingScaleFactor
        picture.contents = still.image
        picture.contentsGravity = .resize
        picture.frame = bounds
        dim.fillRule = .evenOdd
        dim.fillColor = NSColor.black.withAlphaComponent(0.35).cgColor
        outline.fillColor = nil
        outline.lineWidth = 1
        badge.scale = scale
        badge.isHidden = true
        hint.scale = scale
        hint.set(Self.hintText)
        hint.frame.origin = CGPoint(x: ((bounds.width - hint.frame.width) / 2).rounded(), y: 28)

        loupe.frame.size = CGSize(width: Self.loupeSide, height: Self.loupeSide)
        loupe.cornerRadius = 10
        loupe.cornerCurve = .continuous
        loupe.masksToBounds = true
        loupe.borderWidth = 1
        loupe.borderColor = NSColor.white.withAlphaComponent(0.8).cgColor
        loupeImage.contents = still.image
        loupeImage.magnificationFilter = .nearest
        loupeImage.frame = loupe.bounds
        let pixel = Self.loupeSide / Self.loupePixels
        loupeCenter.path = CGPath(
            rect: CGRect(
                x: (Self.loupeSide - pixel) / 2, y: (Self.loupeSide - pixel) / 2, width: pixel, height: pixel),
            transform: nil)
        loupeCenter.fillColor = nil
        loupeCenter.strokeColor = NSColor.white.cgColor
        loupeCenter.lineWidth = 1
        loupe.addSublayer(loupeImage)
        loupe.addSublayer(loupeCenter)
        loupe.isHidden = true

        for sublayer in [picture, dim, outline, badge, hint, loupe] { layer?.addSublayer(sublayer) }
        update(hole: nil, outlineColor: nil)
        addTrackingArea(
            NSTrackingArea(rect: .zero, options: [.mouseMoved, .activeAlways, .inVisibleRect], owner: self))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    private var accent: NSColor { asText ? .systemOrange : .controlAccentColor }

    // MARK: Drawing

    func show(hovered window: WindowFrame?) {
        hovered = window
        guard start == nil else { return }
        let hole = window.map { Geometry.local($0.frame, displayBounds: still.displayBounds) }
        update(hole: hole, outlineColor: hole == nil ? nil : accent)
        withoutAnimation {
            badge.isHidden = true
            hint.isHidden = false
        }
    }

    func showSelection(_ rect: CGRect) {
        selection = rect
        update(hole: rect, outlineColor: asText ? accent : .white)
        let pixels = Geometry.pixels(
            of: rect, viewSize: bounds.size, imageWidth: still.image.width, imageHeight: still.image.height)
        withoutAnimation {
            badge.set("\(Int(pixels.width)) × \(Int(pixels.height))" + (asText ? " · Text" : ""))
            // Under the selection's bottom-right corner, or inside it when that would leave the screen.
            var origin = CGPoint(x: rect.maxX - badge.frame.width, y: rect.minY - badge.frame.height - 6)
            if origin.y < 4 { origin.y = rect.minY + 6 }
            origin.x = min(max(origin.x, 4), bounds.width - badge.frame.width - 4)
            badge.frame.origin = origin
            badge.isHidden = false
            hint.isHidden = true
        }
    }

    /// Magnifies the frozen pixels under `mouse`, given in screen coordinates, beside the pointer.
    func showLoupe(at mouse: NSPoint) {
        let point = NSPoint(x: mouse.x - still.screen.frame.minX, y: mouse.y - still.screen.frame.minY)
        guard bounds.contains(point) else {
            withoutAnimation { loupe.isHidden = true }
            return
        }
        let scaleX = CGFloat(still.image.width) / bounds.width
        let scaleY = CGFloat(still.image.height) / bounds.height
        // Centred on the pixel under the pointer, in the image's unit square counted from the bottom left.
        let centerX = (point.x * scaleX).rounded(.down) + 0.5
        let centerY = (point.y * scaleY).rounded(.down) + 0.5
        let half = Self.loupePixels / 2
        let side = Self.loupeSide
        var origin = CGPoint(x: point.x + 24, y: point.y - 24 - side)
        if origin.x + side > bounds.width - 4 { origin.x = point.x - 24 - side }
        if origin.y < 4 { origin.y = point.y + 24 }
        withoutAnimation {
            loupeImage.contentsRect = CGRect(
                x: (centerX - half) / CGFloat(still.image.width), y: (centerY - half) / CGFloat(still.image.height),
                width: Self.loupePixels / CGFloat(still.image.width),
                height: Self.loupePixels / CGFloat(still.image.height))
            loupe.frame.origin = origin
            loupe.isHidden = false
        }
    }

    /// Dims everything but `hole`, and outlines the hole when there is one.
    private func update(hole: CGRect?, outlineColor: NSColor?) {
        withoutAnimation {
            let path = CGMutablePath()
            path.addRect(bounds)
            if let hole { path.addRect(hole) }
            dim.path = path
            dim.frame = bounds
            if let hole, let outlineColor {
                // Half a point outside the hole, so the line covers none of what's captured.
                outline.path = CGPath(rect: hole.insetBy(dx: -0.5, dy: -0.5), transform: nil)
                outline.strokeColor = outlineColor.cgColor
            } else {
                outline.path = nil
            }
            outline.frame = bounds
        }
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
        start = convert(event.locationInWindow, from: nil)
    }

    override func mouseDragged(with event: NSEvent) {
        overlay?.pointerMoved(to: NSEvent.mouseLocation)
        guard let start else { return }
        let rect = Geometry.selection(from: start, to: convert(event.locationInWindow, from: nil), within: bounds)
        guard !Geometry.isClick(rect) else { return }
        overlay?.dragBegan(in: self)
        showSelection(rect)
    }

    override func mouseUp(with event: NSEvent) {
        guard let start else { return }
        self.start = nil
        selection = nil
        let rect = Geometry.selection(from: start, to: convert(event.locationInWindow, from: nil), within: bounds)
        overlay?.dragEnded(in: self, selection: rect, asText: event.modifierFlags.contains(.option))
    }

    override func rightMouseDown(with event: NSEvent) {
        overlay?.cancel()
    }

    override func keyDown(with event: NSEvent) {
        overlay?.keyDown(event)
    }
}

/// White text on a dark rounded pill, sized to fit.
private final class Label: CALayer {
    private let text = CATextLayer()
    private static var font: NSFont { .monospacedDigitSystemFont(ofSize: 12, weight: .medium) }

    var scale: CGFloat = 2 {
        didSet { text.contentsScale = scale }
    }

    override init() {
        super.init()
        backgroundColor = NSColor.black.withAlphaComponent(0.75).cgColor
        cornerRadius = 6
        cornerCurve = .continuous
        text.font = Self.font
        text.fontSize = Self.font.pointSize
        text.foregroundColor = NSColor.white.cgColor
        text.alignmentMode = .center
        addSublayer(text)
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func set(_ string: String) {
        let size = (string as NSString).size(withAttributes: [.font: Self.font])
        frame.size = CGSize(width: ceil(size.width) + 16, height: ceil(size.height) + 8)
        text.frame = CGRect(x: 0, y: 4, width: frame.width, height: ceil(size.height))
        text.string = string
    }
}
