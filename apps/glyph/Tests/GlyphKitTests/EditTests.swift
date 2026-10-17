import Foundation
import Testing

@testable import GlyphKit

@Suite struct CropRectTests {
    @Test func movingStopsAtTheEdgesWithoutShrinking() {
        let r = CropRect(x: 0.5, y: 0.5, width: 0.4, height: 0.4).moved(dx: 0.5, dy: -1)
        #expect(r == CropRect(x: 0.6, y: 0, width: 0.4, height: 0.4))
    }

    @Test func resizingKeepsTheOppositeCornerPut() {
        let r = CropRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6).resized(.topLeading, dx: 0.1, dy: -0.1)
        #expect(abs(r.x - 0.3) < 1e-9 && abs(r.y - 0.1) < 1e-9)
        #expect(abs((r.x + r.width) - 0.8) < 1e-9 && abs((r.y + r.height) - 0.8) < 1e-9)
    }

    @Test func resizingCannotCollapseOrEscapeTheImage() {
        let r = CropRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
        let squashed = r.resized(.bottomTrailing, dx: -5, dy: -5)
        #expect(abs(squashed.width - CropRect.minimumSide) < 1e-9)
        #expect(abs(squashed.height - CropRect.minimumSide) < 1e-9)
        let stretched = r.resized(.topTrailing, dx: 5, dy: -5)
        #expect(stretched.y == 0 && abs(stretched.x + stretched.width - 1) < 1e-9)
    }

    @Test(arguments: CropRect.Corner.allCases)
    func everyCornerStaysInsideTheImage(corner: CropRect.Corner) {
        for d in [-2.0, -0.3, 0.3, 2.0] {
            let r = CropRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4).resized(corner, dx: d, dy: d)
            #expect(r.x >= 0 && r.y >= 0 && r.x + r.width <= 1 + 1e-9 && r.y + r.height <= 1 + 1e-9)
            #expect(r.width >= CropRect.minimumSide - 1e-9 && r.height >= CropRect.minimumSide - 1e-9)
        }
    }

    @Test func clampingPullsAStrayRectBackInside() {
        let r = CropRect(x: -0.5, y: 0.99, width: 2, height: 0).clamped()
        #expect(r == CropRect(x: 0, y: 1 - CropRect.minimumSide, width: 1, height: CropRect.minimumSide))
    }
}

@Suite struct EditTests {
    let source = numbered(width: 5, height: 3)

    @Test func rotatingTheEditTurnsWhatTheEditorShows() {
        for flipped in [false, true] {
            var edit = Edit()
            if flipped { edit.flip() }
            let before = edit.oriented(source)
            edit.rotateClockwise()
            #expect(edit.oriented(source) == before.rotated(quarterTurns: 1), "flipped: \(flipped)")
        }
    }

    @Test func flippingTheEditMirrorsWhatTheEditorShows() {
        var edit = Edit()
        edit.rotateClockwise()
        let before = edit.oriented(source)
        edit.flip()
        #expect(edit.oriented(source) == before.flippedHorizontally())
    }

    @Test func theCropFollowsTheImageWhenItTurnsOrFlips() {
        // Whatever the crop picked out before, it picks out the same pixels after, turned or mirrored.
        var edit = Edit()
        edit.crop = CropRect(x: 0, y: 0, width: 0.4, height: 1.0 / 3)
        let picked = edit.framed(source)
        edit.rotateClockwise()
        #expect(edit.framed(source) == picked.rotated(quarterTurns: 1))
        edit.flip()
        #expect(edit.framed(source) == picked.rotated(quarterTurns: 1).flippedHorizontally())
        edit.rotateClockwise()
        #expect(edit.framed(source) == picked.rotated(quarterTurns: 1).flippedHorizontally().rotated(quarterTurns: 1))
    }

    @Test func resettingTheFramingKeepsTheLook() {
        var edit = Edit()
        edit.style = .ink
        edit.scale = 0.6
        edit.rotateClockwise()
        edit.flip()
        edit.crop = CropRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5)
        edit.resetFraming()
        #expect(edit.oriented(source) == source && edit.crop.isFull)
        #expect(edit.style == .ink && edit.scale == 0.6)
    }

    @Test func finishingRemovesTheBackdropStylesAndTrims() {
        var edit = Edit()
        edit.background = .solid
        edit.style = .silhouette
        let out = edit.finished([
            drawn([
                "wwwww",
                "w#r#w",
                "wwwww",
            ])
        ])
        #expect(opaque(out[0]) == ["###"])
        #expect(out[0][1, 0] == .black)
    }

    @Test func animationFramesAreTrimmedToOneSharedBox() {
        // A bar lying flat, then standing up: trimmed apart, each would fill the glyph's size and be
        // squashed to the first frame's shape.
        let flat = drawn([
            ".....",
            ".....",
            ".###.",
            ".....",
            ".....",
        ])
        let standing = drawn([
            ".....",
            "..#..",
            "..#..",
            "..#..",
            ".....",
        ])
        let out = Edit().finished([flat, standing])
        #expect(opaque(out[0]) == ["...", "###", "..."])
        #expect(opaque(out[1]) == [".#.", ".#.", ".#."])
    }

    @Test func survivesARoundTripThroughUserDefaultsData() throws {
        var edit = Edit()
        edit.crop = CropRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
        edit.style = .ink
        edit.background = .subject
        let data = try JSONEncoder().encode(edit)
        #expect(try JSONDecoder().decode(Edit.self, from: data) == edit)
    }

    @Test func textStartsInTheMenuBarsOwnColour() {
        #expect(Edit.text.style == .silhouette)
        #expect(Style.suggested(forText: SourceKind.initialText) == .silhouette)
    }

    @Test(arguments: ["🐈‍⬛", "❤️", "hi 👋", "🫠"])
    func emojiAreSuggestedInColour(text: String) {
        #expect(Style.suggested(forText: text) == .color)
    }

    @Test(arguments: ["(◕‿◕)", "☯", "ok", "♥", "⌘"])
    func otherTextIsSuggestedAsASilhouette(text: String) {
        #expect(Style.suggested(forText: text) == .silhouette)
    }
}

@Suite struct GlyphSizeTests {
    @Test func fillsTheChosenShareOfTheBar() {
        let s = GlyphSize(pixelWidth: 100, pixelHeight: 100, barThickness: 24, scale: 0.75)
        #expect(s == GlyphSize(width: 18, height: 18))
    }

    @Test func keepsTheAspectRatio() {
        let s = GlyphSize(pixelWidth: 300, pixelHeight: 100, barThickness: 22, scale: 1)
        #expect(s == GlyphSize(width: 66, height: 22))
    }

    @Test func aVeryWideImageShrinksInsteadOfCrowdingTheMenus() {
        let s = GlyphSize(pixelWidth: 2000, pixelHeight: 100, barThickness: 22, scale: 1)
        #expect(s.width == GlyphSize.maximumWidth)
        #expect(s.height == 9)
    }

    @Test func clampsTheScale() {
        let tiny = GlyphSize(pixelWidth: 10, pixelHeight: 10, barThickness: 24, scale: 0)
        let huge = GlyphSize(pixelWidth: 10, pixelHeight: 10, barThickness: 24, scale: 5)
        #expect(tiny.height == 12 && huge.height == 24)
    }
}

@Suite struct FrameTimingTests {
    @Test func playsTooShortDelaysAtATenthOfASecond() {
        #expect(FrameTiming.delay(unclamped: 0, clamped: 0.1) == 0.1)
        #expect(FrameTiming.delay(unclamped: 0.01, clamped: nil) == 0.1)
        #expect(FrameTiming.delay(unclamped: nil, clamped: nil) == 0.1)
    }

    @Test func prefersTheUnclampedDelay() {
        #expect(FrameTiming.delay(unclamped: 0.04, clamped: 0.1) == 0.04)
        #expect(FrameTiming.delay(unclamped: nil, clamped: 0.5) == 0.5)
    }

    @Test func findsTheFrameShowingAtATime() {
        let delays = [0.1, 0.5, 0.2]
        #expect(FrameTiming.frame(at: 0, delays: delays) == 0)
        #expect(FrameTiming.frame(at: 0.15, delays: delays) == 1)
        #expect(FrameTiming.frame(at: 0.65, delays: delays) == 2)
        // Loops: 0.8 seconds is the start again.
        #expect(FrameTiming.frame(at: 0.85, delays: delays) == 0)
        #expect(FrameTiming.frame(at: 1000.65, delays: delays) == 2)
    }

    @Test func aStillImageIsAlwaysOnItsFirstFrame() {
        #expect(FrameTiming.frame(at: 12, delays: []) == 0)
        #expect(FrameTiming.frame(at: 12, delays: [0]) == 0)
    }
}
