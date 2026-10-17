import Foundation
import Testing

@testable import BatteryKit

struct DrainModelTests {
    @Test func learnsALinearRelationship() {
        var model = DrainModel(prior: [0, 0, 0], variance: 10, forgetting: 1)
        var rng = SplitMix(seed: 1)
        for _ in 0..<500 {
            let x = [1, Double.random(in: 0...3, using: &rng), Double.random(in: -1...1, using: &rng)]
            model.learn(x, 0.4 + 0.8 * x[1] - 0.5 * x[2])
        }
        #expect(abs(model.predict([1, 2, 0.5]) - (0.4 + 1.6 - 0.25)) < 0.01)
    }

    @Test func aFeatureThatNeverVariesDoesntWindUp() {
        var model = DrainModel(prior: [0, 0], variance: 0.5, forgetting: 0.999)
        // The second feature is always zero, as Low Power Mode is for someone who never uses it.
        for i in 0..<50_000 { model.learn([1, 0], Double(i % 3)) }
        let before = model.predict([1, 1])
        model.learn([1, 1], 1)
        #expect(abs(model.predict([1, 1]) - before) < 5, "one example swung the model from \(before)")
    }
}

struct EstimatorTests {
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func defersToMacOSUntilItHasLearned() {
        var e = TimeEstimator()
        let r = BatteryReading(
            level: 0.5, state: .discharging, minutesRemaining: 200, current: -1500, remainingCapacity: 4000)
        for minute in 0..<30 {
            #expect(e.update(r, at: start.addingTimeInterval(Double(minute) * 60)) == 200)
        }
    }

    @Test func chargingPassesThrough() {
        var e = TimeEstimator()
        let r = BatteryReading(
            level: 0.5, state: .charging, minutesRemaining: 42, current: 3000, remainingCapacity: 4000)
        #expect(e.update(r, at: start) == 42)
    }

    @Test func stateSurvivesARelaunch() throws {
        var sim = Simulator(seed: 7)
        var e = TimeEstimator()
        sim.run(sessions: 3, from: start, into: &e)
        let data = try JSONEncoder().encode(e.state)
        #expect(try JSONDecoder().decode(TimeEstimator.State.self, from: data) == e.state)
        #expect(e.state.labels > 0)
    }

    /// The claim the feature rests on: after a few weeks of use, the time shown is closer to
    /// the truth than macOS's method, and it counts down instead of jumping. Several seeds, so
    /// one lucky month can't carry it.
    @Test(arguments: [42, 7, 2026] as [UInt64])
    func beatsTheInstantEstimateOnSimulatedUse(seed: UInt64) {
        var sim = Simulator(seed: seed)
        var e = TimeEstimator()
        let trained = sim.run(sessions: 25, from: start, into: &e)
        let result = sim.run(sessions: 15, from: trained, into: &e, scoring: true)

        print(
            String(
                format: "seed %llu learned: %.0f min mean error, %.1f%% p95 jump; macOS-style: %.0f min, %.1f%%",
                seed, result.learnedError, result.learnedJump, result.instantError, result.instantJump))
        #expect(result.learnedError < result.instantError * 0.75)
        // The bound by design: 1% a minute of drift, plus up to a minute of rounding, which is
        // under 1% of anything over 100 minutes.
        #expect(result.learnedJump < 2)
        #expect(result.learnedJump < result.instantJump / 4)
    }
}

/// Deterministic randomness, so the simulation and its verdict are the same on every run.
struct SplitMix: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// A laptop's day: idle, browsing, builds, video calls, and evening video, mixed by the hour,
/// one reading a minute, each session run from full to empty so the true time left is known.
struct Simulator {
    var rng: SplitMix
    let fullCapacity = 7800.0

    init(seed: UInt64) { rng = SplitMix(seed: seed) }

    enum Activity: CaseIterable {
        case idle, browsing, building, call, video

        /// Amps, and the chance per minute of moving on.
        var draw: Double {
            switch self {
            case .idle: 0.35
            case .browsing: 0.9
            case .building: 4.2
            case .call: 2.0
            case .video: 1.3
            }
        }
        var leave: Double {
            switch self {
            case .idle: 0.15
            case .browsing: 0.08
            case .building: 0.3
            case .call: 0.03
            case .video: 0.02
            }
        }
    }

    /// How likely each activity is to come next at a given hour: building and calls during the
    /// working day, video in the evening.
    mutating func next(at hour: Int) -> Activity {
        let weights: [(Activity, Double)] =
            switch hour {
            case 9..<12: [(.idle, 2), (.browsing, 4), (.building, 3), (.call, 1), (.video, 0)]
            case 12..<18: [(.idle, 2), (.browsing, 3), (.building, 2), (.call, 3), (.video, 0)]
            case 18..<24: [(.idle, 2), (.browsing, 3), (.building, 0), (.call, 0), (.video, 5)]
            default: [(.idle, 5), (.browsing, 2), (.building, 0), (.call, 0), (.video, 1)]
            }
        var pick = Double.random(in: 0..<weights.map(\.1).reduce(0, +), using: &rng)
        for (activity, weight) in weights {
            if pick < weight { return activity }
            pick -= weight
        }
        return .idle
    }

    struct Result {
        var learnedError = 0.0
        var instantError = 0.0
        /// 95th percentile, percent of the time shown.
        var learnedJump = 0.0
        var instantJump = 0.0
    }

    /// Runs sessions on consecutive days and returns when the last ended; `scoring` fills `result`.
    @discardableResult
    mutating func run(sessions: Int, from start: Date, into e: inout TimeEstimator) -> Date {
        var ignored = Result()
        return run(sessions: sessions, from: start, into: &e, scoring: false, result: &ignored)
    }

    mutating func run(sessions: Int, from start: Date, into e: inout TimeEstimator, scoring: Bool) -> Result {
        var result = Result()
        _ = run(sessions: sessions, from: start, into: &e, scoring: scoring, result: &result)
        return result
    }

    private mutating func run(
        sessions: Int, from start: Date, into e: inout TimeEstimator, scoring: Bool, result: inout Result
    ) -> Date {
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: start)
        var learnedErrors: [Double] = []
        var instantErrors: [Double] = []
        var learnedJumps: [Double] = []
        var instantJumps: [Double] = []
        var end = start

        for _ in 0..<sessions {
            day = calendar.date(byAdding: .day, value: 1, to: day)!
            let begin = day.addingTimeInterval(Double(Int.random(in: 8...14, using: &rng)) * 3600)
            // Draw the whole session first, so every minute knows how long is truly left.
            var minutes: [(time: Date, amps: Double, capacity: Double)] = []
            var capacity = fullCapacity
            var activity = Activity.browsing
            var time = begin
            while capacity > 0 {
                let hour = calendar.component(.hour, from: time)
                if Double.random(in: 0..<1, using: &rng) < activity.leave { activity = next(at: hour) }
                let amps = activity.draw * Double.random(in: 0.85...1.15, using: &rng)
                minutes.append((time, amps, capacity))
                capacity -= amps * 1000 / 60
                time = time.addingTimeInterval(60)
            }
            var previous: (learned: Double, instant: Double)?
            for (i, m) in minutes.enumerated() {
                let instant = m.capacity / (m.amps * 1000) * 60
                let reading = BatteryReading(
                    level: m.capacity / fullCapacity, state: .discharging, minutesRemaining: Int(instant),
                    current: -Int(m.amps * 1000), remainingCapacity: Int(m.capacity))
                let shown = Double(e.update(reading, at: m.time) ?? 0)
                let truth = Double(minutes.count - i)
                // The last quarter hour and the warm-up say little about an estimator.
                if scoring, truth >= 15, i >= 10 {
                    learnedErrors.append(abs(shown - truth))
                    instantErrors.append(abs(instant - truth))
                    if let previous {
                        // A countdown loses one minute a minute; anything beyond that is a jump, as a
                        // share of what was showing: two minutes off four hours goes unnoticed.
                        learnedJumps.append(abs(shown - previous.learned + 1) / previous.learned * 100)
                        instantJumps.append(abs(instant - previous.instant + 1) / previous.instant * 100)
                    }
                    previous = (shown, instant)
                }
            }
            // Plugged in overnight.
            end = time
            _ = e.update(BatteryReading(level: 1, state: .charged), at: time)
        }
        func p95(_ values: [Double]) -> Double { values.sorted()[Int(Double(values.count) * 0.95)] }
        if scoring {
            result.learnedError = learnedErrors.reduce(0, +) / Double(learnedErrors.count)
            result.instantError = instantErrors.reduce(0, +) / Double(instantErrors.count)
            result.learnedJump = p95(learnedJumps)
            result.instantJump = p95(instantJumps)
        }
        return end
    }
}
