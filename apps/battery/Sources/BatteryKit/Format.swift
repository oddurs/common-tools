import Foundation

public enum Format {
    /// What a value that can't be read shows, never a made-up zero.
    public static let missing = "–"

    public static func percent(_ value: Int) -> String { "\(value)%" }

    /// "2:41", as the system's battery menu writes time remaining.
    public static func duration(minutes: Int) -> String {
        guard minutes >= 0 else { return missing }
        return "\(minutes / 60):" + String(format: "%02d", minutes % 60)
    }

    /// "12.4 W" or "12,4 W", as the user's region writes it.
    public static func watts(_ value: Double, locale: Locale = .autoupdatingCurrent) -> String {
        guard value.isFinite else { return missing }
        return abs(value).formatted(.number.precision(.fractionLength(1)).locale(locale)) + " W"
    }

    /// Celsius or Fahrenheit, as the user's region prefers.
    public static func temperature(celsius: Double, locale: Locale = .autoupdatingCurrent) -> String {
        guard celsius.isFinite else { return missing }
        return Measurement(value: celsius, unit: UnitTemperature.celsius).formatted(
            .measurement(width: .abbreviated, usage: .weather, numberFormatStyle: .number.precision(.fractionLength(0)))
                .locale(locale))
    }

    public static func count(_ value: Int, locale: Locale = .autoupdatingCurrent) -> String {
        value.formatted(.number.locale(locale))
    }

    /// One line for what the battery is doing: "2:41 remaining", "Charging", "Charged".
    public static func status(_ reading: BatteryReading) -> String {
        let time = reading.minutesRemaining.map { duration(minutes: $0) }
        switch reading.state {
        case .charging: return time.map { "\($0) until full" } ?? "Charging"
        case .charged: return "Charged"
        case .notCharging: return "Not charging"
        case .discharging: return time.map { "\($0) remaining" } ?? "Calculating…"
        }
    }
}
