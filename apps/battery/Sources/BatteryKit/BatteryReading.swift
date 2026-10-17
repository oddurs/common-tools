import Foundation

/// One look at the internal battery. The level, state, and time come from IOKit's power sources,
/// the same source as the system's own battery menu and `pmset -g batt`. The rest comes from the
/// AppleSmartBattery registry entry and is nil when the hardware doesn't publish it.
public struct BatteryReading: Sendable, Equatable {
    public enum State: Sendable, Equatable {
        case charging
        /// On power and full.
        case charged
        /// On power but holding: Optimized Charging, a charge limit, or an adapter too weak to charge.
        case notCharging
        case discharging
    }

    /// 0...1, as the system rounds it.
    public var level: Double
    public var state: State
    /// Minutes to empty while discharging, or to full while charging; nil while macOS is still estimating.
    public var minutesRemaining: Int?
    public var isLowPowerMode: Bool
    /// The adapter's rating, while one is connected.
    public var adapterWatts: Int?

    public var cycleCount: Int?
    /// The cycle count the battery is rated for.
    public var designCycleCount: Int?
    /// What a full charge holds now, in mAh.
    public var fullChargeCapacity: Int?
    /// What a full charge held when new, in mAh.
    public var designCapacity: Int?
    /// Degrees Celsius.
    public var temperature: Double?
    /// Power into the battery in watts: positive while charging, negative while discharging.
    public var watts: Double?
    /// Current into the battery in mA, signed like `watts`; the gauge averages it over seconds.
    public var current: Int?
    /// What the battery holds now, in mAh.
    public var remainingCapacity: Int?

    public init(
        level: Double, state: State, minutesRemaining: Int? = nil, isLowPowerMode: Bool = false,
        adapterWatts: Int? = nil, cycleCount: Int? = nil, designCycleCount: Int? = nil,
        fullChargeCapacity: Int? = nil, designCapacity: Int? = nil, temperature: Double? = nil, watts: Double? = nil,
        current: Int? = nil, remainingCapacity: Int? = nil
    ) {
        self.level = level
        self.state = state
        self.minutesRemaining = minutesRemaining
        self.isLowPowerMode = isLowPowerMode
        self.adapterWatts = adapterWatts
        self.cycleCount = cycleCount
        self.designCycleCount = designCycleCount
        self.fullChargeCapacity = fullChargeCapacity
        self.designCapacity = designCapacity
        self.temperature = temperature
        self.watts = watts
        self.current = current
        self.remainingCapacity = remainingCapacity
    }

    public var percent: Int { Int((min(max(level, 0), 1) * 100).rounded()) }

    public var isOnPower: Bool { state != .discharging }

    /// The level at which the bar turns red, as on iPhone. Only while discharging: a low battery
    /// that is charging needs no warning.
    public static let lowLevel = 20

    public var isLow: Bool { state == .discharging && percent <= Self.lowLevel }
}
