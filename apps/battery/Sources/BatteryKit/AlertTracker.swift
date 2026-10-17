/// Decides when to notify. Each alert fires once as the level crosses its threshold, not every
/// minute it stays past it.
public struct AlertTracker: Sendable {
    public enum Alert: Sendable, Equatable {
        case low(percent: Int)
        case charged(percent: Int)
    }

    // Nil until the first reading. Conditions already true at launch don't fire: the user
    // doesn't need telling that the battery they just looked at is charged.
    private var lowArmed: Bool?
    private var chargedArmed: Bool?

    public init() {}

    /// `low` and `charged` are thresholds in percent; nil turns that alert off.
    public mutating func update(_ reading: BatteryReading?, low: Int?, charged: Int?) -> [Alert] {
        guard let reading else { return [] }
        var alerts: [Alert] = []
        // Low re-arms whenever the condition lapses, including a moment on power: unplugging at
        // 15% is worth a warning even if the last one was minutes ago.
        let lowMet = low.map { reading.state == .discharging && reading.percent <= $0 } ?? false
        if lowMet, lowArmed == true { alerts.append(.low(percent: reading.percent)) }
        lowArmed = !lowMet
        // Charged re-arms only below the threshold, so plugging back in above it stays quiet.
        if let charged, reading.isOnPower, reading.percent >= charged, chargedArmed == true {
            alerts.append(.charged(percent: reading.percent))
        }
        chargedArmed = charged.map { reading.percent < $0 } ?? false
        return alerts
    }
}
