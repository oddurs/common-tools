import Foundation
import Testing

@testable import CommonKit

@MainActor @Suite struct UpdateCheckTests {
    static let bar = CommonTool.all.first { $0.id == "bar" }!

    nonisolated static func release(
        _ tag: String, draft: Bool = false, prerelease: Bool = false, assets: [String] = ["CommonBar.zip"]
    )
        -> String
    {
        let list = assets.map {
            """
            {"name": "\($0)", "size": 1, "browser_download_url": "https://github.com/oddurs/common-tools/releases/download/\(tag)/\($0)"}
            """
        }
        return """
            {"tag_name": "\(tag)", "html_url": "https://github.com/oddurs/common-tools/releases/tag/\(tag)",
             "published_at": "2026-10-16T07:51:46Z", "draft": \(draft), "prerelease": \(prerelease),
             "assets": [\(list.joined(separator: ","))]}
            """
    }

    nonisolated static func list(_ releases: String...) -> Data { Data("[\(releases.joined(separator: ","))]".utf8) }

    /// Fresh defaults for every test, so one test's state can't reach another.
    nonisolated static func defaults() -> UserDefaults {
        let suite = "CommonKitTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func picksTheNewestOfThisAppByVersionNotPosition() throws {
        let data = Self.list(
            Self.release("stats-v9.0.0"),
            Self.release("bar-v0.4.1"),
            Self.release("bar-v0.10.0"),
            Self.release("bar-v0.9.0"),
            Self.release("bar-v1.0.0", draft: true),
            Self.release("bar-v2.0.0", prerelease: true))
        let newest = try #require(try UpdateCheck.newest(in: data, for: Self.bar))
        #expect(newest.version == Version(0, 10, 0))
        #expect(newest.page.absoluteString == "https://github.com/oddurs/common-tools/releases/tag/bar-v0.10.0")
        #expect(
            newest.download?.absoluteString
                == "https://github.com/oddurs/common-tools/releases/download/bar-v0.10.0/CommonBar.zip")
    }

    @Test func noReleaseMeansNoUpdate() throws {
        #expect(try UpdateCheck.newest(in: Self.list(Self.release("stats-v0.4.0")), for: Self.bar) == nil)
        #expect(try UpdateCheck.newest(in: Self.list(), for: Self.bar) == nil)
    }

    @Test func downloadIsOptionalAndGarbageThrows() throws {
        let data = Self.list(Self.release("bar-v0.4.0", assets: ["worldkey.zip"]))
        let newest = try #require(try UpdateCheck.newest(in: data, for: Self.bar))
        #expect(newest.download == nil)
        #expect(throws: (any Error).self) { try UpdateCheck.newest(in: Data("<html>".utf8), for: Self.bar) }
    }

    @Test func assetNamesMatchAppsJSON() throws {
        // The download is the asset named after the app without the space; apps.json is the source of truth.
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let apps = try JSONSerialization.jsonObject(with: Data(contentsOf: root.appending(path: "apps.json")))
        let fields = try #require(apps as? [String: [String: Any]])
        for tool in CommonTool.all {
            let asset = try #require(fields[tool.id]?["ASSET"] as? String)
            #expect(asset == tool.name.replacingOccurrences(of: " ", with: ""), "\(tool.id)")
        }
    }

    @Test func offByDefaultAndFetchesNothingUntilEnabled() async {
        let fetched = Counter()
        let check = UpdateCheck(
            tool: Self.bar, current: Version(0, 4, 0), defaults: Self.defaults(),
            fetch: { _ in
                await fetched.bump()
                return Self.list()
            })
        #expect(!check.isEnabled)
        #expect(!check.isDue)
        await check.checkIfDue()
        #expect(await fetched.count == 0)
        #expect(check.available == nil)
    }

    @Test func checksOnceADayAndFindsANewerVersion() async throws {
        let fetched = Counter()
        var clock = Date(timeIntervalSince1970: 1_000_000)
        let now = Clock(clock)
        let check = UpdateCheck(
            tool: Self.bar, current: Version(0, 4, 0), defaults: Self.defaults(), now: { now.date },
            fetch: { request in
                #expect(request.url == UpdateCheck.releases)
                #expect(request.httpMethod == "GET")
                #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
                #expect(request.value(forHTTPHeaderField: "User-Agent") == "common-tools")
                await fetched.bump()
                return Self.list(Self.release("bar-v0.5.0"))
            })
        check.isEnabled = true
        #expect(check.isDue)
        await check.checkIfDue()
        #expect(await fetched.count == 1)
        #expect(check.available?.version == Version(0, 5, 0))
        #expect(check.lastChecked == clock)
        #expect(check.lastError == nil)

        // The same day: nothing.
        clock += 12 * 60 * 60
        now.date = clock
        #expect(!check.isDue)
        await check.checkIfDue()
        #expect(await fetched.count == 1)

        // A day later: again.
        clock += 12 * 60 * 60
        now.date = clock
        #expect(check.isDue)
        await check.checkIfDue()
        #expect(await fetched.count == 2)
    }

    @Test func runningTheLatestMeansNothingAvailable() async throws {
        let check = UpdateCheck(
            tool: Self.bar, current: Version(0, 5, 0), defaults: Self.defaults(),
            fetch: { _ in
                Self.list(Self.release("bar-v0.5.0"), Self.release("bar-v0.4.0"))
            })
        try await check.check()
        #expect(check.available == nil)
    }

    @Test func aFailedCheckIsRecordedNotHidden() async {
        let check = UpdateCheck(
            tool: Self.bar, current: Version(0, 4, 0), defaults: Self.defaults(),
            fetch: { _ in
                throw URLError(.notConnectedToInternet)
            })
        check.isEnabled = true
        await check.checkIfDue()
        #expect(check.available == nil)
        #expect(check.lastError != nil)
        // Not recorded as checked, so the next launch tries again.
        #expect(check.lastChecked == nil)
    }
}

private actor Counter {
    private(set) var count = 0
    func bump() { count += 1 }
}

private final class Clock: @unchecked Sendable {
    var date: Date
    init(_ date: Date) { self.date = date }
}
