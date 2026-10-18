import AppKit

/// The Common Tools family, in the order the apps were made. Every app's Settings ends with the
/// same list, and every app bundle carries every app's icon (shared/CommonTools, copied in by the
/// build), so a tool that isn't installed still shows its own.
public struct CommonTool: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let summary: String
    public let bundleIdentifier: String

    public static let all = [
        CommonTool(
            id: "stats", name: "Common Stats", summary: "System stats in the menu bar",
            bundleIdentifier: "com.oddurs.commonstats"),
        CommonTool(
            id: "keys", name: "Common Keys", summary: "Fixes words typed on the wrong keyboard",
            bundleIdentifier: "com.oddurs.commonkeys"),
        CommonTool(
            id: "bar", name: "Common Bar", summary: "Hides the menu bar icons you rarely use",
            bundleIdentifier: "com.oddurs.reasonal"),
        CommonTool(
            id: "glyph", name: "Common Glyph", summary: "Your own image in the menu bar",
            bundleIdentifier: "com.oddurs.commonglyph"),
        CommonTool(
            id: "command", name: "Common Command", summary: "Opens apps, files, and settings from the keyboard",
            bundleIdentifier: "com.oddurs.commoncommand"),
        CommonTool(
            id: "shot", name: "Common Shot", summary: "Screenshots straight to the clipboard",
            bundleIdentifier: "com.oddurs.commonshot"),
        CommonTool(
            id: "battery", name: "Common Battery", summary: "The battery in the menu bar, with alerts",
            bundleIdentifier: "com.oddurs.commonbattery"),
        CommonTool(
            id: "color", name: "Common Color", summary: "Pick a color anywhere, paste it as code",
            bundleIdentifier: "com.oddurs.commoncolor"),
    ]

    public static let website = URL(string: "https://oddurs.github.io/common-tools/")!

    /// The tool's page on the site, which has its download or says it's on the way.
    public var page: URL { Self.website.appending(path: "\(id)/") }

    public var icon: NSImage? {
        Bundle.main.url(forResource: id, withExtension: "png", subdirectory: "CommonTools")
            .flatMap(NSImage.init(contentsOf:))
    }

    public var isThisApp: Bool { Bundle.main.bundleIdentifier == bundleIdentifier }

    public var installedURL: URL? { NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) }
}
