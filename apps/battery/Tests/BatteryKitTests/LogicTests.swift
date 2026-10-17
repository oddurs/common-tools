import Foundation
import Testing

@testable import BatteryKit

struct FormatTests {
    @Test func duration() {
        #expect(Format.duration(minutes: 161) == "2:41")
        #expect(Format.duration(minutes: 4) == "0:04")
        #expect(Format.duration(minutes: -1) == Format.missing)
    }

    @Test func wattsFollowTheRegion() {
        #expect(Format.watts(-21.09, locale: Locale(identifier: "en_US")) == "21.1 W")
        #expect(Format.watts(45, locale: Locale(identifier: "de_DE")) == "45,0 W")
        #expect(Format.watts(.nan) == Format.missing)
    }

    @Test func temperatureFollowsTheRegion() {
        #expect(Format.temperature(celsius: 29.7, locale: Locale(identifier: "en_US")) == "85°F")
        #expect(Format.temperature(celsius: 29.7, locale: Locale(identifier: "en_GB")).hasPrefix("30°"))
    }

    @Test func status() {
        #expect(
            Format.status(BatteryReading(level: 0.5, state: .discharging, minutesRemaining: 161)) == "2:41 remaining")
        #expect(Format.status(BatteryReading(level: 0.5, state: .discharging)) == "Calculating…")
        #expect(Format.status(BatteryReading(level: 0.5, state: .charging, minutesRemaining: 52)) == "0:52 until full")
        #expect(Format.status(BatteryReading(level: 0.5, state: .charging)) == "Charging")
        #expect(Format.status(BatteryReading(level: 1, state: .charged)) == "Charged")
        #expect(Format.status(BatteryReading(level: 0.8, state: .notCharging)) == "Not charging")
    }
}

struct AlertTests {
    func at(_ percent: Int, _ state: BatteryReading.State) -> BatteryReading {
        BatteryReading(level: Double(percent) / 100, state: state)
    }

    @Test func lowFiresOnceAsTheLevelCrosses() {
        var t = AlertTracker()
        #expect(t.update(at(25, .discharging), low: 20, charged: nil).isEmpty)
        #expect(t.update(at(20, .discharging), low: 20, charged: nil) == [.low(percent: 20)])
        #expect(t.update(at(19, .discharging), low: 20, charged: nil).isEmpty)
        #expect(t.update(at(5, .discharging), low: 20, charged: nil).isEmpty)
    }

    @Test func lowRearmsAfterPower() {
        var t = AlertTracker()
        _ = t.update(at(25, .discharging), low: 20, charged: nil)
        _ = t.update(at(20, .discharging), low: 20, charged: nil)
        #expect(t.update(at(21, .charging), low: 20, charged: nil).isEmpty)
        #expect(t.update(at(19, .discharging), low: 20, charged: nil) == [.low(percent: 19)])
    }

    @Test func conditionsTrueAtLaunchStayQuiet() {
        var t = AlertTracker()
        #expect(t.update(at(10, .discharging), low: 20, charged: nil).isEmpty)
        var u = AlertTracker()
        #expect(u.update(at(100, .charged), low: nil, charged: 80).isEmpty)
    }

    @Test func chargedFiresOnReachingTheLevel() {
        var t = AlertTracker()
        #expect(t.update(at(79, .charging), low: nil, charged: 80).isEmpty)
        #expect(t.update(at(80, .notCharging), low: nil, charged: 80) == [.charged(percent: 80)])
        #expect(t.update(at(81, .charging), low: nil, charged: 80).isEmpty)
        // Unplugged and plugged back in above the level: it didn't charge up to it, so stay quiet.
        #expect(t.update(at(81, .discharging), low: nil, charged: 80).isEmpty)
        #expect(t.update(at(81, .charging), low: nil, charged: 80).isEmpty)
        // Drained below it and charged back: that's a crossing.
        #expect(t.update(at(70, .discharging), low: nil, charged: 80).isEmpty)
        #expect(t.update(at(79, .charging), low: nil, charged: 80).isEmpty)
        #expect(t.update(at(80, .charging), low: nil, charged: 80) == [.charged(percent: 80)])
    }

    @Test func offMeansOffAndNoReadingMeansNothing() {
        var t = AlertTracker()
        _ = t.update(at(30, .discharging), low: nil, charged: nil)
        #expect(t.update(at(5, .discharging), low: nil, charged: nil).isEmpty)
        #expect(t.update(nil, low: 20, charged: 80).isEmpty)
    }
}

struct HistoryTests {
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    func reading(_ level: Double, charging: Bool = false) -> BatteryReading {
        BatteryReading(level: level, state: charging ? .charging : .discharging)
    }

    @Test func burstsKeepASampleAMinute() {
        var h = ChargeHistory()
        // A power-source event every 10 s for five minutes.
        for s in stride(from: 0, through: 300, by: 10) {
            h.record(reading(1 - Double(s) / 1000), at: start.addingTimeInterval(Double(s)))
        }
        #expect(h.samples.count == 6)
        for (a, b) in zip(h.samples, h.samples.dropFirst()) {
            #expect(b.time.timeIntervalSince(a.time) >= ChargeHistory.spacing)
        }
    }

    @Test func oldSamplesFallOff() throws {
        var h = ChargeHistory()
        for m in 0...(13 * 60) { h.record(reading(0.5), at: start.addingTimeInterval(Double(m) * 60)) }
        let first = try #require(h.samples.first).time
        let last = try #require(h.samples.last).time
        #expect(last.timeIntervalSince(first) <= ChargeHistory.span)
        #expect(h.samples.count <= 12 * 60 + 1)
    }

    @Test func sleepSplitsTheLine() {
        var h = ChargeHistory()
        for m in [0, 1, 2, 60, 61] { h.record(reading(0.5), at: start.addingTimeInterval(Double(m) * 60)) }
        #expect(h.runs().map(\.count) == [3, 2])
    }

    @Test func chargingIsRemembered() {
        var h = ChargeHistory()
        h.record(reading(0.5, charging: true), at: start)
        #expect(h.samples.first?.charging == true)
    }
}
