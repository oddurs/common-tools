import Foundation
import Testing

@testable import ShotKit

@Suite struct FileNameTests {
    @Test func namesFollowMacOSScreenshots() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        let date = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 9, minute: 5, second: 2)))
        #expect(FileName.forShot(at: date, calendar: calendar) == "Common Shot 2026-03-07 at 09.05.02.png")
    }

    @Test func aTakenNameGetsANumber() {
        let taken: Set = ["a.png", "a 2.png"]
        #expect(FileName.unique("a.png") { taken.contains($0) } == "a 3.png")
        #expect(FileName.unique("b.png") { taken.contains($0) } == "b.png")
    }
}
