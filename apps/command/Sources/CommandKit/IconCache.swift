import AppKit

/// App and System Settings icons drawn ahead of time, off the main thread, at the size a row shows them.
/// The first time an app's icon is drawn, Icon Services renders it, which takes 7 to 20 ms per app on an
/// M-series Mac. Done on the main thread as rows appear, that stalls the first keystrokes after launch by
/// a frame per new icon; done here once per app, a row only draws a small bitmap.
public final class IconCache: @unchecked Sendable {
    public static let shared = IconCache()

    /// The largest row icon at 2x. Smaller sizes and 1x screens scale it down.
    public static let pixels = Int(PanelSize.allCases.map(\.iconSize).max()! * 2)

    private let lock = NSLock()
    private var images: [String: CGImage] = [:]

    public init() {}

    public func image(forPath path: String) -> CGImage? {
        lock.withLock { images[path] }
    }

    /// Icons have light and dark variants, drawn here for the appearance at the time.
    public func removeAll() {
        lock.withLock { images = [:] }
    }

    /// Renders the icons not yet cached. Blocks for about 15 ms per new icon, mostly waiting on Icon
    /// Services, so call it from a background task.
    public func prerender(_ paths: some Sequence<String>, pixels: Int = pixels) {
        for path in paths where image(forPath: path) == nil {
            guard let image = Self.render(path, pixels: pixels) else { continue }
            lock.withLock { images[path] = image }
        }
    }

    /// The icon of what a symlink or alias points to: read for the link itself, it wears Finder's alias arrow.
    public static func icon(forFile path: String) -> NSImage {
        NSWorkspace.shared.icon(forFile: URL(filePath: path).resolvingLinks.path)
    }

    static func render(_ path: String, pixels: Int) -> CGImage? {
        guard
            let context = CGContext(
                data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        let icon = icon(forFile: path)
        // The graphics context is per thread, so this doesn't disturb drawing elsewhere.
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        icon.draw(in: CGRect(x: 0, y: 0, width: pixels, height: pixels))
        NSGraphicsContext.restoreGraphicsState()
        return context.makeImage()
    }
}
