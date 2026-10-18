import CoreGraphics
import Testing

@testable import ShotKit

@Suite struct PrecisionTests {
    let screen = CGRect(x: 0, y: 0, width: 1512, height: 982)

    @Test func anArrowMovesOneDevicePixel() {
        let retina = Precision.nudge(CGPoint(x: 100, y: 100), .right, large: false, scale: 2, within: screen)
        #expect(retina == CGPoint(x: 100.5, y: 100))
        let standard = Precision.nudge(CGPoint(x: 100, y: 100), .up, large: false, scale: 1, within: screen)
        #expect(standard == CGPoint(x: 100, y: 101))
    }

    @Test func shiftArrowMovesTen() {
        let point = Precision.nudge(CGPoint(x: 100, y: 100), .down, large: true, scale: 2, within: screen)
        #expect(point == CGPoint(x: 100, y: 95))
    }

    @Test func aNudgeLandsOnThePixelGrid() {
        // The pointer can sit between device pixels; the first nudge puts it on one.
        let point = Precision.nudge(CGPoint(x: 100.3, y: 100.8), .left, large: false, scale: 2, within: screen)
        #expect(point == CGPoint(x: 100, y: 101))
    }

    @Test func aNudgeStopsAtTheDisplaysEdges() {
        #expect(Precision.nudge(.zero, .left, large: true, scale: 2, within: screen) == .zero)
        let corner = CGPoint(x: 1512, y: 982)
        #expect(Precision.nudge(corner, .up, large: false, scale: 2, within: screen) == corner)
    }

    let window = CGRect(x: 200, y: 200, width: 600, height: 400)

    @Test func aCornerNearAWindowEdgeSettlesOnIt() {
        let point = Precision.snapped(CGPoint(x: 203, y: 450), toEdgesOf: [window], within: screen)
        #expect(point == CGPoint(x: 200, y: 450))
    }

    @Test func bothAxesSnapAtAWindowsCorner() {
        let point = Precision.snapped(CGPoint(x: 797, y: 604), toEdgesOf: [window], within: screen)
        #expect(point == CGPoint(x: 800, y: 600))
    }

    @Test func farFromAnEdgeNothingMoves() {
        let point = CGPoint(x: 210, y: 450)
        #expect(Precision.snapped(point, toEdgesOf: [window], within: screen) == point)
    }

    @Test func anEdgeCountsOnlyBesideItsWindow() {
        // In line with the window's left edge, but far below the window.
        let point = CGPoint(x: 202, y: 100)
        #expect(Precision.snapped(point, toEdgesOf: [window], within: screen) == point)
    }

    @Test func anEdgeHiddenByAWindowInFrontDoesntCount() {
        let front = CGRect(x: 100, y: 300, width: 300, height: 200)
        // The back window's left edge at y 400 lies under the front window.
        let point = CGPoint(x: 203, y: 400)
        #expect(Precision.snapped(point, toEdgesOf: [front, window], within: screen) == point)
    }

    @Test func theDisplaysEdgesCount() {
        let point = Precision.snapped(CGPoint(x: 1509, y: 3), toEdgesOf: [], within: screen)
        #expect(point == CGPoint(x: 1512, y: 0))
    }

    @Test func theNearestEdgeWins() {
        let beside = CGRect(x: 806, y: 200, width: 300, height: 400)
        let point = Precision.snapped(CGPoint(x: 804, y: 300), toEdgesOf: [window, beside], within: screen)
        #expect(point.x == 806)
    }

    @Test func spaceMovesTheWholeSelection() {
        let moved = Precision.moved(
            start: CGPoint(x: 100, y: 100), end: CGPoint(x: 300, y: 200), by: CGVector(dx: 50, dy: -20), within: screen)
        #expect(moved.start == CGPoint(x: 150, y: 80))
        #expect(moved.end == CGPoint(x: 350, y: 180))
    }

    @Test func aMovedSelectionStopsAtTheEdge() {
        let moved = Precision.moved(
            start: CGPoint(x: 1300, y: 100), end: CGPoint(x: 1500, y: 200), by: CGVector(dx: 50, dy: -500),
            within: screen)
        #expect(moved.start == CGPoint(x: 1312, y: 0))
        #expect(moved.end == CGPoint(x: 1512, y: 100))
    }
}
