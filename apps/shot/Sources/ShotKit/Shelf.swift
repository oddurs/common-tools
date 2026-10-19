import Foundation

/// How the history panel arranges past shots: grouped by when they were taken, labelled so a group
/// doesn't repeat what its header says, and walked with the arrow keys as the grid shows them.
public enum Shelf {
    /// A group's place in time, newest first. Each is a header in the panel.
    public enum Period: Int, CaseIterable, Sendable, Comparable {
        case today, yesterday, thisWeek, older

        public var title: String {
            switch self {
            case .today: "Today"
            case .yesterday: "Yesterday"
            case .thisWeek: "Earlier This Week"
            case .older: "Older"
            }
        }

        public static func < (a: Period, b: Period) -> Bool { a.rawValue < b.rawValue }
    }

    public struct Group: Equatable, Sendable {
        public let period: Period
        /// Indices into the dates passed to `groups`, newest first.
        public let indices: [Int]
    }

    /// Where `date` falls, seen from `now`. The week is the calendar's, so it starts on the user's
    /// first weekday; a Monday has no "Earlier This Week" when the week starts on Monday.
    public static func period(of date: Date, now: Date, calendar: Calendar = .current) -> Period {
        if calendar.isDate(date, inSameDayAs: now) { return .today }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
            calendar.isDate(date, inSameDayAs: yesterday)
        {
            return .yesterday
        }
        if let week = calendar.dateInterval(of: .weekOfYear, for: now), week.contains(date), date < now {
            return .thisWeek
        }
        return .older
    }

    /// `dates` grouped by period, groups and shots newest first, empty groups left out.
    public static func groups(of dates: [Date], now: Date, calendar: Calendar = .current) -> [Group] {
        let order = dates.indices.sorted { dates[$0] > dates[$1] }
        var byPeriod: [Period: [Int]] = [:]
        for index in order {
            byPeriod[period(of: dates[index], now: now, calendar: calendar), default: []].append(index)
        }
        return Period.allCases.compactMap { period in byPeriod[period].map { Group(period: period, indices: $0) } }
    }

    /// When a shot was taken, as much as its group doesn't already say: the time today and yesterday,
    /// the weekday and time earlier this week, the date before that, with the year once it isn't this one.
    public static func when(_ date: Date, in period: Period, now: Date, calendar: Calendar = .current) -> String {
        var style = Date.FormatStyle(timeZone: calendar.timeZone)
        style.calendar = calendar
        style.locale = calendar.locale ?? .current
        switch period {
        case .today, .yesterday:
            return date.formatted(style.hour().minute())
        case .thisWeek:
            return date.formatted(style.weekday(.abbreviated).hour().minute())
        case .older:
            let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: now)
            return date.formatted(sameYear ? style.month(.abbreviated).day() : style.month(.abbreviated).day().year())
        }
    }

    /// Arrow keys over the grid, which lays each group out in rows of `columns`.
    public enum Move: Sendable {
        case left, right, up, down
    }

    /// The shot an arrow key selects, from `current` (a position in the panel's order: each group's
    /// shots in turn), in groups of these `sizes`. Left and right step through the order, across groups;
    /// up and down keep the column, landing on a shorter row's last shot, and stop at the ends. With
    /// nothing selected, any arrow selects the first shot.
    public static func move(_ move: Move, from current: Int?, sizes: [Int], columns: Int) -> Int? {
        let count = sizes.reduce(0, +)
        guard count > 0, columns > 0 else { return nil }
        guard let current, current >= 0, current < count else { return 0 }
        switch move {
        case .left: return max(current - 1, 0)
        case .right: return min(current + 1, count - 1)
        case .up, .down:
            // Every row of the grid as (first position, length), top to bottom.
            var rows: [(start: Int, length: Int)] = []
            var start = 0
            for size in sizes {
                for offset in stride(from: 0, to: size, by: columns) {
                    rows.append((start + offset, min(columns, size - offset)))
                }
                start += size
            }
            guard let row = rows.firstIndex(where: { current >= $0.start && current < $0.start + $0.length })
            else { return current }
            let column = current - rows[row].start
            let target = move == .up ? row - 1 : row + 1
            guard rows.indices.contains(target) else { return current }
            return rows[target].start + min(column, rows[target].length - 1)
        }
    }
}
