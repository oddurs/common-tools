import ColorKit
import CommonShortcut
import Foundation

/// Every setting, saved to UserDefaults as it changes.
@MainActor @Observable
final class Preferences {
    private let defaults: UserDefaults

    var hotKey: KeyCombo { didSet { defaults.set(try? JSONEncoder().encode(hotKey), forKey: "hotKey") } }
    var format: ColorFormat { didSet { defaults.set(format.rawValue, forKey: "format") } }
    /// Whether the panel lists every format under the default one, or keeps them a click away.
    var showsAllFormats: Bool { didSet { defaults.set(showsAllFormats, forKey: "showsAllFormats") } }
    /// A moment's card after each copy, saying what went to the clipboard.
    var confirmsCopies: Bool { didSet { defaults.set(confirmsCopies, forKey: "confirmsCopies") } }

    /// ⌃⇧⌘C: C for colour, and free on a stock Mac.
    static let standardHotKey = KeyCombo(keyCode: 8, modifiers: [.control, .shift, .command])

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: ["confirmsCopies": true])
        hotKey =
            defaults.data(forKey: "hotKey").flatMap { try? JSONDecoder().decode(KeyCombo.self, from: $0) }
            ?? Self.standardHotKey
        format = defaults.string(forKey: "format").flatMap(ColorFormat.init) ?? .hex
        showsAllFormats = defaults.bool(forKey: "showsAllFormats")
        confirmsCopies = defaults.bool(forKey: "confirmsCopies")
    }
}
