import Foundation
import Testing

@testable import ColorKit

@Suite struct DescribeTests {
    func srgb(_ hex: UInt32) -> ColorValue {
        ColorValue(
            .sRGB, red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255)
    }

    @Test(
        arguments: [
            (0xff0000, "vivid red"), (0xff8000, "orange"), (0xffff00, "vivid yellow"), (0x00ff00, "vivid green"),
            (0x00ffff, "cyan"), (0x0000ff, "vivid blue"), (0x800080, "dark purple"), (0xff69b4, "pink"),
            (0x3a7bd5, "blue"), (0x8b4513, "brown"), (0xe8e0ff, "pale purple"), (0x0e7c86, "cyan"),
            (0x000000, "black"), (0xffffff, "white"), (0x777777, "grey"), (0x1d1d1f, "dark grey"),
            (0xd0d0d0, "light grey"), (0xc8e6c9, "pale green"),
        ] as [(UInt32, String)])
    func namesTheFamily(hex: UInt32, family: String) {
        #expect(srgb(hex).family == family, "\(String(hex, radix: 16))")
    }

    @Test func speaksTheFamilyAndTheHex() {
        #expect(srgb(0x3a7bd5).spoken == "Blue, hex 3A7BD5")
        let green = ColorValue(.displayP3, red: 0, green: 1, blue: 0)
        #expect(green.spoken == "Vivid green, hex 00FB29, Display P3, outside sRGB")
    }

    @Test func saysWhereTheColourSits() {
        #expect(srgb(0x3a7bd5).gamutDescription == "sRGB")
        #expect(ColorValue(.displayP3, red: 0, green: 1, blue: 0).gamutDescription == "Display P3, outside sRGB")
        #expect(ColorValue(.sRGB, red: -0.6, green: 1.1, blue: -0.4).gamutDescription == "Outside Display P3")
    }

    @Test func givesTheHighestBarAContrastClears() {
        #expect(Contrast(srgb(0x000000), srgb(0xffffff)).verdict == "Passes AAA")
        #expect(Contrast(srgb(0x767676), srgb(0xffffff)).verdict == "Passes AA")
        #expect(Contrast(srgb(0x777777), srgb(0xffffff)).verdict == "Large text only")
        #expect(Contrast(srgb(0xaaaaaa), srgb(0xffffff)).verdict == "Fails AA")
    }

    @Test func speaksTheContrastAsASentence() {
        #expect(
            Contrast(srgb(0x777777), srgb(0xffffff)).spoken
                == "Contrast 4.47 to 1. Normal text: fails AA and AAA. Large text: passes AA, fails AAA.")
        #expect(
            Contrast(srgb(0x000000), srgb(0xffffff)).spoken
                == "Contrast 21 to 1. Normal text: passes AA and AAA. Large text: passes AA and AAA.")
    }

    @Test func numbersEveryFormatFromOne() {
        #expect(ColorFormat.allCases.map(\.key) == ["1", "2", "3", "4", "5", "6", "7"])
        #expect(ColorFormat(key: "1") == .hex)
        #expect(ColorFormat(key: "7") == .appKit)
        #expect(ColorFormat(key: "8") == nil)
        #expect(ColorFormat(key: "0") == nil)
        #expect(ColorFormat(key: "a") == nil)
    }
}

@Suite struct GridMoveTests {
    // Twelve in rows of six: 0…5 above 6…11.
    @Test func movesWithinTheRowAndStopsAtTheEnds() {
        #expect(GridMove.right.from(0, count: 12, columns: 6) == 1)
        #expect(GridMove.left.from(0, count: 12, columns: 6) == 0)
        #expect(GridMove.right.from(11, count: 12, columns: 6) == 11)
        // Right from the end of a row carries on to the next, as reading order does.
        #expect(GridMove.right.from(5, count: 12, columns: 6) == 6)
    }

    @Test func movesBetweenRowsWithoutWrapping() {
        #expect(GridMove.down.from(2, count: 12, columns: 6) == 8)
        #expect(GridMove.down.from(8, count: 12, columns: 6) == 8)
        #expect(GridMove.up.from(8, count: 12, columns: 6) == 2)
        #expect(GridMove.up.from(2, count: 12, columns: 6) == 2)
        // A short last row: down from above an empty cell stays put.
        #expect(GridMove.down.from(4, count: 8, columns: 6) == 4)
    }

    @Test func startsAtTheFirstAndIgnoresAnEmptyGrid() {
        #expect(GridMove.down.from(nil, count: 3, columns: 6) == 0)
        #expect(GridMove.left.from(7, count: 3, columns: 6) == 0)
        #expect(GridMove.right.from(nil, count: 0, columns: 6) == nil)
    }
}

extension HistoryTests {
    @Test func removesOneAndUndoPutsItBack() {
        var history = History()
        let green = ColorValue(.sRGB, red: 0, green: 1, blue: 0)
        for color in [red, green, blue] { history.add(color) }
        let removed = history.remove(at: 1)
        #expect(removed == green)
        #expect(history.colors == [blue, red])
        history.restore(removed, at: 1)
        #expect(history.colors == [blue, green, red])
    }

    @Test func undoDoesNotDuplicateAPickMadeAgain() {
        var history = History()
        history.add(red)
        history.add(blue)
        let removed = history.remove(at: 1)
        history.add(red)
        history.restore(removed, at: 1)
        #expect(history.colors == [red, blue])
    }
}
