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

    @Test func theMenuShowsACharacterKeyAsItsLowercaseCharacter() {
        #expect(KeyCombo.standard.keyEquivalent(keyName: { _ in "2" }) == "2")
        let k = KeyCombo(keyCode: 40, modifiers: [.command, .option])
        #expect(k.keyEquivalent(keyName: { _ in "K" }) == "k")
    }

    @Test func theMenuShowsSpecialKeysAsAppKitsCodePoints() {
        let f5 = KeyCombo(keyCode: 96, modifiers: [])
        #expect(f5.keyEquivalent(keyName: { _ in nil }) == "\u{F708}")
        let space = KeyCombo(keyCode: 49, modifiers: [.option])
        #expect(space.keyEquivalent(keyName: { _ in " " }) == " ")
    }

    @Test func aKeyWithNoNameHasNoEquivalent() {
        #expect(KeyCombo(keyCode: 200, modifiers: [.command]).keyEquivalent(keyName: { _ in nil }) == nil)
    }
}
