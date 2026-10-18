import Foundation
import Testing

@testable import CommonShortcut

@Suite struct KeyComboTests {
    let controlShiftCommandC = KeyCombo(keyCode: 8, modifiers: [.control, .shift, .command])

    @Test func showsModifiersInTheSystemsOrder() {
        #expect(controlShiftCommandC.display { $0 == 8 ? "c" : nil } == "⌃⇧⌘C")
        #expect(KeyCombo(keyCode: 49, modifiers: .option).display { _ in nil } == "⌥Space")
    }

    @Test func givesCarbonItsOwnModifierBits() {
        #expect(controlShiftCommandC.carbonModifiers == 0x1000 | 0x0200 | 0x0100)
    }

    @Test func aBareLetterIsntUsableButAFunctionKeyIs() {
        #expect(!KeyCombo(keyCode: 0, modifiers: .shift).isUsable)
        #expect(KeyCombo(keyCode: 105, modifiers: []).isUsable)
        #expect(controlShiftCommandC.isUsable)
    }

    @Test func dropsFlagsThatArentModifiers() {
        // Caps Lock (1 << 16) and the function-key flag (1 << 23) come with some key events.
        let combo = KeyCombo(keyCode: 8, modifiers: KeyCombo.Modifiers(rawValue: 1 << 16 | 1 << 20 | 1 << 23))
        #expect(combo.modifiers == .command)
    }

    @Test func survivesSaving() throws {
        let data = try JSONEncoder().encode(controlShiftCommandC)
        #expect(try JSONDecoder().decode(KeyCombo.self, from: data) == controlShiftCommandC)
    }
}
