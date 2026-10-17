import CoreGraphics
import Testing

@testable import ShotKit

@Suite struct GestureTests {
    let drag = CGRect(x: 10, y: 10, width: 200, height: 100)
    let click = CGRect(x: 10, y: 10, width: 1, height: 1)

    @Test func aDragIsAnAreaWithOrWithoutAWindowUnderIt() {
        #expect(Gesture.from(selection: drag, dragged: true, overWindow: true) == .area(drag))
        #expect(Gesture.from(selection: drag, dragged: true, overWindow: false) == .area(drag))
    }

    @Test func aClickOnAWindowIsThatWindow() {
        #expect(Gesture.from(selection: click, dragged: false, overWindow: true) == .window)
    }

    @Test func aClickOnTheDesktopIsNothing() {
        #expect(Gesture.from(selection: click, dragged: false, overWindow: false) == .nothing)
    }

    @Test func aDragShrunkBackToAClickIsNothing() {
        #expect(Gesture.from(selection: click, dragged: true, overWindow: true) == .nothing)
    }
}
