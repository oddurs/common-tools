import Testing

@testable import BatteryKit

struct AppearanceTests {
    /// Every style and time setting an install could have saved before parts could be arranged.
    @Test(arguments: [
        ("icon", false, [BarPart.battery], IconStyle.plain),
        ("icon", true, [.time, .battery], .plain),
        ("iconAndPercent", false, [.percent, .battery], .plain),
        ("iconAndPercent", true, [.time, .percent, .battery], .plain),
        ("percentInIcon", false, [.battery], .percentInside),
        ("percentInIcon", true, [.time, .battery], .percentInside),
        ("percent", false, [.percent], .plain),
        ("percent", true, [.time, .percent], .plain),
    ])
    func anOldInstallKeepsWhatItShowed(style: String, showsTime: Bool, parts: [BarPart], icon: IconStyle) {
        let restored = BarAppearance.restored(
            parts: nil, iconStyle: nil, legacyStyle: style, legacyShowsTime: showsTime, colorsAlerts: false)
        #expect(restored.parts == parts)
        #expect(restored.iconStyle == icon)
        #expect(!restored.colorsAlerts)
    }

    @Test func aFreshInstallGetsTheStandard() {
        let restored = BarAppearance.restored(
            parts: nil, iconStyle: nil, legacyStyle: nil, legacyShowsTime: false, colorsAlerts: true)
        #expect(restored == .standard)
    }

    @Test func savedPartsWinOverTheOldKeys() {
        let restored = BarAppearance.restored(
            parts: ["time"], iconStyle: "plain", legacyStyle: "percentInIcon", legacyShowsTime: false,
            colorsAlerts: true)
        #expect(restored.parts == [.time])
        #expect(restored.iconStyle == .plain)
    }

    @Test func unreadablePartsFallBack() {
        // A newer version's part is skipped; nothing usable is the standard, never an empty item.
        #expect(
            BarAppearance.restored(
                parts: ["sparkline", "percent", "percent"], iconStyle: "future", legacyStyle: nil,
                legacyShowsTime: false, colorsAlerts: true
            ).parts == [.percent])
        #expect(
            BarAppearance.restored(
                parts: [], iconStyle: nil, legacyStyle: nil, legacyShowsTime: false, colorsAlerts: true
            ).parts == BarAppearance.standard.parts)
    }

    @Test func theLastPartStays() {
        var appearance = BarAppearance(parts: [.time, .percent])
        appearance.remove(.percent)
        #expect(appearance.parts == [.time])
        #expect(!appearance.canRemove)
        appearance.remove(.time)
        #expect(appearance.parts == [.time])
    }

    @Test func placingMovesOrAdds() {
        var appearance = BarAppearance(parts: [.percent, .battery])
        #expect(appearance.hidden == [.time])
        appearance.place(.time, at: .max)
        #expect(appearance.parts == [.percent, .battery, .time])
        appearance.place(.battery, at: 0)
        #expect(appearance.parts == [.battery, .percent, .time])
        appearance.place(.time, at: -3)
        #expect(appearance.parts == [.time, .battery, .percent])
        #expect(appearance.hidden.isEmpty)
        #expect(appearance.storedParts == ["time", "battery", "percent"])
    }
}
