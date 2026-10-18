import Foundation
import Testing

@testable import CommonKit

@Suite struct LegacyIdentityTests {
    /// Two throwaway defaults domains, the old identity's and the new one's, removed afterwards.
    final class Domains {
        let old = "LegacyIdentityTests.old-\(UUID())"
        let new = "LegacyIdentityTests.new-\(UUID())"
        let oldDefaults: UserDefaults
        let newDefaults: UserDefaults

        init() throws {
            oldDefaults = try #require(UserDefaults(suiteName: old))
            newDefaults = try #require(UserDefaults(suiteName: new))
        }

        deinit {
            for name in [old, new] { LegacyIdentityTests.forget(name) }
        }
    }

    /// Empties a test domain and deletes the plist cfprefsd leaves behind.
    static func forget(_ domain: String) {
        UserDefaults.standard.removePersistentDomain(forName: domain)
        try? FileManager.default.removeItem(at: URL.libraryDirectory.appending(path: "Preferences/\(domain).plist"))
    }

    @Test func copiesTheOldDomainWithStatusItemsRenamed() throws {
        let domains = try Domains()
        domains.oldDefaults.set(140.0, forKey: "NSStatusItem Preferred Position Old")
        domains.oldDefaults.set(true, forKey: "NSStatusItem Visible Old")
        domains.oldDefaults.set(false, forKey: "NSStatusItem VisibleCC Old")
        domains.oldDefaults.set(608.0, forKey: "NSStatusItem Preferred Position divider")
        domains.oldDefaults.set(Data([1, 2, 3]), forKey: "layout")
        domains.oldDefaults.set(["com.apple.Terminal"], forKey: "excludedApps")
        domains.oldDefaults.set(true, forKey: "askedForAccessibility")
        let legacy = LegacyIdentity(
            bundleIdentifier: domains.old, statusItems: ["Old": "new"], droppedKeys: ["askedForAccessibility"])

        #expect(legacy.copyDefaults(into: domains.newDefaults, domain: domains.new) == 6)

        let new = domains.newDefaults
        #expect(new.double(forKey: "NSStatusItem Preferred Position new") == 140)
        #expect(new.object(forKey: "NSStatusItem Visible new") as? Bool == true)
        #expect(new.object(forKey: "NSStatusItem VisibleCC new") as? Bool == false)
        // Another item's name is no old name, and stays as it is.
        #expect(new.double(forKey: "NSStatusItem Preferred Position divider") == 608)
        #expect(new.data(forKey: "layout") == Data([1, 2, 3]))
        #expect(new.stringArray(forKey: "excludedApps") == ["com.apple.Terminal"])
        #expect(new.object(forKey: "askedForAccessibility") == nil)
        #expect(new.object(forKey: "NSStatusItem Preferred Position Old") == nil)
        // The old domain stays, so going back to the old version finds its settings.
        #expect(domains.oldDefaults.double(forKey: "NSStatusItem Preferred Position Old") == 140)
    }

    @Test func copiesOnlyTheOldAppsOwnKeys() throws {
        // A suite's dictionaryRepresentation holds every global default too; none may come over.
        let domains = try Domains()
        domains.oldDefaults.set(1, forKey: "only")
        let legacy = LegacyIdentity(bundleIdentifier: domains.old)
        #expect(legacy.copyDefaults(into: domains.newDefaults, domain: domains.new) == 1)
        let copied = try #require(domains.newDefaults.persistentDomain(forName: domains.new))
        #expect(Set(copied.keys) == ["only", LoginItemFollow.key])
    }

    @Test func leavesANewDomainThatHasSettingsAlone() throws {
        let domains = try Domains()
        domains.oldDefaults.set(140.0, forKey: "NSStatusItem Preferred Position Old")
        domains.newDefaults.set(912.0, forKey: "NSStatusItem Preferred Position new")
        let legacy = LegacyIdentity(bundleIdentifier: domains.old, statusItems: ["Old": "new"])

        #expect(legacy.copyDefaults(into: domains.newDefaults, domain: domains.new) == 0)
        #expect(domains.newDefaults.double(forKey: "NSStatusItem Preferred Position new") == 912)
        #expect(domains.newDefaults.object(forKey: LoginItemFollow.key) == nil)
    }

    @Test func copiesOnce() throws {
        let domains = try Domains()
        domains.oldDefaults.set("first", forKey: "value")
        let legacy = LegacyIdentity(bundleIdentifier: domains.old)
        #expect(legacy.copyDefaults(into: domains.newDefaults, domain: domains.new) == 1)
        domains.newDefaults.set("changed here", forKey: "value")
        #expect(legacy.copyDefaults(into: domains.newDefaults, domain: domains.new) == 0)
        #expect(domains.newDefaults.string(forKey: "value") == "changed here")
    }

    @Test func aFreshInstallHasNothingToCopy() throws {
        let domains = try Domains()
        let legacy = LegacyIdentity(bundleIdentifier: domains.old)
        #expect(legacy.copyDefaults(into: domains.newDefaults, domain: domains.new) == 0)
        #expect(domains.newDefaults.object(forKey: LoginItemFollow.key) == nil)
    }

    @Test func readsTheOldPlistFromDisk() throws {
        // What an update meets: the old app's settings only in its plist, written by another process.
        let domain = "LegacyIdentityTests.disk-\(UUID())"
        defer { Self.forget(domain) }
        let write = Process()
        write.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        write.arguments = ["write", domain, "NSStatusItem Preferred Position Old", "-float", "228"]
        try write.run()
        write.waitUntilExit()
        #expect(write.terminationStatus == 0)
        let plist = URL.libraryDirectory.appending(path: "Preferences/\(domain).plist")
        #expect(FileManager.default.fileExists(atPath: plist.path))

        let newDomain = "LegacyIdentityTests.new-\(UUID())"
        defer { Self.forget(newDomain) }
        let new = try #require(UserDefaults(suiteName: newDomain))
        let legacy = LegacyIdentity(bundleIdentifier: domain, statusItems: ["Old": "new"])
        #expect(legacy.copyDefaults(into: new, domain: newDomain) == 1)
        #expect(new.double(forKey: "NSStatusItem Preferred Position new") == 228)
    }

    @Test func renamesOnlyStatusItemKeysEndingInTheOldName() {
        let legacy = LegacyIdentity(bundleIdentifier: "old", statusItems: ["Old": "new"])
        #expect(legacy.renamed("NSStatusItem Preferred Position Old") == "NSStatusItem Preferred Position new")
        #expect(legacy.renamed("NSStatusItem Preferred Position Older") == "NSStatusItem Preferred Position Older")
        #expect(legacy.renamed("NSStatusItem Preferred Position Item-0") == "NSStatusItem Preferred Position Item-0")
        #expect(legacy.renamed("my Old") == "my Old")
    }

    // MARK: Folder

    private func temporaryBase() throws -> URL {
        let base = FileManager.default.temporaryDirectory.appending(path: "LegacyIdentityTests-\(UUID())")
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    @Test func movesTheSupportFolderWithItsFiles() throws {
        let base = try temporaryBase()
        defer { try? FileManager.default.removeItem(at: base) }
        let old = base.appending(path: "Old Name")
        try FileManager.default.createDirectory(at: old, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: old.appending(path: "memory.json"))
        let legacy = LegacyIdentity(bundleIdentifier: "old", supportFolder: .init(old: "Old Name", new: "New Name"))

        #expect(try legacy.moveSupportFolder(in: base))
        #expect(!FileManager.default.fileExists(atPath: old.path))
        #expect(try Data(contentsOf: base.appending(path: "New Name/memory.json")) == Data("{}".utf8))
        // Done once: a second launch finds nothing to move.
        #expect(try !legacy.moveSupportFolder(in: base))
    }

    @Test func keepsANewFolderThatExists() throws {
        let base = try temporaryBase()
        defer { try? FileManager.default.removeItem(at: base) }
        for name in ["Old Name", "New Name"] {
            try FileManager.default.createDirectory(at: base.appending(path: name), withIntermediateDirectories: true)
        }
        try Data("new".utf8).write(to: base.appending(path: "New Name/memory.json"))
        let legacy = LegacyIdentity(bundleIdentifier: "old", supportFolder: .init(old: "Old Name", new: "New Name"))

        #expect(try !legacy.moveSupportFolder(in: base))
        #expect(FileManager.default.fileExists(atPath: base.appending(path: "Old Name").path))
        #expect(try Data(contentsOf: base.appending(path: "New Name/memory.json")) == Data("new".utf8))
    }

    @Test func movesNothingWithoutAnOldFolder() throws {
        let base = try temporaryBase()
        defer { try? FileManager.default.removeItem(at: base) }
        let legacy = LegacyIdentity(bundleIdentifier: "old", supportFolder: .init(old: "Old Name", new: "New Name"))
        #expect(try !legacy.moveSupportFolder(in: base))
        #expect(try !LegacyIdentity(bundleIdentifier: "old").moveSupportFolder(in: base))
    }

    // MARK: Login item

    @Test func followsTheOldLoginItemOnlyWhenItOpensTheApp() {
        #expect(LoginItemFollow.decide(pending: false, launchedAtLogin: true, registered: false) == .nothing)
        #expect(LoginItemFollow.decide(pending: true, launchedAtLogin: false, registered: false) == .wait)
        #expect(LoginItemFollow.decide(pending: true, launchedAtLogin: true, registered: false) == .register)
        #expect(LoginItemFollow.decide(pending: true, launchedAtLogin: true, registered: true) == .done)
        #expect(LoginItemFollow.decide(pending: true, launchedAtLogin: false, registered: true) == .done)
    }

    @Test @MainActor func aTestRunIsNoLoginLaunch() {
        #expect(!LegacyIdentity.launchedAtLogin)
    }

    @Test @MainActor func nothingRunsUnderAnIdentityNobodyHas() {
        #expect(!LegacyIdentity.quitRunningCopy(of: "LegacyIdentityTests.nobody-\(UUID())"))
    }
}
