import AppKit
import ScreenCaptureKit
import ShotKit

/// One display as it looked the moment the shortcut was pressed.
struct Still {
    /// Where the display sits in AppKit's global coordinates: points up from the main display's bottom-left.
    let frame: CGRect
    /// Where the display sits in global display coordinates, down from the main display's top-left corner.
    let displayBounds: CGRect
    let image: CGImage
    /// The screen it was captured from; nil for a made-up one rendered offscreen.
    let screen: NSScreen?

    /// Pixels per point, which can be fractional on a scaled display.
    var scale: CGFloat { CGFloat(image.width) / frame.width }
}

/// Every display frozen, and the windows on them, front to back.
struct Freeze {
    let stills: [Still]
    let windows: [WindowFrame]
}

enum CaptureError: LocalizedError {
    case noDisplays
    case windowGone

    var errorDescription: String? {
        switch self {
        case .noDisplays: "None of the displays could be captured."
        case .windowGone: "That window closed before it could be captured."
        }
    }
}

/// Screen pixels through ScreenCaptureKit, the public API that replaced CGDisplayCreateImage. It needs
/// Screen Recording access, which no screenshot tool can do without.
@MainActor
enum Capture {
    static var hasAccess: Bool { CGPreflightScreenCaptureAccess() }

    /// Captures every display before the overlay covers them, so the selection is drawn over a still
    /// picture and what's copied is exactly what was on screen when the shortcut was pressed.
    static func freeze() async throws -> Freeze {
        let windows = onScreenWindows()
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        // This app's own windows, such as the last shot's preview, stay out of the next one.
        let ownApp = content.applications.filter { $0.processID == getpid() }
        var stills: [Still] = []
        for screen in NSScreen.screens {
            guard let id = screen.displayID, let display = content.displays.first(where: { $0.displayID == id })
            else { continue }
            let filter = SCContentFilter(display: display, excludingApplications: ownApp, exceptingWindows: [])
            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter, configuration: configuration(for: filter))
            stills.append(
                Still(frame: screen.frame, displayBounds: CGDisplayBounds(id), image: image, screen: screen))
        }
        guard !stills.isEmpty else { throw CaptureError.noDisplays }
        return Freeze(stills: stills, windows: windows)
    }

    /// One window on its own, without what overlaps it or its shadow.
    static func image(ofWindow id: UInt32) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
        guard let window = content.windows.first(where: { $0.windowID == id }) else { throw CaptureError.windowGone }
        let filter = SCContentFilter(desktopIndependentWindow: window)
        return try await SCScreenshotManager.captureImage(
            contentFilter: filter, configuration: configuration(for: filter))
    }

    /// At the display's full backing resolution, without the pointer.
    private static func configuration(for filter: SCContentFilter) -> SCStreamConfiguration {
        let configuration = SCStreamConfiguration()
        let scale = CGFloat(filter.pointPixelScale)
        configuration.width = Int((filter.contentRect.width * scale).rounded())
        configuration.height = Int((filter.contentRect.height * scale).rounded())
        configuration.showsCursor = false
        configuration.captureResolution = .best
        return configuration
    }

    /// The window server's list rather than ScreenCaptureKit's, because only this one promises front-to-back
    /// order, which is how a click picks the window on top. Ordinary app windows only: layer 0 leaves out
    /// the menu bar, the Dock, and overlays.
    private static func onScreenWindows() -> [WindowFrame] {
        let list =
            CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
            as? [[String: Any]] ?? []
        return list.compactMap { info in
            guard info[kCGWindowLayer as String] as? Int == 0,
                info[kCGWindowOwnerPID as String] as? pid_t != getpid(),
                (info[kCGWindowAlpha as String] as? Double ?? 1) > 0,
                let id = info[kCGWindowNumber as String] as? UInt32,
                let bounds = info[kCGWindowBounds as String] as? NSDictionary,
                let frame = CGRect(dictionaryRepresentation: bounds),
                frame.width > 1, frame.height > 1
            else { return nil }
            return WindowFrame(id: id, frame: frame)
        }
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}
