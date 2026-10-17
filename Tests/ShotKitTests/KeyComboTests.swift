import Testing

@testable import ShotKit

@Suite struct KeyComboTests {
    @Test func standardIsShiftCommandTwo() {
        #expect(KeyCombo.standard.display { $0 == 19 ? "2" : nil } == "⇧⌘2")
        #expect(KeyCombo.standard.carbonModifiers == 0x0300)
        #expect(KeyCombo.standard.isUsable)
    }

    @Test func aBareLetterIsntUsableButAFunctionKeyIs() {
        #expect(!KeyCombo(keyCode: 0, modifiers: .shift).isUsable)
        #expect(KeyCombo(keyCode: 105, modifiers: []).isUsable)
    }
}
