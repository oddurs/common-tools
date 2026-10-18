import CoreGraphics
import Testing

@testable import ShotKit

@Suite struct PlacementTests {
    let screen = CGRect(x: 0, y: 0, width: 1512, height: 982)
    let pill = CGSize(width: 120, height: 24)

    @Test func pillSitsBelowTheBottomRightCorner() {
        let selection = CGRect(x: 300, y: 400, width: 500, height: 300)
        let frame = Placement.pill(size: pill, for: selection, in: screen)
        #expect(frame == CGRect(x: 680, y: 400 - 8 - 24, width: 120, height: 24))
    }

    @Test func pillMovesInsideTheCornerAtTheBottomOfTheScreen() {
        let selection = CGRect(x: 300, y: 0, width: 500, height: 300)
        let frame = Placement.pill(size: pill, for: selection, in: screen)
        #expect(frame == CGRect(x: 672, y: 8, width: 120, height: 24))
    }

    @Test func pillGoesAboveASelectionTooSmallToHoldIt() {
        let selection = CGRect(x: 300, y: 2, width: 60, height: 20)
        let frame = Placement.pill(size: pill, for: selection, in: screen)
        // Above the selection's top edge, at 2 + 20 points.
        #expect(frame.origin == CGPoint(x: 360 - 120, y: 22 + Placement.gap))
        #expect(screen.insetBy(dx: Placement.margin, dy: Placement.margin).contains(frame))
    }

    @Test func pillStaysOnScreenAtTheLeftEdge() {
        let selection = CGRect(x: 0, y: 400, width: 40, height: 40)
        let frame = Placement.pill(size: pill, for: selection, in: screen)
        #expect(frame.minX == Placement.margin)
    }

    @Test func aFullScreenSelectionKeepsThePillInside() {
        let frame = Placement.pill(size: pill, for: screen, in: screen)
        #expect(frame == CGRect(x: 1512 - 120 - 8, y: 8, width: 120, height: 24))
    }

    @Test func pillNeverSitsUnderTheNotch() {
        // A selection hugging the top of a notched display, whose bottom is still above the notch's.
        let notch = CGRect(x: 663, y: 950, width: 186, height: 32)
        let selection = CGRect(x: 600, y: 960, width: 240, height: 22)
        let frame = Placement.pill(size: pill, for: selection, in: screen, avoiding: [notch])
        #expect(!frame.intersects(notch))
    }

    @Test func loupeSitsBelowAndRightOfThePointer() {
        let frame = Placement.loupe(side: 126, at: CGPoint(x: 500, y: 500), in: screen)
        #expect(frame == CGRect(x: 524, y: 500 - 24 - 126, width: 126, height: 126))
    }

    @Test func loupeFlipsAtTheBottomRightCorner() {
        let frame = Placement.loupe(side: 126, at: CGPoint(x: 1500, y: 10), in: screen)
        #expect(frame == CGRect(x: 1500 - 24 - 126, y: 34, width: 126, height: 126))
    }

    @Test func loupeStepsAroundThePill() {
        let pillFrame = CGRect(x: 520, y: 360, width: 120, height: 24)
        let frame = Placement.loupe(side: 126, at: CGPoint(x: 500, y: 500), in: screen, avoiding: [pillFrame])
        #expect(!frame.intersects(pillFrame))
        #expect(frame.origin == CGPoint(x: 500 - 24 - 126, y: 500 - 24 - 126))
    }

    @Test func piecesLandOnWholePoints() {
        let selection = CGRect(x: 300.5, y: 400.25, width: 500, height: 300)
        let frame = Placement.pill(size: pill, for: selection, in: screen)
        #expect(frame.minX == frame.minX.rounded() && frame.minY == frame.minY.rounded())
    }
}
