import CommonUI
import GlyphKit
import SwiftUI

/// The source image with a crop box over it. Drag inside the box to move it, drag a corner to resize
/// it, and double-click it to take in the whole image again.
struct CropEditor: View {
    let image: NSImage
    @Binding var crop: CropRect
    @State private var dragStart: CropRect?

    private static let handle: CGFloat = 12

    var body: some View {
        GeometryReader { geometry in
            let frame = Self.fitted(image.size, in: geometry.size)
            let box = CGRect(
                x: frame.minX + crop.x * frame.width, y: frame.minY + crop.y * frame.height,
                width: crop.width * frame.width, height: crop.height * frame.height)
            ZStack(alignment: .topLeading) {
                Checkerboard()
                    .frame(width: frame.width, height: frame.height)
                    .offset(x: frame.minX, y: frame.minY)
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: frame.width, height: frame.height)
                    .offset(x: frame.minX, y: frame.minY)
                Path { path in
                    path.addRect(frame)
                    path.addRect(box)
                }
                .fill(Tokens.Surface.overlay.color, style: FillStyle(eoFill: true))
                .allowsHitTesting(false)
                // The box and its handles float over whatever the image holds, so each is drawn in the
                // over-media ink with the overlay colour as its edge, legible on white and on black alike.
                Rectangle()
                    .strokeBorder(Tokens.Surface.overlay.color, lineWidth: 2.5)
                    .overlay(Rectangle().strokeBorder(Tokens.Text.inverse.color, lineWidth: 1.5).padding(0.5))
                    .contentShape(Rectangle())
                    .frame(width: box.width, height: box.height)
                    .offset(x: box.minX, y: box.minY)
                    .onTapGesture(count: 2) { crop = .full }
                    .gesture(drag(in: frame) { start, dx, dy in start.moved(dx: dx, dy: dy) })
                    .onHover { inside in inside ? NSCursor.openHand.push() : NSCursor.pop() }
                ForEach(CropRect.Corner.allCases, id: \.self) { corner in
                    let point = Self.point(of: corner, in: box)
                    Circle()
                        .fill(Tokens.Text.inverse.color)
                        .overlay(Circle().strokeBorder(Tokens.Surface.overlay.color, lineWidth: 1))
                        .frame(width: Self.handle, height: Self.handle)
                        .contentShape(Rectangle().inset(by: -Self.handle / 2))
                        .offset(x: point.x - Self.handle / 2, y: point.y - Self.handle / 2)
                        .gesture(drag(in: frame) { start, dx, dy in start.resized(corner, dx: dx, dy: dy) })
                        .onHover { inside in inside ? NSCursor.crosshair.push() : NSCursor.pop() }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
        .accessibilityElement()
        .accessibilityLabel("Crop")
        .accessibilityValue(crop.isFull ? "Whole image" : "Cropped")
    }

    /// Translations arrive in points; the crop is in fractions of the image, so divide by its shown size.
    private func drag(in frame: CGRect, _ change: @escaping (CropRect, Double, Double) -> CropRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let start = dragStart ?? crop
                dragStart = start
                crop = change(start, value.translation.width / frame.width, value.translation.height / frame.height)
            }
            .onEnded { _ in dragStart = nil }
    }

    private static func fitted(_ size: CGSize, in space: CGSize) -> CGRect {
        let scale = min(space.width / max(size.width, 1), space.height / max(size.height, 1))
        let w = size.width * scale, h = size.height * scale
        return CGRect(x: (space.width - w) / 2, y: (space.height - h) / 2, width: w, height: h)
    }

    private static func point(of corner: CropRect.Corner, in box: CGRect) -> CGPoint {
        switch corner {
        case .topLeading: CGPoint(x: box.minX, y: box.minY)
        case .topTrailing: CGPoint(x: box.maxX, y: box.minY)
        case .bottomLeading: CGPoint(x: box.minX, y: box.maxY)
        case .bottomTrailing: CGPoint(x: box.maxX, y: box.maxY)
        }
    }
}

/// Shows where an image is transparent, the way image editors do: the media surface, with every other
/// square tinted a step darker.
struct Checkerboard: View {
    var body: some View {
        Canvas { context, size in
            let side = Tokens.Space.xs
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Tokens.Surface.media.color))
            for row in 0..<Int((size.height / side).rounded(.up)) {
                for column in 0..<Int((size.width / side).rounded(.up)) where (row + column).isMultiple(of: 2) {
                    let square = CGRect(x: CGFloat(column) * side, y: CGFloat(row) * side, width: side, height: side)
                    context.fill(Path(square), with: .style(.quaternary))
                }
            }
        }
    }
}
