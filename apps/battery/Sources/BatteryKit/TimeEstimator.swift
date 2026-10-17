import Foundation

/// Time to empty, learned from how this Mac is used.
///
/// macOS divides the charge left by the current of the last minute or so, so the time leaps as
/// soon as a build starts or the screen dims. This instead predicts the average current of the
/// next hour from the last 5 and 30 minutes, the time of day, and Low Power Mode, with a model
/// that learns from every hour on battery what that hour actually drew. It's only used once its
/// measured error is lower than the alternatives', and what's shown counts down smoothly.
///
/// Feed it every reading; it returns the minutes to show. While charging, or until it has
/// something better, that's macOS's own figure.
public struct TimeEstimator: Sendable {
    /// What survives a relaunch: the model, and how well each predictor has done.
    public struct State: Codable, Equatable, Sendable {
        var model = DrainModel(prior: TimeEstimator.prior, variance: 0.5, forgetting: 0.9995)
        /// Running mean absolute error, in amps, of each predictor's next-hour current.
        var errors: [Predictor: Double] = [:]
        /// Hours on battery the predictors have been scored on, counted in labelled minutes.
        public internal(set) var labels = 0

        public init() {}
    }

    enum Predictor: String, Codable, CaseIterable, Sendable {
        /// The learned model.
        case model
        /// The 30-minute average alone.
        case trend
        /// The gauge's current right now, standing in for macOS's estimate, which divides by it.
        case instant
    }

    public private(set) var state: State

    /// One minute's features, kept until an hour later says what that hour drew.
    private struct Pending: Sendable {
        let time: Date
        let features: [Double]
        let capacity: Int
        let predictions: [Predictor: Double]
    }

    private var short: Double?
    private var long: Double?
    private var last: (time: Date, capacity: Int)?
    private var stretchStart: Date?
    /// Chosen when a stretch starts and kept to its end, so the method never changes while
    /// someone watches the countdown. Nil defers to macOS.
    private var choice: Predictor?
    private var pending: [Pending] = []
    private var shown: (time: Date, minutes: Double)?

    public init(state: State = State()) {
        self.state = state
    }

    // MARK: Tuning

    /// Starts as "mostly the 30-minute average", the best guess with no history, and learns from there.
    static let prior: [Double] = [0, 0.3, 0.7, 0, 0, 0]
    static let shortWindow: TimeInterval = 5 * 60
    static let longWindow: TimeInterval = 30 * 60
    static let horizon: TimeInterval = 60 * 60
    /// A stretch cut short by a charger still teaches, if it ran this long.
    static let shortestLabel: TimeInterval = 15 * 60
    /// Longer than this between readings is sleep or a quit: the stretch starts again.
    static let gap: TimeInterval = 5 * 60
    /// Before this much of a stretch, the averages haven't settled and macOS's figure stands.
    static let warmUp: TimeInterval = 3 * 60
    /// About an hour of scored predictions before any are trusted over macOS.
    static let trustAfter = 60
    /// How quickly what's shown eases toward the estimate.
    static let settle: TimeInterval = 10 * 60
    /// The most what's shown may move beyond the countdown, as a share of itself per minute.
    /// At 1%, "4:00" moves at most 2–3 minutes in a minute, which reads as a steady countdown,
    /// yet a real change, like starting a game, is fully shown within the hour.
    static let drift = 0.01

    // MARK: Updating

    /// The minutes to show for this reading.
    public mutating func update(_ reading: BatteryReading, at now: Date) -> Int? {
        guard reading.state == .discharging, let current = reading.current, let capacity = reading.remainingCapacity
        else {
            endStretch()
            return reading.minutesRemaining
        }
        if let last, now.timeIntervalSince(last.time) > Self.gap || now < last.time { endStretch() }

        let amps = max(Double(-current), 0) / 1000
        let dt = last.map { now.timeIntervalSince($0.time) } ?? 0
        short = Self.average(short, amps, dt: dt, window: Self.shortWindow)
        long = Self.average(long, amps, dt: dt, window: Self.longWindow)
        if stretchStart == nil {
            stretchStart = now
            choice = trusted
        }
        last = (now, capacity)

        let x = features(lowPower: reading.isLowPowerMode, at: now)
        if pending.last.map({ now.timeIntervalSince($0.time) >= 60 }) ?? true {
            label(matured: Self.horizon, capacity: capacity, at: now)
            pending.append(
                Pending(time: now, features: x, capacity: capacity, predictions: predictions(x, instant: amps)))
        }

        guard now.timeIntervalSince(stretchStart!) >= Self.warmUp, let choice else {
            shown = nil
            return reading.minutesRemaining
        }
        let predicted = predictions(x, instant: amps)[choice]!
        // Below 50 mA the Mac is all but asleep; dividing by less invents days.
        let estimate = Double(capacity) / (max(predicted, 0.05) * 1000) * 60
        return Int(show(estimate, at: now).rounded())
    }

    /// The predictor with the lowest error so far, once there's enough to judge; nil defers to macOS.
    /// If macOS's own method is doing best, its own figure is shown.
    private var trusted: Predictor? {
        guard state.labels >= Self.trustAfter else { return nil }
        let best = Predictor.allCases.min {
            state.errors[$0, default: .infinity] < state.errors[$1, default: .infinity]
        }
        return best == .instant ? nil : best
    }

    private func features(lowPower: Bool, at time: Date) -> [Double] {
        let hour =
            Double(Calendar.current.component(.hour, from: time))
            + Double(Calendar.current.component(.minute, from: time)) / 60
        let angle = hour / 24 * 2 * .pi
        return [1, short ?? 0, long ?? 0, sin(angle), cos(angle), lowPower ? 1 : 0]
    }

    private func predictions(_ x: [Double], instant: Double) -> [Predictor: Double] {
        [.model: state.model.predict(x), .trend: long ?? instant, .instant: instant]
    }

    /// A time-weighted moving average, so irregular readings (every minute, or every two
    /// seconds while the menu is open) weigh what they cover.
    private static func average(_ previous: Double?, _ value: Double, dt: TimeInterval, window: TimeInterval) -> Double
    {
        guard let previous else { return value }
        return previous + (1 - exp(-dt / window)) * (value - previous)
    }

    /// Scores and learns from every pending minute at least `age` old, using what the battery
    /// actually lost since: the gauge's own count of charge, not a sum of noisy current readings.
    private mutating func label(matured age: TimeInterval, capacity: Int, at now: Date) {
        while let first = pending.first, now.timeIntervalSince(first.time) >= age {
            pending.removeFirst()
            let hours = now.timeIntervalSince(first.time) / 3600
            let amps = Double(first.capacity - capacity) / hours / 1000
            // A recalibrating gauge can jump; a figure like that teaches nothing.
            guard (0...10).contains(amps) else { continue }
            for (predictor, predicted) in first.predictions {
                let error = abs(predicted - amps)
                // Averaged over about 100 labelled minutes: a single steady hour, which flatters
                // the instant reading, shouldn't decide which method is better.
                state.errors[predictor] = state.errors[predictor].map { $0 + 0.01 * (error - $0) } ?? error
            }
            state.labels += 1
            state.model.learn(first.features, amps)
        }
    }

    private mutating func endStretch() {
        if let last { label(matured: Self.shortestLabel, capacity: last.capacity, at: last.time) }
        pending.removeAll()
        short = nil
        long = nil
        last = nil
        stretchStart = nil
        choice = nil
        shown = nil
    }

    /// Counts down from what was shown, and eases toward the new estimate no faster than `drift`.
    private mutating func show(_ estimate: Double, at now: Date) -> Double {
        guard let shown else {
            self.shown = (now, estimate)
            return estimate
        }
        let elapsed = now.timeIntervalSince(shown.time)
        let countdown = max(shown.minutes - elapsed / 60, 0)
        let step = (1 - exp(-elapsed / Self.settle)) * (estimate - countdown)
        let limit = max(countdown, 30) * Self.drift * elapsed / 60
        let minutes = countdown + min(max(step, -limit), limit)
        self.shown = (now, minutes)
        return minutes
    }
}
