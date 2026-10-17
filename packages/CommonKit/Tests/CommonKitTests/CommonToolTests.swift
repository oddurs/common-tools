import Foundation
import Testing

@testable import CommonKit

@Suite struct CommonToolTests {
    @Test func everyToolIsDistinct() {
        let ids = CommonTool.all.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(Set(CommonTool.all.map(\.bundleIdentifier)).count == ids.count)
    }

    @Test func everyToolHasAFamilyIcon() throws {
        // shared/CommonTools, two directories up from this package, is what the build copies into each app.
        let shared = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "shared/CommonTools")
        for tool in CommonTool.all {
            let icon = shared.appending(path: "\(tool.id).png")
            #expect(FileManager.default.fileExists(atPath: icon.path), "no family icon for \(tool.id)")
        }
    }

    @Test func pagesAreOnTheSite() {
        for tool in CommonTool.all {
            #expect(tool.page.absoluteString == "https://oddurs.github.io/common-tools/\(tool.id)/")
        }
    }
}
