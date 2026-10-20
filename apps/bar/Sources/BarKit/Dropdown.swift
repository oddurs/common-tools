import Foundation

/// What a folder's dropdown shows and how the keyboard moves through it. Pure, so every rule is tested
/// without a panel.
public enum Dropdown {
    /// A row's status line, when Accessibility already gives one for free: what macOS's own items say
    /// after their name ("Wi‑Fi, connected, 3 bars" → "connected, 3 bars"). Nil otherwise.
    public static func status(of owner: AccessibleItem) -> String? {
        guard owner.bundleID?.hasPrefix("com.apple.") == true, let label = owner.label,
            let comma = label.firstIndex(of: ",")
        else { return nil }
        let rest = label[label.index(after: comma)...].trimmingCharacters(in: .whitespaces)
        return rest.isEmpty ? nil : rest
    }

    /// The SF Symbol for one of macOS's own menu bar items, which all belong to Control Center or
    /// another agent and so share its icon. By the item's identifier, or its name when it has none.
    public static func symbol(identifier: String?, name: String) -> String? {
        let key = (identifier?.split(separator: ".").last.map(String.init) ?? name).lowercased()
        let symbols: [(String, String)] = [
            ("wifi", "wifi"), ("wi‑fi", "wifi"), ("battery", "battery.100percent"), ("bluetooth", "bluetooth"),
            ("now-playing", "play.circle"), ("now playing", "play.circle"), ("focusmode", "moon"),
            ("focus", "moon"), ("sound", "speaker.wave.2"), ("volume", "speaker.wave.2"),
            ("display", "sun.max"), ("controlcenter", "switch.2"), ("control center", "switch.2"),
            ("clock", "clock"), ("search", "magnifyingglass"), ("spotlight", "magnifyingglass"),
            ("siri", "waveform"), ("airdrop", "dot.radiowaves.left.and.right"),
            ("screenmirroring", "rectangle.on.rectangle"), ("keyboardbrightness", "light.max"),
            ("textinput", "keyboard"), ("timemachine", "clock.arrow.circlepath"),
            ("vpn", "network.badge.shield.half.filled"),
            ("user", "person.crop.circle"), ("stagemanager", "rectangle.split.3x1"),
        ]
        return symbols.first { $0.0 == key }?.1
    }

    /// Whether a row matches what was typed: every word of the query is in its name or status,
    /// ignoring case and accents, in any order.
    public static func matches(_ query: String, name: String, status: String?) -> Bool {
        let haystack = [name, status ?? ""].joined(separator: " ").folding(
            options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        return query.split(separator: " ").allSatisfy {
            haystack.contains(String($0).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil))
        }
    }

    /// The keyboard's place in a list of `count` rows: none until the first arrow, then clamped to the
    /// ends, as a menu does.
    public struct Selection: Equatable, Sendable {
        public private(set) var index: Int?

        public init(index: Int? = nil) {
            self.index = index
        }

        /// Down from nothing selects the first row; up from nothing, the last.
        public mutating func move(by offset: Int, count: Int) {
            guard count > 0 else {
                index = nil
                return
            }
            guard let index else {
                self.index = offset > 0 ? 0 : count - 1
                return
            }
            self.index = min(max(index + offset, 0), count - 1)
        }

        /// After the list changes: keeps the place if it still exists, or the first row while a filter
        /// is typed, so Return opens the best match.
        public mutating func settle(count: Int, filtering: Bool) {
            if count == 0 {
                index = nil
            } else if filtering {
                index = 0
            } else if let index, index >= count {
                self.index = count - 1
            }
        }
    }
}
