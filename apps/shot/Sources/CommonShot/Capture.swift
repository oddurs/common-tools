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
    /// The camera housing at the top of a notched display, in the display's points from its bottom-left.
    var notch: CGRect?

    /// Pixels per point, which can be fractional on a scaled display.
    var scale: CGFloat { CGFloat(image.width) / frame.width }
}

/// Every display frozen, and the windows on them, front to back.
struct Freeze {
    let stills: [Still]
    let windows: [WindowFrame]
    /// ScreenCaptureKit's view of the same moment, so a window can be captured without asking again.
    var content: SCShareableContent?
}

enum CaptureError: LocalizedError {
    case noDisplays

    var errorDescription: String? {
        switch self {
        case .noDisplays: "None of the displays could be captured."
        }
    }
}

/// Screen pixels through ScreenCaptureKit, the public API that replaced CGDisplayCreateImage. It needs
/// Screen Recording access, which no screenshot tool can do without.
@MainActor
enum Capture {
    static var hasAccess: Bool { CGPreflightScreenCaptureAccess() }

    /// The first request in a process costs several times a later one (about 35 ms against 5 for the
    /// shareable content on an M-series Mac), so it's made at launch rather than on the first shortcut.
    static func warmUp() async throws {
        guard hasAccess else { return }
        _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    }

    /// Captures every display before the overlay covers them, all at once, so the selection is drawn over
    /// a still picture and what's copied is exactly what was on screen when the shortcut was pressed.
    static func freeze() async throws -> Freeze {
        let windows = onScreenWindows()
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        // This app's own windows, such as the last shot's preview, stay out of the next one.
        let ownApp = content.applications.filter { $0.processID == getpid() }
        let targets = NSScreen.screens.compactMap { screen -> (NSScreen, SCDisplay)? in
            guard let id = screen.displayID, let display = content.displays.first(where: { $0.displayID == id })
            else { return nil }
            return (screen, display)
        }
        let captures = targets.map { _, display in
            let filter = SCContentFilter(display: display, excludingApplications: ownApp, exceptingWindows: [])
            return Shot(filter: filter, configuration: configuration(for: filter))
        }
        let images = try await withThrowingTaskGroup(of: (Int, CGImage).self) { group in
            for (index, capture) in captures.enumerated() {
                group.addTask { (index, try await capture.take()) }
            }
            var images: [Int: CGImage] = [:]
            for try await (index, image) in group { images[index] = image }
            return images
        }
        let stills = targets.enumerated().compactMap { index, target -> Still? in
            let (screen, display) = target
            guard let image = images[index] else { return nil }
            return Still(
                frame: screen.frame, displayBounds: CGDisplayBounds(display.displayID), image: image, screen: screen,
                notch: screen.notch)
        }
        guard !stills.isEmpty else { throw CaptureError.noDisplays }
        return Freeze(stills: stills, windows: windows, content: content)
    }

    /// One window on its own, without what overlaps it or its shadow. Nil when it's no longer there.
    static func image(ofWindow id: UInt32, in content: SCShareableContent?) async throws -> CGImage? {
        let content =
            if let content { content } else {
                try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            }
        guard let window = content.windows.first(where: { $0.windowID == id }) else { return nil }
        let filter = SCContentFilter(desktopIndependentWindow: window)
        return try await Shot(filter: filter, configuration: configuration(for: filter)).take()
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

/// One capture's filter and configuration, made on the main actor and handed whole to a task, which is
/// all ScreenCaptureKit's objects need to cross; nothing else touches them.
private struct Shot: @unchecked Sendable {
    let filter: SCContentFilter
    let configuration: SCStreamConfiguration

    func take() async throws -> CGImage {
        try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
    }
}

extension NSScreen {
    /// Between the two areas beside the camera housing, as tall as the safe area's top inset.
    var notch: CGRect? {
        guard safeAreaInsets.top > 0, let left = auxiliaryTopLeftArea, let right = auxiliaryTopRightArea
        else { return nil }
        let height = safeAreaInsets.top
        return CGRect(
            x: left.width, y: frame.height - height, width: frame.width - left.width - right.width, height: height)
    }

    var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}
