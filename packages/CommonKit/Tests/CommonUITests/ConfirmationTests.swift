import AppKit
import Testing

@testable import CommonUI

@Suite struct ConfirmationTests {
    let screen = NSRect(x: 0, y: 0, width: 1512, height: 944)
    let card = CGSize(width: 200, height: 48)

    @Test func sitsBelowAndRightOfThePoint() {
        let origin = ConfirmationHost.origin(for: card, near: NSPoint(x: 400, y: 500), in: screen)
        #expect(origin == NSPoint(x: 416, y: 436))
    }

    @Test func flipsToStayOnTheScreen() {
        // Near the right edge it goes to the left of the point; near the bottom, above it.
        let corner = ConfirmationHost.origin(for: card, near: NSPoint(x: 1500, y: 20), in: screen)
        #expect(corner == NSPoint(x: 1284, y: 36))
        #expect(corner.x + card.width <= screen.maxX && corner.y >= screen.minY)
    }

    @Test func staysOnAScreenSmallerThanTheOffset() {
        let tight = NSRect(x: 0, y: 0, width: 210, height: 60)
        let origin = ConfirmationHost.origin(for: card, near: NSPoint(x: 100, y: 30), in: tight)
        #expect(origin.x >= 0 && origin.x + card.width <= tight.maxX)
        #expect(origin.y >= 0 && origin.y + card.height <= tight.maxY)
    }
}
