import Foundation
import Testing

@testable import CommonKit

@Suite struct WelcomeTests {
    @Test func theFirstFamilyAppShowsEverything() {
        #expect(WelcomeKind.decide(familyWelcomed: false, permissionMissing: false) == .full)
        #expect(WelcomeKind.decide(familyWelcomed: false, permissionMissing: true) == .full)
    }

    @Test func aLaterAppShowsOnlyAMissingPermission() {
        #expect(WelcomeKind.decide(familyWelcomed: true, permissionMissing: true) == .permission)
        #expect(WelcomeKind.decide(familyWelcomed: true, permissionMissing: false) == nil)
    }

    @Test func oneHolderAtATimeNamedByPid() throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "welcome-lock-\(UUID().uuidString)/welcome.lock")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let first = WelcomeLock(url: url), second = WelcomeLock(url: url)

        #expect(try first.tryAcquire())
        #expect(first.owner == getpid())
        // flock is per open file, so a second lock in the same process stands in for another app.
        #expect(try !second.tryAcquire())
        #expect(try first.tryAcquire(), "taking a lock already held is a no-op")

        first.release()
        #expect(try second.tryAcquire())
        #expect(try !first.tryAcquire())
    }

    @Test func aLockIsFreedWithItsOwner() throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "welcome-lock-\(UUID().uuidString)/welcome.lock")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        do {
            let gone = WelcomeLock(url: url)
            #expect(try gone.tryAcquire())
        }
        #expect(try WelcomeLock(url: url).tryAcquire())
    }

    @Test func theFamilySuiteIsOneFileEveryAppReads() throws {
        // The same suite name from two UserDefaults objects is the same store; across apps it's the
        // same plist in ~/Library/Preferences, since none is sandboxed.
        let suite = "io.github.oddurs.commontools.test-\(UUID().uuidString)"
        let writer = try #require(UserDefaults(suiteName: suite))
        defer { writer.removePersistentDomain(forName: suite) }
        writer.set(true, forKey: Welcome.familyKey)
        #expect(UserDefaults(suiteName: suite)?.bool(forKey: Welcome.familyKey) == true)
    }
}
