extension Bitmap {
    /// Clears the backdrop of clip art, stickers, and scanned drawings: the colour most of the corners
    /// share, flooded inwards from the edges. Filling from the edges rather than matching the colour
    /// everywhere keeps enclosed areas of the same colour, such as the whites of a character's eyes.
    ///
    /// `tolerance` is how far, from 0 to 1, a colour may stray from the backdrop and still count as it.
    /// Pixels just past that, on the edge of the cleared area, fade out in proportion, so anti-aliased
    /// outlines don't keep a fringe of the old background.
    public func removingBackground(tolerance: Double) -> Bitmap {
        let tolerance = min(max(tolerance, 0), 1)
        let backdrop = cornerColor
        var cleared = [Bool](repeating: false, count: width * height)
        var stack: [Int] = []
        func visit(_ x: Int, _ y: Int) {
            let i = y * width + x
            guard !cleared[i], self[x, y].distance(to: backdrop) <= tolerance else { return }
            cleared[i] = true
            stack.append(i)
        }
        for x in 0..<width {
            visit(x, 0)
            visit(x, height - 1)
        }
        for y in 0..<height {
            visit(0, y)
            visit(width - 1, y)
        }
        while let i = stack.popLast() {
            let x = i % width, y = i / width
            if x > 0 { visit(x - 1, y) }
            if x < width - 1 { visit(x + 1, y) }
            if y > 0 { visit(x, y - 1) }
            if y < height - 1 { visit(x, y + 1) }
        }

        var out = self
        // Edge pixels within twice the tolerance are part backdrop, part subject.
        let soft = max(tolerance, 1.0 / 255)
        for y in 0..<height {
            for x in 0..<width {
                let i = y * width + x
                if cleared[i] {
                    out[x, y] = .clear
                    continue
                }
                let touches =
                    (x > 0 && cleared[i - 1]) || (x < width - 1 && cleared[i + 1])
                    || (y > 0 && cleared[i - width]) || (y < height - 1 && cleared[i + width])
                guard touches else { continue }
                let d = self[x, y].distance(to: backdrop)
                guard d < tolerance + soft else { continue }
                var p = self[x, y]
                p.a = UInt8(Double(p.a) * (d - tolerance) / soft)
                out[x, y] = p
            }
        }
        return out
    }

    /// The colour shared by the most corners; the top-left one on a tie.
    var cornerColor: Pixel {
        let corners = [self[0, 0], self[width - 1, 0], self[0, height - 1], self[width - 1, height - 1]]
        return corners.max { a, b in
            corners.filter { $0.distance(to: a) < 0.05 }.count < corners.filter { $0.distance(to: b) < 0.05 }.count
        } ?? corners[0]
    }
}
