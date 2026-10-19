import Foundation
import Testing

@testable import ShotKit

@Suite struct ShelfTests {
    /// Weeks start on Monday, in UTC, in English, whatever this Mac says.
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }()

    /// Friday 16 October 2026, 15:00 UTC.
    let now = Date(timeIntervalSince1970: 1_792_162_800)

    func hoursAgo(_ hours: Double) -> Date { now.addingTimeInterval(-hours * 3600) }

    @Test func periodsFollowTheCalendar() {
        #expect(Shelf.period(of: hoursAgo(1), now: now, calendar: calendar) == .today)
        #expect(Shelf.period(of: hoursAgo(14), now: now, calendar: calendar) == .today)  // 01:00 today
        #expect(Shelf.period(of: hoursAgo(16), now: now, calendar: calendar) == .yesterday)  // 23:00 Thursday
        #expect(Shelf.period(of: hoursAgo(50), now: now, calendar: calendar) == .thisWeek)  // Wednesday
        #expect(Shelf.period(of: hoursAgo(110), now: now, calendar: calendar) == .thisWeek)  // 01:00 Monday
        #expect(Shelf.period(of: hoursAgo(120), now: now, calendar: calendar) == .older)  // Sunday, last week
    }

    @Test func aMondayHasNoEarlierThisWeek() {
        let monday = Date(timeIntervalSince1970: 1_791_817_200)  // Monday 12 October 2026, 15:00 UTC
        let sunday = monday.addingTimeInterval(-26 * 3600)
        let saturday = monday.addingTimeInterval(-40 * 3600)
        #expect(Shelf.period(of: sunday, now: monday, calendar: calendar) == .yesterday)
        #expect(Shelf.period(of: saturday, now: monday, calendar: calendar) == .older)
    }

    @Test func groupsAreNewestFirstAndSkipEmptyPeriods() {
        let dates = [hoursAgo(120), hoursAgo(1), hoursAgo(200), hoursAgo(2)]
        let groups = Shelf.groups(of: dates, now: now, calendar: calendar)
        #expect(groups.map(\.period) == [.today, .older])
        #expect(groups[0].indices == [1, 3])
        #expect(groups[1].indices == [0, 2])
    }

    @Test func labelsSayOnlyWhatTheHeaderDoesnt() {
        // ICU puts a narrow no-break space before PM.
        #expect(Shelf.when(hoursAgo(1), in: .today, now: now, calendar: calendar) == "2:00\u{202F}PM")
        #expect(Shelf.when(hoursAgo(50), in: .thisWeek, now: now, calendar: calendar) == "Wed 1:00\u{202F}PM")
        #expect(Shelf.when(hoursAgo(120), in: .older, now: now, calendar: calendar) == "Oct 11")
        let lastYear = now.addingTimeInterval(-400 * 86400)
        #expect(Shelf.when(lastYear, in: .older, now: now, calendar: calendar) == "Sep 11, 2025")
    }

    @Test func leftAndRightWalkTheOrderAcrossGroups() {
        let sizes = [3, 2]
        #expect(Shelf.move(.right, from: 2, sizes: sizes, columns: 2) == 3)
        #expect(Shelf.move(.left, from: 3, sizes: sizes, columns: 2) == 2)
        #expect(Shelf.move(.left, from: 0, sizes: sizes, columns: 2) == 0)
        #expect(Shelf.move(.right, from: 4, sizes: sizes, columns: 2) == 4)
    }

    @Test func upAndDownKeepTheColumnAcrossGroups() {
        // Today: [0 1] [2]; Older: [3 4].
        let sizes = [3, 2]
        #expect(Shelf.move(.down, from: 1, sizes: sizes, columns: 2) == 2)  // onto the short row's only shot
        #expect(Shelf.move(.down, from: 2, sizes: sizes, columns: 2) == 3)
        #expect(Shelf.move(.up, from: 4, sizes: sizes, columns: 2) == 2)
        #expect(Shelf.move(.up, from: 1, sizes: sizes, columns: 2) == 1)  // the top row stays
        #expect(Shelf.move(.down, from: 4, sizes: sizes, columns: 2) == 4)
    }

    @Test func anyArrowStartsAtTheFirstShot() {
        #expect(Shelf.move(.down, from: nil, sizes: [2], columns: 2) == 0)
        #expect(Shelf.move(.left, from: nil, sizes: [], columns: 2) == nil)
    }
}
