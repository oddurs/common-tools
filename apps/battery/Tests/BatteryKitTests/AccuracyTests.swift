import Foundation
import Testing

@testable import BatteryKit

/// Cross-checks the sampler against the system's own command-line tools. On a Mac without a
/// battery, such as a CI runner, both must agree there is none.
struct AccuracyTests {
    func run(_ tool: String, _ args: [String]) throws -> String {
        let p = Process()
        let pipe = Pipe()
        p.executableURL = URL(fileURLWithPath: tool)
        p.arguments = args
        p.standardOutput = pipe
        try p.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return String(decoding: data, as: UTF8.self)
    }

    @Test func levelMatchesPmset() throws {
        let pmset = try run("/usr/bin/pmset", ["-g", "batt"])
        let percent = pmset.firstMatch(of: /InternalBattery[^\t]*\t(\d+)%/).flatMap { Int($0.1) }
        let reading = BatterySampler().sample()
        guard let percent else {
            #expect(reading == nil, "pmset sees no battery, but the sampler read \(String(describing: reading))")
            return
        }
        let sampled = try #require(reading).percent
        // A percent can tick over between the two reads.
        #expect(abs(sampled - percent) <= 1, "sampled \(sampled)%, pmset \(percent)%")
    }

    @Test func stateMatchesPmset() throws {
        let pmset = try run("/usr/bin/pmset", ["-g", "batt"])
        guard let reading = BatterySampler().sample(), pmset.contains("InternalBattery") else { return }
        let drawingFromAC = pmset.contains("'AC Power'")
        #expect(reading.isOnPower == drawingFromAC, "pmset: \(pmset)")
    }

    @Test func cycleCountMatchesIoreg() throws {
        let ioreg = try run("/usr/sbin/ioreg", ["-rn", "AppleSmartBattery", "-d", "1"])
        let cycles = ioreg.firstMatch(of: /"CycleCount" = (\d+)/).flatMap { Int($0.1) }
        guard let cycles else { return }
        #expect(BatterySampler().sample()?.cycleCount == cycles)
    }

    @Test func remainingChargeMatchesIoreg() throws {
        let ioreg = try run("/usr/sbin/ioreg", ["-rn", "AppleSmartBattery", "-d", "1"])
        guard let raw = ioreg.firstMatch(of: /"AppleRawCurrentCapacity" = (\d+)/).flatMap({ Int($0.1) }) else { return }
        let sampled = try #require(BatterySampler().sample()?.remainingCapacity)
        // The gauge counts while the two reads happen; a few mAh is seconds of use.
        #expect(abs(sampled - raw) <= 5, "sampled \(sampled) mAh, ioreg \(raw) mAh")
    }
}
