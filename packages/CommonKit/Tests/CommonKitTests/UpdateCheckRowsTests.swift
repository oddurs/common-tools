import Foundation
import Testing

@testable import CommonKit

/// The Settings rows every app draws for `UpdateCheck`: what the toggle does and what the footnote
/// says, without a window.
@MainActor @Suite struct UpdateCheckRowsTests {
    private func check(fetch: @escaping UpdateCheck.Fetch) -> UpdateCheck {
        UpdateCheck(
            tool: UpdateCheckTests.bar, current: Version(0, 4, 0), defaults: UpdateCheckTests.defaults(), fetch: fetch)
    }

    @Test func turningTheToggleOnRecordsItAndChecksAtOnce() async {
        let fetched = Counter()
        let check = check { _ in
            await fetched.bump()
            return UpdateCheckTests.list(UpdateCheckTests.release("bar-v0.5.0"))
        }
        #expect(UpdateCheckToggle.label == "Check for updates daily")

        await UpdateCheckToggle.apply(true, to: check)?.value
        #expect(check.isEnabled)
        #expect(await fetched.count == 1)
        #expect(check.available?.version == Version(0, 5, 0))

        // The same value again does nothing, as a toggle redrawn with the state it already has.
        #expect(UpdateCheckToggle.apply(true, to: check) == nil)
        #expect(await fetched.count == 1)

        await UpdateCheckToggle.apply(false, to: check)?.value
        #expect(!check.isEnabled)
        #expect(await fetched.count == 1)
    }

    @Test func footnoteNamesTheVersionAndLinksToTheDownload() async throws {
        let check = check { _ in UpdateCheckTests.list(UpdateCheckTests.release("bar-v0.5.0")) }
        #expect(UpdateCheckFootnote.content(of: check) == nil)
        try await check.check()
        let download = URL(string: "https://github.com/oddurs/common-tools/releases/download/bar-v0.5.0/CommonBar.zip")!
        #expect(UpdateCheckFootnote.content(of: check) == .available("Version 0.5.0 is available", download))
    }

    @Test func footnoteFallsBackToTheReleasePageWithoutAZip() async throws {
        let check = check { _ in UpdateCheckTests.list(UpdateCheckTests.release("bar-v0.5.0", assets: [])) }
        try await check.check()
        let page = URL(string: "https://github.com/oddurs/common-tools/releases/tag/bar-v0.5.0")!
        #expect(UpdateCheckFootnote.content(of: check) == .available("Version 0.5.0 is available", page))
    }

    @Test func footnoteShowsWhyTheLastCheckFailed() async {
        let check = check { _ in throw URLError(.notConnectedToInternet) }
        check.isEnabled = true
        await check.checkIfDue()
        let error = URLError(.notConnectedToInternet).localizedDescription
        #expect(UpdateCheckFootnote.content(of: check) == .problem(error))
    }
}

private actor Counter {
    private(set) var count = 0
    func bump() { count += 1 }
}
