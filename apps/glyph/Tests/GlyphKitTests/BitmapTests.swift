import Testing

@testable import GlyphKit

/// A bitmap whose every pixel is distinct, so geometry tests can see where each one went.
func numbered(width: Int, height: Int) -> Bitmap {
    Bitmap.make(width: width, height: height) { x, y in Pixel(UInt8(x), UInt8(y), 0) }
}

/// Draws from rows of characters: `.` transparent, `#` black, `w` white, `r` red.
func drawn(_ rows: [String]) -> Bitmap {
    let chars = rows.map(Array.init)
    return Bitmap.make(width: chars[0].count, height: chars.count) { x, y in
        switch chars[y][x] {
        case "#": .black
        case "w": .white
        case "r": Pixel(255, 0, 0)
        default: .clear
        }
    }
}

func opaque(_ bitmap: Bitmap) -> [String] {
    (0..<bitmap.height).map { y in
        String((0..<bitmap.width).map { x in bitmap[x, y].a >= 128 ? "#" : "." })
    }
}

@Suite struct GeometryTests {
    @Test func aClockwiseTurnMovesTheTopLeftToTheTopRight() {
        let b = numbered(width: 3, height: 2)
        let r = b.rotated(quarterTurns: 1)
        #expect(r.width == 2 && r.height == 3)
        #expect(r[1, 0] == b[0, 0])
        #expect(r[0, 0] == b[0, 1])
        #expect(r[1, 2] == b[2, 0])
    }

    @Test func fourTurnsAreNoTurn() {
        let b = numbered(width: 4, height: 3)
        #expect(b.rotated(quarterTurns: 4) == b)
        #expect(b.rotated(quarterTurns: 1).rotated(quarterTurns: 3) == b)
        #expect(b.rotated(quarterTurns: 2) == b.rotated(quarterTurns: 1).rotated(quarterTurns: 1))
        #expect(b.rotated(quarterTurns: -1) == b.rotated(quarterTurns: 3))
    }

    @Test func flippingMirrorsEachRow() {
        let b = numbered(width: 3, height: 2)
        let f = b.flippedHorizontally()
        #expect(f[0, 1] == b[2, 1])
        #expect(f.flippedHorizontally() == b)
    }

    @Test func croppingRoundsOutwardsToWholePixels() {
        let b = numbered(width: 10, height: 10)
        let c = b.cropped(to: CropRect(x: 0.25, y: 0.5, width: 0.5, height: 0.26))
        #expect(c.width == 6 && c.height == 3)
        #expect(c[0, 0] == b[2, 5])
    }

    @Test func croppingNeverProducesAnEmptyImage() {
        let b = numbered(width: 2, height: 2)
        let c = b.cropped(to: CropRect(x: 1, y: 1, width: 0, height: 0))
        #expect(c.width >= 1 && c.height >= 1)
    }

    @Test func trimmingRemovesTheTransparentMargin() {
        let b = drawn([
            "....",
            ".#..",
            "..#.",
            "....",
        ])
        #expect(opaque(b.trimmed()) == ["#.", ".#"])
    }

    @Test func trimmingAnEmptyImageLeavesItAlone() {
        let b = Bitmap(width: 3, height: 2)
        #expect(b.trimmed() == b)
        #expect(!b.hasVisiblePixels)
        #expect(drawn(["..#"]).hasVisiblePixels)
    }

    @Test func fittingShrinksTheLongestSideAndKeepsTheAspect() {
        let b = Bitmap(width: 400, height: 100, fill: .black)
        let f = b.fitting(maxSide: 100)
        #expect(f.width == 100 && f.height == 25)
        #expect(f[50, 10] == .black)
        #expect(b.fitting(maxSide: 1000) == b)
    }

    @Test func fittingDoesNotDarkenEdgesAgainstTransparency() {
        // Half white, half transparent: the average must stay white, at half alpha.
        let b = Bitmap.make(width: 2, height: 2) { x, _ in x == 0 ? .white : .clear }
        let p = b.fitting(maxSide: 1)[0, 0]
        #expect(p.r == 255 && p.g == 255 && p.b == 255)
        #expect(p.a == 127)
    }
}

@Suite struct BackgroundTests {
    @Test func clearsTheBackdropFromTheEdges() {
        let b = drawn([
            "wwwww",
            "w###w",
            "w#r#w",
            "w###w",
            "wwwww",
        ])
        #expect(
            opaque(b.removingBackground(tolerance: 0.1)) == [
                ".....",
                ".###.",
                ".###.",
                ".###.",
                ".....",
            ])
    }

    @Test func keepsEnclosedAreasOfTheBackdropColour() {
        // The whites of the eyes: white, but walled in by the outline.
        let b = drawn([
            "wwwww",
            "w###w",
            "w#w#w",
            "w###w",
            "wwwww",
        ])
        let cleared = b.removingBackground(tolerance: 0.1)
        #expect(cleared[2, 2] == .white)
        #expect(cleared[0, 0].a == 0)
    }

    @Test func usesTheColourMostCornersShare() {
        // One corner is part of the subject; the other three agree on the backdrop.
        let b = drawn([
            "#rrr",
            "r##r",
            "rrrr",
        ])
        let cleared = b.removingBackground(tolerance: 0.1)
        #expect(cleared[3, 0].a == 0)
        #expect(cleared[1, 1] == .black)
        #expect(cleared[0, 0] == .black)
    }

    @Test func fadesAntiAliasedEdgesInsteadOfLeavingAFringe() {
        // A light grey pixel between the white backdrop and a black line.
        var b = drawn(["ww#", "ww#"])
        b[1, 0] = Pixel(235, 235, 235)
        let cleared = b.removingBackground(tolerance: 0.05)
        #expect(cleared[1, 0].a > 0 && cleared[1, 0].a < 255)
        #expect(cleared[2, 0] == .black)
    }

    @Test func leavesAnAlreadyTransparentImageAlone() {
        let b = drawn(["...", ".#.", "..."])
        #expect(b.removingBackground(tolerance: 0.2) == b)
    }
}

@Suite struct StyleTests {
    @Test func colorKeepsTheImage() {
        let b = drawn(["r#w"])
        #expect(b.styled(.color, threshold: 0.5, inverted: false) == b)
    }

    @Test func silhouetteKeepsTheShapeInBlack() {
        let s = drawn(["r.w"]).styled(.silhouette, threshold: 0.5, inverted: false)
        #expect(s[0, 0] == .black)
        #expect(s[1, 0].a == 0)
        #expect(s[2, 0] == .black)
    }

    @Test func inkKeepsTheDarkParts() {
        let s = drawn(["#w"]).styled(.ink, threshold: 0.5, inverted: false)
        #expect(s[0, 0].a == 255)
        #expect(s[1, 0].a == 0)
    }

    @Test func invertedInkKeepsTheLightParts() {
        let s = drawn(["#w."]).styled(.ink, threshold: 0.5, inverted: true)
        #expect(s[0, 0].a == 0)
        #expect(s[1, 0].a == 255)
        // Transparent stays transparent, whichever parts count as ink.
        #expect(s[2, 0].a == 0)
    }

    @Test func onlyColorIsDrawnAsIs() {
        #expect(Style.allCases.filter { !$0.isTemplate } == [.color])
    }
}
