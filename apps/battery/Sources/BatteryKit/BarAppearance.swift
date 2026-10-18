import Foundation

/// One of the things the menu bar item can show. Each is optional and the order is the user's.
public enum BarPart: String, Codable, CaseIterable, Identifiable, Sendable {
    case battery, percent, time

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .battery: "Battery Icon"
        case .percent: "Percentage"
        case .time: "Time Remaining"
        }
    }

    public var symbol: String {
        switch self {
        case .battery: "battery.75percent"
        case .percent: "percent"
        case .time: "clock"
        }
    }
}

/// How the battery icon is drawn.
public enum IconStyle: String, Codable, CaseIterable, Sendable {
    case plain, percentInside

    public var name: String {
        switch self {
        case .plain: "Icon"
        case .percentInside: "Percentage in Icon"
        }
    }
}

/// What the menu bar item shows: some of the parts, left to right, and how they're drawn.
public struct BarAppearance: Equatable, Sendable {
    /// Left to right, each at most once, never empty: an item with nothing in it can't be found or clicked.
    public private(set) var parts: [BarPart]
    public var iconStyle: IconStyle
    /// Red when low, yellow in Low Power Mode, as the system's own battery icon does.
    public var colorsAlerts: Bool

    public init(parts: [BarPart], iconStyle: IconStyle = .plain, colorsAlerts: Bool = true) {
        var seen = Set<BarPart>()
        let unique = parts.filter { seen.insert($0).inserted }
        self.parts = unique.isEmpty ? Self.standard.parts : unique
        self.iconStyle = iconStyle
        self.colorsAlerts = colorsAlerts
    }

    /// The percentage beside the icon, as the system's battery shows it.
    public static let standard = BarAppearance(parts: [.percent, .battery])

    /// The parts not in the menu bar, in their natural order.
    public var hidden: [BarPart] { BarPart.allCases.filter { !parts.contains($0) } }

    /// The last part stays: removing it is refused.
    public var canRemove: Bool { parts.count > 1 }

    public mutating func remove(_ part: BarPart) {
        guard canRemove else { return }
        parts.removeAll { $0 == part }
    }

    /// Puts `part` at `index` among the shown parts, adding it if it was hidden. The index counts
    /// positions once `part` has left its old place, so it's clamped to the ends.
    public mutating func place(_ part: BarPart, at index: Int) {
        parts.removeAll { $0 == part }
        parts.insert(part, at: min(max(index, 0), parts.count))
    }

    // MARK: Storage

    /// The stored form: part names, left to right.
    public var storedParts: [String] { parts.map(\.rawValue) }

    /// Reads what was saved. Before parts could be arranged, the item had a style and a time
    /// toggle (`style`, `showsTime`); an install that saved only those keeps what it showed.
    /// Names this version doesn't know are skipped, and nothing usable falls back to the standard.
    public static func restored(
        parts stored: [String]?, iconStyle: String?, legacyStyle: String?, legacyShowsTime: Bool, colorsAlerts: Bool
    ) -> BarAppearance {
        let inside = iconStyle.flatMap(IconStyle.init) ?? (legacyStyle == "percentInIcon" ? .percentInside : .plain)
        if let stored {
            return BarAppearance(parts: stored.compactMap(BarPart.init), iconStyle: inside, colorsAlerts: colorsAlerts)
        }
        // The old layout drew the time first, then the percentage, then the icon.
        var parts: [BarPart] = legacyShowsTime ? [.time] : []
        switch legacyStyle {
        case "icon", "percentInIcon": parts.append(.battery)
        case "percent": parts.append(.percent)
        default: parts += [.percent, .battery]
        }
        return BarAppearance(parts: parts, iconStyle: inside, colorsAlerts: colorsAlerts)
    }
}
