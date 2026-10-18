import BarKit
import CoreGraphics
import Foundation

/// Plays a ⌘-drag in the menu bar, the way a person moves a status item: press with ⌘ held, drag
/// in small steps, let go. macOS has no API to move another app's item. Posting events needs
/// Accessibility, which opening an icon from a folder already asked for.
///
/// For the third of a second it takes, the pointer is hidden and the mouse is detached from it, so
/// a hand on the trackpad can't pull the drag somewhere else; afterwards the pointer is back where
/// it was.
enum MenuBarDrag {
    private static let pause: useconds_t = 12_000

    static func perform(from: CGPoint, to: CGPoint) async {
        await Task.detached(priority: .userInitiated) { play(from: from, to: to) }.value
    }

    private nonisolated static func play(from: CGPoint, to: CGPoint) {
        let source = CGEventSource(stateID: .hidSystemState)
        let home = CGEvent(source: nil)?.location
        let display = CGMainDisplayID()
        CGDisplayHideCursor(display)
        CGAssociateMouseAndMouseCursorPosition(0)
        defer {
            if let home { CGWarpMouseCursorPosition(home) }
            CGAssociateMouseAndMouseCursorPosition(1)
            CGDisplayShowCursor(display)
        }
        func post(_ type: CGEventType, _ point: CGPoint) {
            guard
                let event = CGEvent(
                    mouseEventSource: source, mouseType: type, mouseCursorPosition: point, mouseButton: .left)
            else { return }
            event.flags = .maskCommand
            event.post(tap: .cghidEventTap)
            usleep(pause)
        }
        post(.mouseMoved, from)
        post(.leftMouseDown, from)
        // macOS starts the item moving only once the pointer has moved a little while pressed.
        for point in Move.path(from: from, to: to) { post(.leftMouseDragged, point) }
        post(.leftMouseUp, to)
    }
}
