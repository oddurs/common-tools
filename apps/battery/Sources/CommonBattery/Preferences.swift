import BatteryKit
import Foundation

/// Every setting, saved to UserDefaults as it changes.
@MainActor @Observable
final class Preferences {
    private let defaults: UserDefaults

    /// The parts go under `barParts` and the icon's look under `iconStyle`. `style` and
    /// `showsTime`, from before the parts could be arranged, count only while `barParts` is
    /// missing, so an install keeps what it showed. They're never written again.
    var appearance: BarAppearance {
        didSet {
            defaults.set(appearance.storedParts, forKey: "barParts")
            defaults.set(appearance.iconStyle.rawValue, forKey: "iconStyle")
            defaults.set(appearance.colorsAlerts, forKey: "colorsAlerts")
        }
    }
    /// Percent; 0 is off.
    var lowAlert: Int { didSet { defaults.set(lowAlert, forKey: "lowAlert") } }
    /// Percent; 0 is off.
    var chargedAlert: Int { didSet { defaults.set(chargedAlert, forKey: "chargedAlert") } }

    static let lowAlerts = [0, 10, 15, 20, 30]
    static let chargedAlerts = [0, 80, 90, 100]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            "colorsAlerts": BarAppearance.standard.colorsAlerts, "lowAlert": 20, "chargedAlert": 0,
        ])
        appearance = BarAppearance.restored(
            parts: defaults.stringArray(forKey: "barParts"), iconStyle: defaults.string(forKey: "iconStyle"),
            legacyStyle: defaults.string(forKey: "style"), legacyShowsTime: defaults.bool(forKey: "showsTime"),
            colorsAlerts: defaults.bool(forKey: "colorsAlerts"))
        lowAlert = defaults.integer(forKey: "lowAlert")
        chargedAlert = defaults.integer(forKey: "chargedAlert")
    }

    var notifies: Bool { lowAlert > 0 || chargedAlert > 0 }
}
