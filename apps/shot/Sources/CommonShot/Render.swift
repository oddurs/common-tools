import AppKit
import ImageIO
import ShotKit
import UniformTypeIdentifiers

/// `CommonShot --render <folder>` pictures the overlay in each of its states, and the preview, in light
/// and dark, over a made-up frozen desktop on two displays: a 2× laptop panel and a 1× monitor beside it.
/// Nothing is shown on screen and no permission is needed, so a change to how Shot looks can be
/// reviewed from the PNGs it writes.
@MainActor
enum Render {
    /// The laptop panel is the main display; the monitor sits to its right, top edges aligned.
    static let panel = CGRect(x: 0, y: 0, width: 1512, height: 982)
    static let monitor = CGRect(x: 1512, y: 982 - 1080, width: 1920, height: 1080)

    /// Two windows on the panel, front to back, in global display coordinates.
    static let terminal = WindowFrame(id: 2, frame: CGRect(x: 760, y: 420, width: 640, height: 400))
    static let editor = WindowFrame(id: 1, frame: CGRect(x: 120, y: 120, width: 820, height: 600))
    static let browser = WindowFrame(id: 3, frame: CGRect(x: 1512 + 260, y: 140, width: 1200, height: 760))

    static func run(into folder: URL) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for (name, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
            guard let appearance = NSAppearance(named: appearance) else { continue }
            var failure: Error?
            appearance.performAsCurrentDrawingAppearance {
                do {
                    try renderAll(suffix: name, appearance: appearance, into: folder)
                } catch {
                    failure = error
                }
            }
            if let failure { throw failure }
        }
    }

    private static func renderAll(suffix: String, appearance: NSAppearance, into folder: URL) throws {
        let freeze = Freeze(
            stills: [still(panel, scale: 2), still(monitor, scale: 1)], windows: [terminal, editor, browser])
        // Points in AppKit's global coordinates, up from the panel's bottom-left corner.
        func appKit(_ point: CGPoint) -> CGPoint { CGPoint(x: point.x, y: panel.maxY - point.y) }

        func states(_ name: String, crop: CGRect? = nil, display: Int = 0, _ stage: (Overlay) -> Void) throws {
            let overlay = Overlay(freeze: freeze)
            for view in overlay.views { view.appearance = appearance }
            stage(overlay)
            let view = overlay.views[display]
            let image = try picture(of: view)
            try write(image, to: folder.appending(path: "\(name)-\(suffix).png"))
            if let crop {
                let detail = try cropped(image, to: crop, in: view)
                try write(detail, to: folder.appending(path: "\(name)-\(suffix)-detail.png"))
            }
        }

        // Over the wallpaper: the screen dims, the loupe follows, the hint names the keys.
        try states("idle", crop: CGRect(x: 40, y: 760, width: 220, height: 200)) {
            $0.pointerMoved(to: appKit(CGPoint(x: 60, y: 80)))
        }
        // Over the terminal: it alone is lit, outlined in the accent colour.
        try states("hover", crop: CGRect(x: 1040, y: 520, width: 400, height: 240)) {
            $0.pointerMoved(to: appKit(CGPoint(x: 1100, y: 600)))
        }
        // Mid-drag over the editor's code, the pointer at the corner being dragged.
        let drag = CGRect(x: 300, y: 560, width: 520, height: 240)
        try states("drag", crop: CGRect(x: drag.maxX - 260, y: drag.minY - 180, width: 460, height: 260)) {
            $0.select(drag)
            $0.pointerMoved(to: CGPoint(x: drag.maxX, y: drag.minY))
        }
        // The same with ⌥ held: text instead of the image.
        try states("text", crop: CGRect(x: drag.maxX - 260, y: drag.minY - 180, width: 460, height: 260)) {
            $0.select(drag)
            $0.modifiersChanged(.option)
            $0.pointerMoved(to: CGPoint(x: drag.maxX, y: drag.minY))
        }
        // A drag into the panel's bottom-right corner, where the pill and the loupe must flip.
        let corner = CGRect(x: 1100, y: 0, width: 412, height: 300)
        try states("edge", crop: CGRect(x: 1080, y: 0, width: 432, height: 340)) {
            $0.select(corner)
            $0.pointerMoved(to: CGPoint(x: corner.maxX - 1, y: corner.minY + 1))
        }
        // On the 1× monitor, dragged up against the edge it shares with the panel.
        let edge = CGRect(x: 0, y: 500, width: 360, height: 220)
        try states("monitor", crop: CGRect(x: 0, y: 380, width: 520, height: 380), display: 1) {
            $0.select(edge, on: 1)
            $0.pointerMoved(to: CGPoint(x: monitor.minX + edge.minX + 1, y: edge.minY))
        }

        // The preview, over the corner of the desktop it appears in.
        let shot = try crop(desktop(panel, scale: 2), CGRect(x: 360, y: 640, width: 1040, height: 520))
        let card = Toast.card(shot, scale: 2, caption: "Copied · 1040 × 520 · ≈ 721 tokens", detail: nil, file: nil) {}
        card.appearance = appearance
        try write(
            try onDesktop(card, scale: 2, corner: panel.size), to: folder.appending(path: "preview-\(suffix).png"))
    }

    // MARK: The made-up desktop

    private static func still(_ display: CGRect, scale: CGFloat) -> Still {
        let main = panel
        let frame = CGRect(
            x: display.minX, y: main.maxY - display.maxY, width: display.width, height: display.height)
        return Still(frame: frame, displayBounds: display, image: desktop(display, scale: scale), screen: nil)
    }

    /// A wallpaper, a menu bar, and the windows on this display, drawn with the system's colours in the
    /// current appearance.
    private static func desktop(_ display: CGRect, scale: CGFloat) -> CGImage {
        let width = Int(display.width * scale)
        let height = Int(display.height * scale)
        let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        // Top-left origin in points, like global display coordinates, offset to this display.
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: scale, y: -scale)
        context.translateBy(x: -display.minX, y: -display.minY)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)

        let wallpaper = NSGradient(colors: [.systemIndigo, .systemTeal, .systemMint])
        wallpaper?.draw(in: display, angle: 60)
        NSColor.windowBackgroundColor.withAlphaComponent(0.8).setFill()
        CGRect(x: display.minX, y: display.minY, width: display.width, height: 24).fill()
        menuBar(in: display)

        // Back to front, so the terminal ends up on top.
        for window in [browser, editor, terminal] where display.intersects(window.frame) {
            draw(window)
        }
        NSGraphicsContext.restoreGraphicsState()
        return context.makeImage()!
    }

    private static func menuBar(in display: CGRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.menuBarFont(ofSize: 0), .foregroundColor: NSColor.labelColor,
        ]
        var x = display.minX + 20
        for title in ["", "Editor", "File", "Edit", "View", "Window", "Help"] {
            (title as NSString).draw(at: CGPoint(x: x, y: display.minY + 4), withAttributes: attributes)
            x += (title as NSString).size(withAttributes: attributes).width + 20
        }
    }

    private static func draw(_ window: WindowFrame) {
        let frame = window.frame
        let body = NSBezierPath(roundedRect: frame, xRadius: 10, yRadius: 10)
        NSColor.windowBackgroundColor.setFill()
        body.fill()
        NSColor.separatorColor.setStroke()
        body.stroke()
        for (index, color) in [NSColor.systemRed, .systemYellow, .systemGreen].enumerated() {
            color.setFill()
            NSBezierPath(
                ovalIn: CGRect(x: frame.minX + 14 + CGFloat(index) * 20, y: frame.minY + 12, width: 12, height: 12)
            )
            .fill()
        }
        let lines: [String]
        switch window.id {
        case terminal.id:
            lines = [
                "$ swift test --filter Geometry", "Building for debugging...", "[8/8] Linking ShotKitTests",
                "Test run with 12 tests in 1 suite passed after 0.004 seconds.", "$ git status --short",
                " M Sources/ShotKit/Geometry.swift", "$ _",
            ]
        case editor.id:
            lines = [
                "public enum Geometry {", "    public static let minimumDrag: CGFloat = 4", "",
                "    public static func selection(",
                "        from start: CGPoint, to end: CGPoint, within bounds: CGRect",
                "    ) -> CGRect {", "        let rect = CGRect(",
                "            x: min(start.x, end.x), y: min(start.y, end.y),",
                "            width: abs(end.x - start.x), height: abs(end.y - start.y))",
                "        let clipped = rect.intersection(bounds)", "        return clipped.isNull ? .zero : clipped",
                "    }",
                "}",
            ]
        default:
            lines = [
                "Common Shot", "", "Screenshots straight to the clipboard, for macOS.",
                "Press ⇧⌘2, drag over what you want, and paste it.",
            ]
        }
        let mono = window.id != browser.id
        let font = mono ? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular) : NSFont.systemFont(ofSize: 17)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.labelColor]
        var y = frame.minY + 44
        let sidebar = window.id == editor.id ? 180.0 : 0
        if sidebar > 0 {
            NSColor.underPageBackgroundColor.setFill()
            CGRect(x: frame.minX + 1, y: frame.minY + 36, width: sidebar, height: frame.height - 37).fill()
            let files = ["Clipboard.swift", "FileName.swift", "Geometry.swift", "Gesture.swift", "ImageSize.swift"]
            for (index, file) in files.enumerated() {
                let row = CGPoint(x: frame.minX + 16, y: frame.minY + 48 + CGFloat(index) * 24)
                if index == 2 {
                    NSColor.selectedContentBackgroundColor.setFill()
                    NSBezierPath(
                        roundedRect: CGRect(x: frame.minX + 8, y: row.y - 3, width: sidebar - 16, height: 22),
                        xRadius: 5, yRadius: 5
                    ).fill()
                }
                (file as NSString).draw(
                    at: row,
                    withAttributes: [
                        .font: NSFont.systemFont(ofSize: 13),
                        .foregroundColor: index == 2 ? NSColor.alternateSelectedControlTextColor : NSColor.labelColor,
                    ])
            }
        }
        for line in lines {
            (line as NSString).draw(at: CGPoint(x: frame.minX + sidebar + 20, y: y), withAttributes: attributes)
            y += mono ? 20 : 28
        }
    }

    // MARK: Pictures

    /// The view's layers, drawn at its display's scale.
    private static func picture(of view: OverlayView) throws -> CGImage {
        let scale = view.still.scale
        let width = Int(view.bounds.width * scale)
        let height = Int(view.bounds.height * scale)
        guard
            let context = CGContext(
                data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
            let layer = view.layer
        else { throw OutputError.encoding }
        context.scaleBy(x: scale, y: scale)
        // `render(in:)` ignores a layer's magnification filter; the picture is drawn 1:1 anyway, so
        // nearest-neighbour everywhere shows the loupe as the screen does.
        context.interpolationQuality = .none
        layer.render(in: context)
        guard let image = context.makeImage() else { throw OutputError.encoding }
        return image
    }

    /// `rect`, in the view's points from its bottom-left corner, at full resolution.
    private static func cropped(_ image: CGImage, to rect: CGRect, in view: OverlayView) throws -> CGImage {
        let pixels = Geometry.pixels(
            of: rect, viewSize: view.bounds.size, imageWidth: image.width, imageHeight: image.height)
        guard let cropped = image.cropping(to: pixels) else { throw OutputError.encoding }
        return cropped
    }

    /// `rect` in points from the top-left, at `scale`.
    private static func crop(_ image: CGImage, _ rect: CGRect) throws -> CGImage {
        guard let cropped = image.cropping(to: rect) else { throw OutputError.encoding }
        return cropped
    }

    /// The preview card over the bottom-right corner of the desktop, where it appears.
    private static func onDesktop(_ card: NSView, scale: CGFloat, corner: CGSize) throws -> CGImage {
        card.frame.size = card.fittingSize
        card.layoutSubtreeIfNeeded()
        let size = CGSize(width: card.frame.width + 64, height: card.frame.height + 64)
        let backdrop = desktop(
            CGRect(
                x: corner.width - size.width, y: corner.height - size.height, width: size.width, height: size.height),
            scale: scale)
        guard
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: Int(card.frame.width * scale),
                pixelsHigh: Int(card.frame.height * scale), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
        else { throw OutputError.encoding }
        rep.size = card.frame.size
        card.cacheDisplay(in: card.bounds, to: rep)
        guard let cardImage = rep.cgImage,
            let context = CGContext(
                data: nil, width: backdrop.width, height: backdrop.height, bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { throw OutputError.encoding }
        context.draw(backdrop, in: CGRect(x: 0, y: 0, width: backdrop.width, height: backdrop.height))
        // Inset by the preview's margin from the visible frame's corner.
        context.draw(
            cardImage,
            in: CGRect(
                x: CGFloat(backdrop.width - cardImage.width) - 32 * scale, y: 32 * scale,
                width: CGFloat(cardImage.width), height: CGFloat(cardImage.height)))
        guard let image = context.makeImage() else { throw OutputError.encoding }
        return image
    }

    private static func write(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { throw OutputError.encoding }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw OutputError.encoding }
    }
}
