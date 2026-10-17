import BatteryKit
import Foundation

/// Every setting, saved to UserDefaults as it changes.
@MainActor @Observable
final class Preferences {
    private let defaults: UserDefaults

    var style: BarStyle { didSet { defaults.set(style.rawValue, forKey: "style") } }
    var showsTime: Bool { didSet { defaults.set(showsTime, forKey: "showsTime") } }
    var colorsAlerts: Bool { didSet { defaults.set(colorsAlerts, forKey: "colorsAlerts") } }
    /// Percent; 0 is off.
    var lowAlert: Int { didSet { defaults.set(lowAlert, forKey: "lowAlert") } }
    /// Percent; 0 is off.
    var chargedAlert: Int { didSet { defaults.set(chargedAlert, forKey: "chargedAlert") } }

    static let lowAlerts = [0, 10, 15, 20, 30]
    static let chargedAlerts = [0, 80, 90, 100]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let standard = BarAppearance.standard
        defaults.register(defaults: [
            "showsTime": standard.showsTime, "colorsAlerts": standard.colorsAlerts, "lowAlert": 20, "chargedAlert": 0,
        ])
        style = defaults.string(forKey: "style").flatMap(BarStyle.init) ?? standard.style
        showsTime = defaults.bool(forKey: "showsTime")
        colorsAlerts = defaults.bool(forKey: "colorsAlerts")
        lowAlert = defaults.integer(forKey: "lowAlert")
        chargedAlert = defaults.integer(forKey: "chargedAlert")
    }

    var appearance: BarAppearance { BarAppearance(style: style, showsTime: showsTime, colorsAlerts: colorsAlerts) }

    var notifies: Bool { lowAlert > 0 || chargedAlert > 0 }
}
