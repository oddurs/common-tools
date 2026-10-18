import Foundation
import ShotKit

/// Every setting, saved to UserDefaults as it changes.
@MainActor @Observable
final class Preferences {
    private let defaults: UserDefaults

    var hotKey: KeyCombo { didSet { defaults.set(try? JSONEncoder().encode(hotKey), forKey: "hotKey") } }
    var imageSize: ImageSize { didSet { defaults.set(imageSize.rawValue, forKey: "imageSize") } }
    var historyLimit: Int { didSet { defaults.set(historyLimit, forKey: "historyLimit") } }
    var showsPreview: Bool { didSet { defaults.set(showsPreview, forKey: "showsPreview") } }
    var playsSound: Bool { didSet { defaults.set(playsSound, forKey: "playsSound") } }
    var showsMenuBarItem: Bool { didSet { defaults.set(showsMenuBarItem, forKey: "showsMenuBarItem") } }

    /// How many shots the menu can offer again. Zero keeps none.
    static let historyLimits = [0, 5, 10, 25, 50, 100]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            "historyLimit": 10, "showsPreview": true, "playsSound": true, "showsMenuBarItem": true,
        ])
        hotKey =
            defaults.data(forKey: "hotKey").flatMap { try? JSONDecoder().decode(KeyCombo.self, from: $0) } ?? .standard
        imageSize = defaults.string(forKey: "imageSize").flatMap(ImageSize.init) ?? .prompt
        historyLimit = max(0, defaults.integer(forKey: "historyLimit"))
        showsPreview = defaults.bool(forKey: "showsPreview")
        playsSound = defaults.bool(forKey: "playsSound")
        showsMenuBarItem = defaults.bool(forKey: "showsMenuBarItem")
    }
}
