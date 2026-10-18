import Testing

@testable import CommonKit

@Suite struct CommonToolsSectionTests {
    @Test @MainActor func thePromiseIsWordForWord() {
        // The site and the READMEs make the same promise; the apps make it in these words.
        #expect(
            CommonToolsSection.promise
                == "Free and open source, forever. Nothing you do is ever reported; nothing leaves your Mac.")
    }

    @Test func aReleaseShowsItsVersionAlone() {
        #expect(CommonToolsSection.versionLine(name: "Common Bar", version: "0.4.0", commit: nil) == "Common Bar 0.4.0")
        #expect(CommonToolsSection.versionLine(name: "Common Bar", version: "0.4.0", commit: "") == "Common Bar 0.4.0")
    }

    @Test func aDevelopmentBuildShowsItsCommit() {
        let sha = "1a2b3c4d5e6f708192a3b4c5d6e7f8091a2b3c4d"
        #expect(
            CommonToolsSection.versionLine(name: "Common Bar", version: "0.4.0", commit: sha)
                == "Common Bar 0.4.0 (1a2b3c4)")
        #expect(
            CommonToolsSection.versionLine(name: "Common Bar", version: "0.4.0", commit: "\(sha)-dirty")
                == "Common Bar 0.4.0 (1a2b3c4-dirty)")
    }
}
