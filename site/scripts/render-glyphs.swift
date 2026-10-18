// Renders the SF Symbols and the arrow cursor the demo scenes draw, so the menu bar in the videos
// uses the same glyphs as the real one. Run on a Mac: pnpm glyphs (pnpm film glyphs)
//
// Each symbol is written black on transparent at 4x; scenes use it as a CSS mask, so one file
// serves light and dark menu bars. static/symbols/symbols.json records each one's size in points.
import AppKit

let symbols: [String: (CGFloat, NSFont.Weight)] = [
    // The system's own menu bar extras.
    "apple.logo": (15, .regular), "wifi": (14, .medium), "battery.100percent": (15, .regular),
    "magnifyingglass": (13.5, .medium), "switch.2": (13.5, .medium),
    // Stand-ins for other apps' menu bar icons.
    "drop.fill": (14, .regular), "lock.fill": (14, .regular), "video.fill": (13, .regular),
    "music.note": (14, .regular), "message.fill": (14, .regular), "icloud.fill": (14, .regular),
    "shippingbox.fill": (14, .regular), "bolt.fill": (14, .regular), "eye": (13, .regular),
    "paperclip": (14, .regular), "cup.and.saucer.fill": (13, .regular), "headphones": (14, .regular),
    "calendar": (14, .regular), "keyboard": (13, .regular),
    "gauge.with.dots.needle.33percent": (14, .regular), "globe": (14, .regular), "timer": (14, .regular),
    // Common Bar's More folder.
    "ellipsis.circle": (15, .regular),
    // Common Stats' card icons.
    "cpu": (13, .medium), "memorychip": (13, .medium), "network": (13, .medium),
    "arrow.up.arrow.down": (12, .semibold), "square.stack.3d.up": (13, .medium),
    "internaldrive": (12, .medium), "battery.75percent": (12, .medium),
    // Key caps.
    "command": (22, .regular), "option": (22, .regular),
]

let scale: CGFloat = 4
let out = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("static/symbols")

func png(_ image: NSImage, size: NSSize) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int((size.width * scale).rounded(.up)),
        pixelsHigh: Int((size.height * scale).rounded(.up)), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(origin: .zero, size: size))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

var manifest: [String: [String: Double]] = [:]
for (name, (points, weight)) in symbols.sorted(by: { $0.key < $1.key }) {
    guard
        let base = NSImage(systemSymbolName: name, accessibilityDescription: nil),
        let image = base.withSymbolConfiguration(.init(pointSize: points, weight: weight))
    else { fatalError("no symbol \(name)") }
    try png(image, size: image.size).write(to: out.appendingPathComponent("\(name).png"))
    manifest[name] = ["width": image.size.width, "height": image.size.height]
}

// The arrow cursor, with its hot spot. Cursors load only once an application exists.
_ = NSApplication.shared
let arrow = NSCursor.arrow
let cursorSize = arrow.image.size
try png(arrow.image, size: cursorSize).write(to: out.appendingPathComponent("cursor.png"))
manifest["cursor"] = [
    "width": cursorSize.width, "height": cursorSize.height, "x": arrow.hotSpot.x, "y": arrow.hotSpot.y,
]

let json = try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
try json.write(to: out.appendingPathComponent("symbols.json"))
print("wrote \(manifest.count) images to \(out.path)")
