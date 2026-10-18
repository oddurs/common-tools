import BarKit
import CoreGraphics
import Foundation
import Testing

@Suite struct FolderConfigTests {
    let model = MenuBarModel(windows: FolderTests.windows, geometry: FolderTests.geometry, own: FolderTests.own)
    var entries: [FolderEntry] { model.folderEntries(FolderTests.accessible, ownPID: FolderTests.bar) }

    func key(_ bundleID: String, _ label: String? = nil, _ index: Int = 0) -> ItemKey {
        ItemKey(bundleID: bundleID, label: label, index: index)
    }

    // MARK: Keys

    @Test func anIconIsKeptByItsAppAndLabel() {
        let keys = FolderEntry.keys(entries)
        #expect(keys[1] == key("com.oddurs.commonshot", "Common Shot", 0))
        #expect(keys.contains(key("com.apple.controlcenter", "Wi‑Fi, connected, 3 bars", 0)))
        #expect(keys.contains(key("com.apple.controlcenter", "Battery", 2)))
    }

    @Test func anIconWithoutALabelIsKeptByItsPlaceAmongItsAppsIcons() {
        let keys = FolderEntry.keys(entries)
        #expect(keys.contains(key("dev.kdrag0n.MacVirt", nil, 0)))
    }

    @Test func aLabelOutweighsThePlace() {
        // Wi‑Fi moved: it is the same icon by its label, wherever it now comes.
        #expect(key("com.apple.controlcenter", "Wi‑Fi", 0).matches(key("com.apple.controlcenter", "Wi‑Fi", 3)))
        #expect(!key("com.apple.controlcenter", "Wi‑Fi", 0).matches(key("com.apple.controlcenter", "Battery", 0)))
        #expect(key("com.example", nil, 1).matches(key("com.example", nil, 1)))
        #expect(!key("com.example", nil, 1).matches(key("com.example", nil, 2)))
        #expect(!key("com.example", "A", 0).matches(key("com.other", "A", 0)))
    }

    // MARK: Folders

    @Test func aFreshStartHasOnlyMore() {
        let config = FolderConfig()
        #expect(config.folders.map(\.id) == [FolderConfig.moreID])
        #expect(config.folders[0].name == "More")
    }

    @Test func moreHoldsEveryIconNoOtherFolderClaims() {
        var config = FolderConfig()
        let work = config.add(name: "Work", id: "work")
        config.assign(key("com.1password.1password"), to: work)
        config.assign(key("ru.keepcoder.Telegram"), to: work)
        let contents = config.contents(of: entries)
        #expect(contents["work"]?.map(\.name) == ["Telegram", "1Password"])
        #expect(contents[FolderConfig.moreID]?.count == 15)
        #expect(contents.values.reduce(0) { $0 + $1.count } == entries.count)
    }

    @Test func assigningMovesAnIconOutOfItsOldFolder() {
        var config = FolderConfig()
        let a = config.add(name: "A", id: "a")
        let b = config.add(name: "B", id: "b")
        config.assign(key("com.example"), to: a)
        config.assign(key("com.example"), to: b)
        #expect(config.folder(a)?.members.isEmpty == true)
        #expect(config.folderID(for: key("com.example")) == b)
        config.assign(key("com.example"), to: FolderConfig.moreID)
        #expect(config.folderID(for: key("com.example")) == FolderConfig.moreID)
        #expect(config.folder(b)?.members.isEmpty == true)
    }

    @Test func deletingAFolderSendsItsIconsBackToMore() {
        var config = FolderConfig()
        let work = config.add(name: "Work", id: "work")
        config.assign(key("com.example"), to: work)
        config.delete(work)
        #expect(config.folders.map(\.id) == [FolderConfig.moreID])
        #expect(config.folderID(for: key("com.example")) == FolderConfig.moreID)
    }

    @Test func moreCantBeDeleted() {
        var config = FolderConfig()
        config.delete(FolderConfig.moreID)
        #expect(config.folders.map(\.id) == [FolderConfig.moreID])
    }

    @Test func aNewFolderGoesAtTheLeftAndFoldersReorder() {
        var config = FolderConfig()
        config.add(name: "A", id: "a")
        config.add(name: "B", id: "b")
        #expect(config.folders.map(\.id) == ["b", "a", "more"])
        config.move("b", by: 1)
        #expect(config.folders.map(\.id) == ["a", "b", "more"])
        config.move("more", by: -5)
        #expect(config.folders.map(\.id) == ["more", "a", "b"])
        config.move("b", by: 1)
        #expect(config.folders.map(\.id) == ["more", "a", "b"])
    }

    @Test func renamingIgnoresABlankName() {
        var config = FolderConfig()
        config.rename(FolderConfig.moreID, to: "  Extras ")
        #expect(config.folder(FolderConfig.moreID)?.name == "Extras")
        config.rename(FolderConfig.moreID, to: "   ")
        #expect(config.folder(FolderConfig.moreID)?.name == "Extras")
        config.setSymbol(FolderConfig.moreID, to: "tray")
        #expect(config.folder(FolderConfig.moreID)?.symbol == "tray")
    }

    // MARK: Saving

    @Test func foldersSurviveARoundTrip() {
        var config = FolderConfig()
        let work = config.add(name: "Work", symbol: "briefcase", id: "work")
        config.assign(key("com.1password.1password", nil, 0), to: work)
        #expect(FolderConfig(data: config.encoded) == config)
    }

    @Test func unreadableDataIsAFreshStart() {
        #expect(FolderConfig(data: Data("not json".utf8)) == FolderConfig())
        #expect(FolderConfig(data: nil) == FolderConfig())
    }

    @Test func savedDataWithoutMoreGetsItBack() throws {
        let saved = #"{"folders":[{"id":"work","name":"Work","symbol":"briefcase","members":[]}]}"#
        let config = FolderConfig(data: Data(saved.utf8))
        #expect(config.folders.map(\.id) == ["work", FolderConfig.moreID])
    }

    @Test func moreNeverKeepsExplicitMembers() {
        let saved =
            #"{"folders":[{"id":"more","name":"More","symbol":"ellipsis.circle","members":[{"bundleID":"x","index":0}]}]}"#
        #expect(FolderConfig(data: Data(saved.utf8)).folder(FolderConfig.moreID)?.members.isEmpty == true)
    }
}
