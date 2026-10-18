import AppKit
import CoreImage
import QuartzCore

/// The overlay's own material. A system material blurs what is behind its window, and behind the overlay
/// is the live screen, not the frozen one; so the overlay blurs the frozen picture once, small, and each
/// floating piece shows its part of that, under the system's window colour. It costs one blur per
/// shortcut, off the main thread, and draws the same offscreen as on screen.
enum Backdrop {
    /// A quarter of the picture's size is plenty for a blur this wide, and a fraction of the work.
    nonisolated static func blurred(_ image: CGImage) -> CGImage? {
        let input = CIImage(cgImage: image)
        let small = input.transformed(by: CGAffineTransform(scaleX: 0.25, y: 0.25))
        let blurred = small.clampedToExtent()
            .applyingGaussianBlur(sigma: 8)
            // A material lifts the colour under it a little, as the system's do.
            .applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 1.4])
            .cropped(to: small.extent)
        return context.createCGImage(blurred, from: small.extent)
    }

    nonisolated private static let context = CIContext(options: [.cacheIntermediates: false])
}

/// A capsule of text over the backdrop: the size by the selection, or the hint along the bottom.
final class MaterialLabel: CALayer {
    enum Style {
        case primary
        case secondary
    }

    var runs: [(String, Style)] = [] {
        didSet {
            guard !runs.elementsEqual(oldValue, by: { $0.0 == $1.0 && $0.1 == $1.1 }) else { return }
            line = nil
            setNeedsDisplay()
        }
    }
    /// The blurred frozen picture, covering `screen`, the overlay view's bounds.
    var backdrop: CGImage? { didSet { setNeedsDisplay() } }
    var screen: CGRect = .zero
    /// Moving shows a different part of the backdrop, so it draws again.
    override var frame: CGRect {
        didSet { if frame.origin != oldValue.origin, backdrop != nil { setNeedsDisplay() } }
    }
    var appearance = NSAppearance.currentDrawing()
    var increaseContrast = false
    var reduceTransparency = false

    private static let height: CGFloat = 24
    private static let padding: CGFloat = 10
    private var line: CTLine?

    override init() {
        super.init()
        needsDisplayOnBoundsChange = true
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// The size the runs need, in points.
    var fittingSize: CGSize {
        let width = CTLineGetTypographicBounds(currentLine(), nil, nil, nil)
        return CGSize(width: ceil(width) + 2 * Self.padding, height: Self.height)
    }

    /// Resolves the colours again, as after an appearance change.
    func restyle() {
        line = nil
        setNeedsDisplay()
    }

    override func draw(in context: CGContext) {
        let shape = CGPath(
            roundedRect: bounds, cornerWidth: bounds.height / 2, cornerHeight: bounds.height / 2, transform: nil)
        appearance.performAsCurrentDrawingAppearance {
            context.saveGState()
            context.addPath(shape)
            context.clip()
            if let backdrop, !reduceTransparency {
                // The whole backdrop laid over the screen, offset so this piece shows its own part.
                context.interpolationQuality = .medium
                context.draw(
                    backdrop,
                    in: CGRect(
                        x: screen.minX - frame.minX, y: screen.minY - frame.minY, width: screen.width,
                        height: screen.height))
            }
            let tint = reduceTransparency || backdrop == nil ? 1 : increaseContrast ? 0.9 : 0.72
            context.setFillColor(NSColor.windowBackgroundColor.withAlphaComponent(tint).cgColor)
            context.fill(bounds)
            context.restoreGState()

            // A hairline just inside the edge, one device pixel, so the capsule holds its shape on any
            // picture; stronger with Increase Contrast.
            let hairline = 1 / max(contentsScale, 1)
            context.addPath(
                CGPath(
                    roundedRect: bounds.insetBy(dx: hairline / 2, dy: hairline / 2),
                    cornerWidth: (bounds.height - hairline) / 2, cornerHeight: (bounds.height - hairline) / 2,
                    transform: nil))
            context.setStrokeColor(
                (increaseContrast ? NSColor.labelColor.withAlphaComponent(0.5) : NSColor.separatorColor).cgColor)
            context.setLineWidth(hairline)
            context.strokePath()

            let line = currentLine()
            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            let width = CTLineGetTypographicBounds(line, &ascent, &descent, nil)
            context.textPosition = CGPoint(
                x: ((bounds.width - width) / 2).rounded(), y: ((bounds.height - ascent + descent) / 2).rounded())
            CTLineDraw(line, context)
        }
    }

    private func currentLine() -> CTLine {
        if let line { return line }
        var made: CTLine!
        appearance.performAsCurrentDrawingAppearance {
            let text = NSMutableAttributedString()
            for (string, style) in runs {
                let font: NSFont =
                    style == .primary
                    ? .monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize + 1, weight: .semibold)
                    : .monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize + 1, weight: .regular)
                let color: NSColor = style == .primary ? .labelColor : .secondaryLabelColor
                text.append(
                    NSAttributedString(
                        string: string,
                        attributes: [
                            .font: font,
                            NSAttributedString.Key(kCTForegroundColorAttributeName as String): color.cgColor,
                        ]))
            }
            made = CTLineCreateWithAttributedString(text)
        }
        line = made
        return made
    }
}
