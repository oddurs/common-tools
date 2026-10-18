import AppKit

extension ColorValue {
    /// Any colour AppKit can express as RGB, whatever space it is in (the colour sampler gives the
    /// display's own). Nil for a pattern or a catalogue colour with no RGB form.
    ///
    /// ColorSync converts out of the display's space. Extended sRGB clips nothing, so it decides
    /// where the colour lies; inside Display P3, which covers every Apple display, the colour is
    /// taken from ColorSync's Display P3 components instead. ColorSync's profiles are quantised and
    /// differ from the exact matrices by up to 0.0004, so going through sRGB would turn a P3
    /// `0 1 0` into `0 1 0.0003`.
    public init?(_ color: NSColor) {
        guard let extended = color.usingColorSpace(.extendedSRGB) else { return nil }
        let wide = ColorValue(
            .sRGB, red: Double(extended.redComponent), green: Double(extended.greenComponent),
            blue: Double(extended.blueComponent))
        guard wide.isInGamut(.displayP3), let p3 = color.usingColorSpace(.displayP3) else {
            self = wide
            return
        }
        self.init(
            .displayP3, red: Double(p3.redComponent), green: Double(p3.greenComponent), blue: Double(p3.blueComponent))
    }

    /// The colour to draw a swatch with: extended sRGB, so a colour outside sRGB is drawn as
    /// itself on a display that can show it.
    public var cgColor: CGColor {
        let c = components(in: .sRGB)
        return CGColor(colorSpace: Self.extendedSRGB, components: [c.x, c.y, c.z, 1].map { CGFloat($0) })
            ?? CGColor(gray: 0, alpha: 1)
    }

    private static let extendedSRGB = CGColorSpace(name: CGColorSpace.extendedSRGB)!
}
