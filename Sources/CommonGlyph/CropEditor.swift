import GlyphKit
import SwiftUI

/// The source image with a crop box over it. Drag inside the box to move it, drag a corner to resize
/// it, and double-click it to take in the whole image again.
struct CropEditor: View {
    let image: NSImage
    @Binding var crop: CropRect
    @State private var dragStart: CropRect?

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
                .fill(.black.opacity(0.5), style: FillStyle(eoFill: true))
                .allowsHitTesting(false)
                Rectangle()
                    .strokeBorder(.white, lineWidth: 1.5)
                    .shadow(color: .black.opacity(0.4), radius: 1)
                    .contentShape(Rectangle())
                    .frame(width: box.width, height: box.height)
                    .offset(x: box.minX, y: box.minY)
                    .onTapGesture(count: 2) { crop = .full }
                    .gesture(drag(in: frame) { start, dx, dy in start.moved(dx: dx, dy: dy) })
                    .onHover { inside in inside ? NSCursor.openHand.push() : NSCursor.pop() }
                ForEach(CropRect.Corner.allCases, id: \.self) { corner in
                    let point = Self.point(of: corner, in: box)
                    Circle()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.4), radius: 1.5)
                        .frame(width: 12, height: 12)
                        .contentShape(Rectangle().inset(by: -6))
                        .offset(x: point.x - 6, y: point.y - 6)
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

/// Shows where an image is transparent, the way image editors do.
struct Checkerboard: View {
    var body: some View {
        Canvas { context, size in
            let side: CGFloat = 8
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(white: 0.92)))
            for row in 0..<Int((size.height / side).rounded(.up)) {
                for column in 0..<Int((size.width / side).rounded(.up)) where (row + column).isMultiple(of: 2) {
                    let square = CGRect(x: CGFloat(column) * side, y: CGFloat(row) * side, width: side, height: side)
                    context.fill(Path(square), with: .color(Color(white: 0.78)))
                }
            }
        }
    }
}
