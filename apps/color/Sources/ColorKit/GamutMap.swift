import Foundation

extension ColorValue {
    /// The nearest colour `space` can show, by CSS Color 4's gamut mapping (binary search
    /// with local MINDE): hold OKLCH lightness and hue, reduce chroma until clipping the result
    /// moves it less than a just-noticeable difference. A plain clip shifts hue (a P3 orange clips
    /// to a yellower sRGB one); this keeps it. A colour already in `space` comes back as it is.
    ///
    /// Gamma-encoded components in `space`, each in 0...1.
    public func mapped(into space: RGBSpace) -> SIMD3<Double> {
        if isInGamut(space) { return Self.clip(components(in: space)) }
        let origin = oklch
        if origin.l >= 1 { return SIMD3(1, 1, 1) }
        if origin.l <= 0 { return SIMD3(0, 0, 0) }

        func clipped(_ lch: OKLab.LCH) -> (SIMD3<Double>, Double) {
            let candidate = ColorValue(OKLab(lch))
            let clip = Self.clip(candidate.components(in: space))
            let distance = ColorValue(space, red: clip.x, green: clip.y, blue: clip.z).oklab
                .distance(to: candidate.oklab)
            return (clip, distance)
        }

        let jnd = 0.02
        let epsilon = 0.0001
        var current = origin
        var (clip, error) = clipped(current)
        if error < jnd { return clip }
        var low = 0.0
        var high = origin.c
        var lowInGamut = true
        while high - low > epsilon {
            current.c = (low + high) / 2
            if lowInGamut, ColorValue(OKLab(current)).isStrictlyInGamut(space) {
                low = current.c
                continue
            }
            (clip, error) = clipped(current)
            if error < jnd {
                if jnd - error < epsilon { return clip }
                lowInGamut = false
                low = current.c
            } else {
                high = current.c
            }
        }
        return clip
    }

    private func isStrictlyInGamut(_ space: RGBSpace) -> Bool {
        let c = components(in: space)
        return c.min() >= 0 && c.max() <= 1
    }

    static func clip(_ c: SIMD3<Double>) -> SIMD3<Double> {
        c.map { min(max($0, 0), 1) }
    }
}
