import Foundation

public enum FileName {
    /// "Common Shot 2026-10-16 at 14.03.22.png", in the pattern of macOS's own screenshots, so a folder of
    /// them sorts by time. Dots, not colons, because Finder shows a colon in a name as a slash.
    public static func forShot(at date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        func two(_ n: Int?) -> String { n.map { $0 < 10 ? "0\($0)" : "\($0)" } ?? "00" }
        return
            "Common Shot \(c.year ?? 0)-\(two(c.month))-\(two(c.day)) at \(two(c.hour)).\(two(c.minute)).\(two(c.second)).png"
    }

    /// `name`, or "name 2.png", "name 3.png"… when a shot in the same second already took it.
    public static func unique(_ name: String, existing: (String) -> Bool) -> String {
        guard existing(name) else { return name }
        let stem = name.hasSuffix(".png") ? String(name.dropLast(4)) : name
        var n = 2
        while existing("\(stem) \(n).png") { n += 1 }
        return "\(stem) \(n).png"
    }
}
