import AppKit
import BatteryKit
import SwiftUI

/// `CommonBattery --snapshot out.png` writes every bar style in every battery state at 2x on light
/// and dark menu bars to `out.png`, and the menu panel in light and dark to `out-menu.png`: this
/// Mac's battery as it is now, then a made-up afternoon with a charge in it. Used for README images
/// and for design review without screen-recording permission.
@MainActor
enum SnapshotCommand {
    static let states: [BatteryReading] = [
        BatteryReading(level: 0.72, state: .discharging, minutesRemaining: 161),
        BatteryReading(level: 0.45, state: .charging, minutesRemaining: 52),
        BatteryReading(level: 1, state: .charged),
        BatteryReading(level: 0.80, state: .notCharging),
        BatteryReading(level: 0.12, state: .discharging, minutesRemaining: 18),
        BatteryReading(level: 0.55, state: .discharging, minutesRemaining: 240, isLowPowerMode: true),
        BatteryReading(level: 0.03, state: .discharging, minutesRemaining: 4),
    ]

    static func run(path: String) {
        writeBar(to: path)
        writeMenu(to: (path as NSString).deletingPathExtension + "-menu.png")
    }

    private static func writeMenu(to path: String) {
        let now = Date()
        var afternoon = ChargeHistory()
        // Down from 90% over six hours, an hour and a half on the charger, then down again; an
        // hour of sleep in the middle shows as a gap.
        for minute in stride(from: 0, through: 12 * 60, by: 2) where !(300..<360).contains(minute) {
            let level: Double =
                minute < 420
                ? 0.9 - Double(minute) / 420 * 0.7
                : minute < 510
                    ? 0.2 + Double(minute - 420) / 90 * 0.6
                    : 0.8 - Double(minute - 510) / 210 * 0.25
            let charging = (420..<510).contains(minute)
            afternoon.record(
                BatteryReading(level: level, state: charging ? .charging : .discharging),
                at: now.addingTimeInterval(Double(minute - 12 * 60) * 60))
        }
        let example = BatteryReading(
            level: 0.55, state: .discharging, minutesRemaining: 161, adapterWatts: nil, cycleCount: 156,
            designCycleCount: 1000, fullChargeCapacity: 7872, designCapacity: 8579, temperature: 29.7, watts: -11.4)

        let live = BatterySampler().sample()
        var liveHistory = ChargeHistory()
        if let live { liveHistory.record(live, at: now) }

        func menu(_ scheme: ColorScheme) -> some View {
            VStack(alignment: .leading, spacing: 12) {
                PanelView(reading: live, history: liveHistory, now: now)
                PanelView(reading: example, history: afternoon, now: now)
                PanelView(reading: nil, history: ChargeHistory(), now: now)
            }
            .padding(.vertical, 6)
            .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
            .environment(\.colorScheme, scheme)
        }
        let renderer = ImageRenderer(
            content: HStack(alignment: .top, spacing: 24) {
                menu(.light)
                menu(.dark)
            }
            .padding(24))
        renderer.scale = 2
        guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
            let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
        else { fatalError("could not render menu") }
        write(png, to: path)
    }

    private static func writeBar(to path: String) {
        let appearances =
            BarStyle.allCases.map { BarAppearance(style: $0, showsTime: false, colorsAlerts: true) } + [
                BarAppearance(style: .iconAndPercent, showsTime: true, colorsAlerts: true)
            ]
        let height: CGFloat = 24
        let renderers = appearances.map { BarRenderer(appearance: $0, height: height) }
        let column = (renderers.map(\.size.width).max() ?? 0) + 16
        let row = height + 4
        let size = CGSize(
            width: column * CGFloat(states.count) + 16, height: row * CGFloat(renderers.count) * 2 + 8)
        let scale: CGFloat = 2

        guard
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
        else { fatalError("could not allocate bitmap") }
        rep.size = size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        for (dark, origin) in [(false, size.height / 2), (true, 0.0)] {
            let band = CGRect(x: 0, y: origin, width: size.width, height: size.height / 2)
            (dark ? NSColor(white: 0.16, alpha: 1) : NSColor(white: 0.93, alpha: 1)).setFill()
            band.fill()
            for (r, renderer) in renderers.enumerated() {
                for (c, reading) in states.enumerated() {
                    let image = renderer.image(reading)
                    let y = band.maxY - row * CGFloat(r + 1) - 2
                    let rect = CGRect(
                        x: 8 + column * CGFloat(c) + column - 8 - image.size.width, y: y, width: image.size.width,
                        height: image.size.height)
                    NSAppearance(named: dark ? .darkAqua : .aqua)?.performAsCurrentDrawingAppearance {
                        (image.isTemplate ? tint(image, dark ? .white : .black) : image).draw(in: rect)
                    }
                }
            }
        }
        NSGraphicsContext.restoreGraphicsState()
        guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("could not encode PNG") }
        write(png, to: path)
    }

    private static func write(_ png: Data, to path: String) {
        do {
            try png.write(to: URL(fileURLWithPath: path))
        } catch {
            FileHandle.standardError.write(Data("common-battery: \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }

    /// What AppKit does to a template image in the menu bar, minus vibrancy.
    private static func tint(_ image: NSImage, _ color: NSColor) -> NSImage {
        NSImage(size: image.size, flipped: false) { rect in
            image.draw(in: rect)
            color.set()
            rect.fill(using: .sourceAtop)
            return true
        }
    }
}
