import CoreGraphics
import Testing

@testable import ShotKit

@Suite struct GeometryTests {
    let screen = CGRect(x: 0, y: 0, width: 1512, height: 982)

    @Test func dragSpansTheSameRectWhicheverWayItGoes() {
        let a = CGPoint(x: 100, y: 200)
        let b = CGPoint(x: 300, y: 50)
        let expected = CGRect(x: 100, y: 50, width: 200, height: 150)
        #expect(Geometry.selection(from: a, to: b, within: screen) == expected)
        #expect(Geometry.selection(from: b, to: a, within: screen) == expected)
    }

    @Test func dragPastTheEdgeStopsAtTheScreen() {
        let rect = Geometry.selection(from: CGPoint(x: 1400, y: 900), to: CGPoint(x: 1700, y: 1100), within: screen)
        #expect(rect == CGRect(x: 1400, y: 900, width: 112, height: 82))
    }

    @Test func dragEntirelyOffScreenSelectsNothing() {
        let rect = Geometry.selection(from: CGPoint(x: -50, y: -50), to: CGPoint(x: -10, y: -10), within: screen)
        #expect(rect == .zero)
        #expect(Geometry.isClick(rect))
    }

    @Test func shortDragIsAClick() {
        #expect(Geometry.isClick(CGRect(x: 0, y: 0, width: 3, height: 300)))
        #expect(!Geometry.isClick(CGRect(x: 0, y: 0, width: 4, height: 4)))
    }

    @Test func pixelsFlipToTheTopAndScaleToRetina() {
        // A 100 × 50 pt box 10 pt from the left and 20 pt from the bottom of a 2× screen.
        let pixels = Geometry.pixels(
            of: CGRect(x: 10, y: 20, width: 100, height: 50), viewSize: screen.size, imageWidth: 3024,
            imageHeight: 1964)
        #expect(pixels == CGRect(x: 20, y: 1964 - 140, width: 200, height: 100))
    }

    @Test func pixelsRoundOutwardSoAPartlyCoveredPixelIsKept() {
        let pixels = Geometry.pixels(
            of: CGRect(x: 10.25, y: 0, width: 10.5, height: 10), viewSize: CGSize(width: 100, height: 100),
            imageWidth: 100, imageHeight: 100)
        #expect(pixels == CGRect(x: 10, y: 90, width: 11, height: 10))
    }

    @Test func pixelsIgnoreFloatingPointDust() {
        // 0.1 × 3 is 0.30000000000000004; that mustn't spill into one more pixel.
        let pixels = Geometry.pixels(
            of: CGRect(x: 0.1, y: 0, width: 0.2, height: 1), viewSize: CGSize(width: 1, height: 1), imageWidth: 10,
            imageHeight: 10)
        #expect(pixels == CGRect(x: 1, y: 0, width: 2, height: 10))
    }

    @Test func pixelsStayInsideTheImage() {
        let pixels = Geometry.pixels(
            of: CGRect(x: -5, y: -5, width: 200, height: 200), viewSize: CGSize(width: 100, height: 100),
            imageWidth: 200, imageHeight: 200)
        #expect(pixels == CGRect(x: 0, y: 0, width: 200, height: 200))
    }

    @Test func pixelsHandleAScaledDisplayWhoseRatioIsntWhole() {
        // "More Space" on a 14-inch MacBook Pro: 1800 × 1169 pt drawn into 3024 × 1964 px.
        let full = Geometry.pixels(
            of: CGRect(x: 0, y: 0, width: 1800, height: 1169), viewSize: CGSize(width: 1800, height: 1169),
            imageWidth: 3024, imageHeight: 1964)
        #expect(full == CGRect(x: 0, y: 0, width: 3024, height: 1964))
    }

    @Test func globalWindowFramesLandInTheRightPlaceOnASecondDisplay() {
        // A second display above and to the right of the main one: Core Graphics puts it at negative y.
        let display = CGRect(x: 1512, y: -1080, width: 1920, height: 1080)
        let window = CGRect(x: 1612, y: -1000, width: 800, height: 600)
        let local = Geometry.local(window, displayBounds: display)
        #expect(local == CGRect(x: 100, y: 1080 - 80 - 600, width: 800, height: 600))
    }

    @Test func globalPointIsTheInverseOfLocal() {
        let display = CGRect(x: -1920, y: 200, width: 1920, height: 1080)
        let point = CGRect(x: -1500, y: 300, width: 0, height: 0)
        let local = Geometry.local(point, displayBounds: display).origin
        #expect(Geometry.global(local, displayBounds: display) == point.origin)
    }

    @Test func topmostWindowIsTheFrontOneUnderThePoint() {
        let windows = [
            WindowFrame(id: 1, frame: CGRect(x: 0, y: 0, width: 100, height: 100)),
            WindowFrame(id: 2, frame: CGRect(x: 0, y: 0, width: 500, height: 500)),
        ]
        #expect(WindowFrame.topmost(at: CGPoint(x: 50, y: 50), in: windows)?.id == 1)
        #expect(WindowFrame.topmost(at: CGPoint(x: 200, y: 200), in: windows)?.id == 2)
        #expect(WindowFrame.topmost(at: CGPoint(x: 600, y: 600), in: windows) == nil)
    }

    @Test func snappingKeepsHalfPointsOnARetinaDisplay() {
        let rect = Geometry.snapped(CGRect(x: 10.5, y: 20.26, width: 100.3, height: 50), scale: 2)
        #expect(rect == CGRect(x: 10.5, y: 20.5, width: 100.5, height: 50))
    }

    @Test func snappingRoundsToWholePointsOnAStandardDisplay() {
        let rect = Geometry.snapped(CGRect(x: 10.5, y: 20.4, width: 100.3, height: 50), scale: 1)
        #expect(rect == CGRect(x: 11, y: 20, width: 100, height: 50))
    }

    @Test func aSnappedSelectionCapturesExactlyTheOutlinedPixels() {
        // Whatever the drag, the pixels copied are the snapped rectangle times the scale, nothing more.
        let view = CGSize(width: 1512, height: 982)
        for scale in [1.0, 2.0] {
            let snapped = Geometry.snapped(CGRect(x: 100.3, y: 200.7, width: 333.33, height: 123.45), scale: scale)
            let pixels = Geometry.pixels(
                of: snapped, viewSize: view, imageWidth: Int(view.width * scale), imageHeight: Int(view.height * scale))
            let expected = CGSize(width: (snapped.width * scale).rounded(), height: (snapped.height * scale).rounded())
            #expect(pixels.size == expected)
        }
    }
}
