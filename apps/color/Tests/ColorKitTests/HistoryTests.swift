import Foundation
import Testing

@testable import ColorKit

@Suite struct HistoryTests {
    let red = ColorValue(.sRGB, red: 1, green: 0, blue: 0)
    let blue = ColorValue(.sRGB, red: 0, green: 0, blue: 1)

    @Test func keepsTheNewestTwelve() {
        var history = History()
        for i in 0..<20 { history.add(ColorValue(.sRGB, red: Double(i) / 20, green: 0, blue: 0)) }
        #expect(history.colors.count == 12)
        #expect(history.current == ColorValue(.sRGB, red: 19 / 20, green: 0, blue: 0))
    }

    @Test func aRepeatMovesToTheFront() {
        var history = History()
        history.add(red)
        history.add(blue)
        history.add(red)
        #expect(history.colors.count == 2)
        #expect(history.current == red)
        #expect(history.contrast == Contrast(red, blue))
    }

    @Test func oneColourHasNoContrast() {
        var history = History()
        history.add(red)
        #expect(history.contrast == nil)
        history.clear()
        #expect(history.colors.isEmpty)
    }

    @Test func survivesSaving() throws {
        var history = History()
        let p3 = ColorValue(.displayP3, red: 0.1, green: 0.9, blue: 0.2)
        history.add(red)
        history.add(p3)
        let restored = try History(decoding: history.encoded())
        #expect(restored.colors.count == 2)
        #expect(restored.colors[0].matches(p3))
        #expect(ColorFormat.hex.string(restored.colors[1]) == "#ff0000")
        #expect(ColorFormat.displayP3.string(restored.colors[0]) == "color(display-p3 0.1 0.9 0.2)")
    }

    @Test func refusesAnUnreadableHistory() {
        #expect(throws: (any Error).self) { try History(decoding: Data(#"[{"p3":[1,2]}]"#.utf8)) }
        #expect(throws: (any Error).self) { try History(decoding: Data("nope".utf8)) }
    }

    @Test func persistsAcrossLaunches() throws {
        let defaults = try #require(UserDefaults(suiteName: "HistoryTests-\(UUID())"))
        var history = History()
        history.add(red)
        history.add(blue)
        try history.save(to: defaults, key: "history")
        // A new launch reads only what was saved.
        let (restored, error) = History.load(from: defaults, key: "history")
        #expect(error == nil)
        #expect(restored.colors.map(ColorFormat.hex.string) == ["#0000ff", "#ff0000"])

        history.clear()
        try history.save(to: defaults, key: "history")
        #expect(History.load(from: defaults, key: "history").0.colors.isEmpty)
    }

    @Test func setsAsideAnUnreadableHistoryInsteadOfLosingIt() throws {
        let defaults = try #require(UserDefaults(suiteName: "HistoryTests-\(UUID())"))
        let garbage = Data("nope".utf8)
        defaults.set(garbage, forKey: "history")
        let (history, error) = History.load(from: defaults, key: "history")
        #expect(history.colors.isEmpty)
        #expect(error != nil)
        #expect(defaults.data(forKey: "history.unreadable") == garbage)
        #expect(defaults.data(forKey: "history") == nil)
    }
}
