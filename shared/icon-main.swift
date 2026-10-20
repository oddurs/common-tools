func render(_ px: Int, _ glyph: (CGContext) -> Void) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let g = NSGraphicsContext(bitmapImageRep: rep)!
    let ctx = g.cgContext
    ctx.scaleBy(x: CGFloat(px) / 1024, y: CGFloat(px) / 1024)
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = g
    background(ctx)
    glyph(ctx)
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

// Arguments: the app's directory, the shared family icons directory, the app's brand colours as
// build.mjs --brand prints them, and where the site keeps the app's icon.
let app = URL(fileURLWithPath: CommandLine.arguments[1])
let family = URL(fileURLWithPath: CommandLine.arguments[2])
let site = URL(fileURLWithPath: CommandLine.arguments[4])
let brand = try JSONSerialization.jsonObject(with: Data(CommandLine.arguments[3].utf8)) as! [String: Any]
func hex(_ value: Any?) -> CGColor { rgb(UInt32((value as! String).dropFirst(), radix: 16)!) }
(brandTop, brandMid, brandDeep) = (hex(brand["top"]), hex(brand["mid"]), hex(brand["deep"]))
brandSpectrum = (brand["spectrum"] as? [String])?.map(hex) ?? []
let slug = app.lastPathComponent
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
if FileManager.default.fileExists(atPath: iconset.path) { try FileManager.default.removeItem(at: iconset) }
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    try render(size, glyph).write(to: iconset.appendingPathComponent("icon_\(size)x\(size).png"))
    try render(size * 2, glyph).write(to: iconset.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
try render(256, glyph).write(to: app.appendingPathComponent("docs/icon.png"))
// The site's copy, sharp at the size its pages show it on a Retina screen.
try render(512, glyph).write(to: site)
// The family icon every app's Settings shows.
try render(128, glyph).write(to: family.appendingPathComponent("\(slug).png"))
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", app.appendingPathComponent("Resources/AppIcon.icns").path]
try iconutil.run()
iconutil.waitUntilExit()
exit(iconutil.terminationStatus)
