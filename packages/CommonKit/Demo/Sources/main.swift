import AppKit
import CommonKit
import SwiftUI

// Shows the Welcome window as Common Keys would, or renders it to a PNG with --screenshot <path>.
// --permission renders the window a later app shows when Screen Recording is missing, as Common Shot would.
// Open at login can't register from a bare executable, so flipping it shows the error the window
// gives; everything else behaves as in an app.

let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent()

// The family icons sit beside the executable, where CommonTool.icon looks in a real bundle.
let icons = Bundle.main.bundleURL.appending(path: "CommonTools")
if !FileManager.default.fileExists(atPath: icons.path) {
    try FileManager.default.copyItem(at: root.appending(path: "shared/CommonTools"), to: icons)
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
app.applicationIconImage = NSImage(contentsOf: root.appending(path: "shared/CommonTools/keys.png"))

let arguments = CommandLine.arguments
let kind: WelcomeKind = arguments.contains("--permission") ? .permission : .full
let info =
    kind == .full
    ? WelcomeInfo(
        name: "Common Keys",
        line: "Fixes words typed on the wrong keyboard layout, for every keyboard macOS has.",
        permission: .accessibility(reason: "to see what you type and fix it"))
    : WelcomeInfo(
        name: "Common Shot",
        line: "Screenshots straight to the clipboard: press ⇧⌘2, drag, paste.",
        permission: .screenRecording(reason: "to capture what is on your screen"))
if let flag = arguments.firstIndex(of: "--screenshot"), arguments.count > flag + 1 {
    let out = URL(fileURLWithPath: arguments[flag + 1])
    let renderer = ImageRenderer(content: WelcomeView(info: info, kind: kind) {}.background(Color(nsColor: .windowBackgroundColor)))
    renderer.scale = 2
    guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
        let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
    else { exit(1) }
    try png.write(to: out)
    print("wrote \(out.path) (\(Int(image.size.width))×\(Int(image.size.height)) points)")
    exit(0)
}

Welcome.show(info)
app.run()
