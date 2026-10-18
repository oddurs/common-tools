import Foundation
import Testing

@testable import CommonKit

@Suite struct StatusItemTests {
    @Test func everyAppStartsRightOfCommonBarsDivider() {
        // Bar's divider sits about 580 points from the right edge; anything right of it is visible.
        let positions = CommonTool.all.map(\.startingPosition)
        #expect(Set(positions).count == positions.count)
        #expect(positions.allSatisfy { $0 > 0 && $0 < 400 })
    }

    @Test func seedsOnlyAPositionTheUserHasNotMade() throws {
        let defaults = try #require(UserDefaults(suiteName: "StatusItemTests-\(UUID())"))
        let key = "NSStatusItem Preferred Position test"
        StatusItemPosition.seed("test", at: 140, in: defaults)
        #expect(defaults.double(forKey: key) == 140)
        defaults.set(912, forKey: key)
        StatusItemPosition.seed("test", at: 140, in: defaults)
        #expect(defaults.double(forKey: key) == 912)
    }
}
