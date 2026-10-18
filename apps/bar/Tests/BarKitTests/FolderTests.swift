import BarKit
import CoreGraphics
import Foundation
import Testing

/// Recorded together on a 14-inch MacBook Pro on macOS 26.5 with every hidden icon off-screen:
/// the window server's list (every window Control Center's) and each app's `AXExtrasMenuBar`.
@Suite struct FolderTests {
    static let controlCenter: Int32 = 628
    static let bar: Int32 = 84435

    static func w(_ id: UInt32, _ minX: CGFloat, _ maxX: CGFloat) -> StatusItemWindow {
        StatusItemWindow(
            id: id, frame: CGRect(x: minX, y: 0, width: maxX - minX, height: 33), ownerPID: controlCenter,
            ownerName: "Control Center")
    }

    static func ax(
        _ pid: Int32, _ bundleID: String, _ name: String, _ minX: CGFloat, _ maxX: CGFloat, title: String? = nil,
        label: String? = nil
    ) -> AccessibleItem {
        AccessibleItem(
            pid: pid, bundleID: bundleID, appName: name, frame: CGRect(x: minX, y: 4, width: maxX - minX, height: 24),
            title: title, label: label)
    }

    static let windows: [StatusItemWindow] = [
        w(55267, -4544, -4506), w(51914, -4544, -4544), w(55741, -4506, -4468), w(27083, -4468, -4430),
        w(42813, -4430, -4398), w(124, -4398, -4358), w(583, -4358, -4318), w(45913, -4318, -4282),
        w(46, -4282, -4246), w(40, -4246, -4214), w(36, -4214, -4183), w(36720, -4183, -4151),
        w(37, -4151, -4107), w(19, -4107, -4069), w(8088, -4069, -4036), w(17, -4036, -3994),
        w(55696, -3994, -3963), w(55742, -3963, -3933),
        w(55886, -3933, 1083),  // Common Bar's divider
        w(55885, 1084, 1110),  // the More folder
        w(55778, 1110, 1160), w(55478, 1160, 1464), w(18, 1582, 1730),
    ]

    static let accessible: [AccessibleItem] = [
        ax(controlCenter, "com.apple.controlcenter", "Control Center", -4544, -4544),
        ax(69096, "com.oddurs.commoncommand", "Common Command", -4537, -4513, label: "Common Command"),
        ax(27426, "com.oddurs.commonshot", "Common Shot", -4499, -4475, label: "Common Shot"),
        ax(79748, "dev.kdrag0n.MacVirt", "OrbStack", -4461, -4437),
        ax(83911, "com.granola.app", "Granola", -4431, -4397),
        ax(814, "com.adobe.acc.AdobeCreativeCloud", "Creative Cloud", -4391, -4365),
        ax(88937, "ru.keepcoder.Telegram", "Telegram", -4359, -4317),
        ax(55522, "com.getdropbox.dropbox", "Dropbox", -4319, -4281),
        ax(856, "com.rampatra.presentify", "Presentify", -4283, -4245, title: "MenuBarIcon"),
        ax(824, "com.apple.Spotlight", "Spotlight", -4247, -4213, title: "Spotlight", label: "Search"),
        ax(629, "com.apple.systemuiserver", "SystemUIServer", -4207, -4190, title: "Siri", label: "Siri"),
        ax(40124, "com.1password.1password", "1Password", -4184, -4150),
        ax(817, "com.apple.TextInputMenuAgent", "TextInputMenuAgent", -4152, -4106, label: "U.S."),
        ax(controlCenter, "com.apple.controlcenter", "Control Center", -4099, -4077, label: "Wi‑Fi, connected, 3 bars"),
        ax(controlCenter, "com.apple.controlcenter", "Control Center", -4061, -4044, label: "Now Playing"),
        ax(controlCenter, "com.apple.controlcenter", "Control Center", -4028, -4002, label: "Battery"),
        ax(82007, "com.oddurs.commonglyph", "Common Glyph", -3995, -3962, label: "Glyph 2"),
        ax(27442, "com.oddurs.langsmart", "Common Keys", -3964, -3932, label: "🇺🇸"),
        ax(bar, "com.oddurs.reasonal", "Common Bar", -3926, 1076),
        ax(bar, "com.oddurs.reasonal", "Common Bar", 1091, 1103, label: "More"),
        ax(74876, "com.oddurs.commonbattery", "Common Battery", 1109, 1161, label: "Battery 34%"),
        ax(9425, "io.github.oddurs.StatBar", "Common Stats", 1159, 1465),
        ax(controlCenter, "com.apple.controlcenter", "Control Center", 1590, 1722, label: "Clock"),
    ]

    static let geometry = MenuBarGeometry(minX: 0, maxX: 1728, top: 0, height: 33, notch: 771...956)
    static let own = OwnItems(
        divider: CGRect(x: -3933, y: 0, width: 5016, height: 33), others: [CGRect(x: 1084, y: 0, width: 26, height: 33)]
    )

    let model = MenuBarModel(windows: windows, geometry: geometry, own: own)
    var entries: [FolderEntry] { model.folderEntries(Self.accessible, ownPID: Self.bar) }

    @Test func everyHiddenIconIsMatchedToItsApp() {
        #expect(entries.count == 17)
        #expect(entries.first?.owner.bundleID == "com.oddurs.commoncommand")
        #expect(entries.last?.owner.bundleID == "com.oddurs.langsmart")
        #expect(entries.map(\.id) == model.items.filter { $0.section == .hidden }.map(\.id))
    }

    @Test func pinnedIconsAreNotInTheFolder() {
        #expect(!entries.contains { $0.owner.bundleID == "io.github.oddurs.StatBar" })
        #expect(!entries.contains { $0.owner.pid == Self.bar })
    }

    @Test func rowsAreNamedForPeople() {
        #expect(
            entries.map(\.name) == [
                "Common Command", "Common Shot", "OrbStack", "Granola", "Creative Cloud", "Telegram", "Dropbox",
                "Presentify", "Search", "Siri", "1Password", "U.S.", "Wi‑Fi", "Now Playing", "Battery",
                "Common Glyph", "Common Keys",
            ])
    }

    @Test func anAppWithSeveralIconsTellsThemApart() {
        let first = Self.ax(1, "com.example.two", "Two", 0, 20, label: "Upload")
        let second = Self.ax(1, "com.example.two", "Two", 20, 40)
        #expect(MenuBarModel.name(of: first, among: [first, second]) == "Two: Upload")
        #expect(MenuBarModel.name(of: second, among: [first, second]) == "Two 2")
        #expect(MenuBarModel.name(of: second, among: [second]) == "Two")
    }

    @Test func anIconAccessibilityDoesntKnowIsLeftOut() {
        let entries = model.folderEntries(
            Self.accessible.filter { $0.bundleID != "com.getdropbox.dropbox" }, ownPID: Self.bar)
        #expect(entries.count == 16)
        #expect(!entries.contains { $0.item.id == 45913 })
    }

    @Test func eachIconIsMatchedOnce() {
        // Two Accessibility children over one window: the second has nowhere to go.
        let doubled = Self.accessible + [Self.ax(5, "com.example.ghost", "Ghost", -4450, -4440)]
        #expect(Set(model.folderEntries(doubled, ownPID: Self.bar).map(\.owner.pid)).isDisjoint(with: [5]))
    }

    // MARK: Groups

    static let family: Set<String> = [
        "io.github.oddurs.StatBar", "com.oddurs.langsmart", "com.oddurs.reasonal", "com.oddurs.commonglyph",
        "com.oddurs.commoncommand", "com.oddurs.commonshot", "com.oddurs.commonbattery",
    ]

    @Test func rowsAreGroupedAppsThenCommonToolsThenMacOS() {
        let groups = FolderEntry.grouped(entries, family: Self.family).map { $0.map(\.name) }
        #expect(
            groups == [
                ["OrbStack", "Granola", "Creative Cloud", "Telegram", "Dropbox", "Presentify", "1Password"],
                ["Common Command", "Common Shot", "Common Glyph", "Common Keys"],
                ["Search", "Siri", "U.S.", "Wi‑Fi", "Now Playing", "Battery"],
            ])
    }

    @Test func anAppsIconsStayTogetherWhereItsFirstIconIs() {
        let a1 = Self.ax(1, "com.example.a", "A", 0, 20, label: "One")
        let b = Self.ax(2, "com.example.b", "B", 20, 40)
        let a2 = Self.ax(1, "com.example.a", "A", 40, 60, label: "Two")
        let windows = [Self.w(1, 0, 20), Self.w(2, 20, 40), Self.w(3, 40, 60)]
        let own = OwnItems(divider: CGRect(x: 60, y: 0, width: 1, height: 33))
        let model = MenuBarModel(windows: windows, geometry: Self.geometry, own: own)
        let rows = FolderEntry.grouped(model.folderEntries([a1, b, a2], ownPID: 0), family: [])
        #expect(rows.map { $0.map(\.name) } == [["A: One", "A: Two", "B"]])
    }

    @Test func emptyGroupsAreLeftOut() {
        let onlyApple = entries.filter { $0.owner.bundleID?.hasPrefix("com.apple.") == true }
        #expect(FolderEntry.grouped(onlyApple, family: Self.family).count == 1)
        #expect(FolderEntry.grouped([], family: Self.family).isEmpty)
    }

    @Test func anyOddursGitHubAppCountsAsCommonTools() {
        #expect(FolderGroup(bundleID: "io.github.oddurs.Something", family: []) == .commonTools)
        #expect(FolderGroup(bundleID: "com.apple.controlcenter", family: []) == .system)
        #expect(FolderGroup(bundleID: nil, family: []) == .apps)
    }

    @Test func aRefreshThatMovesIconsButRenamesNothingLeavesTheRowsAlone() {
        var moved = entries
        moved[0].item.window.frame.origin.x += 500
        #expect(moved.map(\.signature) == entries.map(\.signature))
        moved[0].name = "Renamed"
        #expect(moved.map(\.signature) != entries.map(\.signature))
    }

    // MARK: Opening

    func hidden(_ id: UInt32) -> MenuBarItem { model.items.first { $0.id == id }! }

    @Test func theIconNearestTheFolderOpensInSightBesideTheNotch() {
        // Common Keys, 30 points wide: nothing between it and the divider, so it can show.
        #expect(model.blockEnd(toOpen: hidden(55742), dividerEnd: 1083, padding: 16) == 986)
    }

    @Test func theNextIconOpensUnderTheNotchWithNothingElseInSight() {
        // Common Glyph: Common Keys is between it and the divider, so that ends where the notch does.
        #expect(model.blockEnd(toOpen: hidden(55696), dividerEnd: 1083, padding: 16) == 956)
    }

    @Test func theFarthestIconLandsOnScreenWithTheRestOutOfSight() {
        // Common Command, with 573 points of icons between it and the divider: they end under
        // the notch, and it sits at x 345 to 383, behind the app's menus but on screen.
        let end = model.blockEnd(toOpen: hidden(55267), dividerEnd: 1083, padding: 16)!
        #expect(end == 956)
        #expect(end - 573 - 38 == 345)
    }

    @Test func theDividerShortensByTheDifference() {
        #expect(DividerLayout.length(showingUpTo: 956, dividerEnd: 1083, padding: 16) == 111)
        #expect(DividerLayout.length(showingUpTo: 2000, dividerEnd: 1083, padding: 16) == 0)
    }

    @Test func withoutANotchTheIconOpensAtTheScreensEdge() {
        let plain = MenuBarGeometry(minX: 0, maxX: 1728, top: 0, height: 33)
        let model = MenuBarModel(windows: Self.windows, geometry: plain, own: Self.own)
        let target = model.items.first { $0.id == 55267 }!
        #expect(model.blockEnd(toOpen: target, dividerEnd: 1083, padding: 16) == 611)
    }

    @Test func anIconThatCantReachTheScreenIsntOpened() {
        let narrow = MenuBarGeometry(minX: 0, maxX: 700, top: 0, height: 33, notch: 300...400)
        let model = MenuBarModel(windows: Self.windows, geometry: narrow, own: Self.own)
        let target = model.items.first { $0.id == 55267 }!
        #expect(model.blockEnd(toOpen: target, dividerEnd: 600, padding: 16) == nil)
    }

    @Test func aShownIconHasNothingToOpen() {
        let shown = model.items.first { $0.id == 55478 }!
        #expect(model.blockEnd(toOpen: shown, dividerEnd: 1083, padding: 16) == nil)
    }
}

@Suite struct OpenWatchTests {
    let start = Date(timeIntervalSinceReferenceDate: 0)
    func at(_ s: TimeInterval) -> Date { start.addingTimeInterval(s) }

    @Test func waitsForTheMenuToAppear() {
        var watch = OpenWatch(started: start)
        #expect(watch.update(somethingOpen: false, now: at(0.5)) == .waiting)
        #expect(watch.update(somethingOpen: true, now: at(0.6)) == .open)
    }

    @Test func aPressThatOpensNothingIsDoneSoon() {
        var watch = OpenWatch(started: start)
        #expect(watch.update(somethingOpen: false, now: at(OpenWatch.appearTimeout)) == .done)
    }

    @Test func staysOpenWhileTheMenuIs() {
        var watch = OpenWatch(started: start)
        _ = watch.update(somethingOpen: true, now: at(0.2))
        #expect(watch.update(somethingOpen: true, now: at(60)) == .open)
    }

    @Test func aMomentaryGapIsNotAClose() {
        var watch = OpenWatch(started: start)
        _ = watch.update(somethingOpen: true, now: at(0.2))
        #expect(watch.update(somethingOpen: false, now: at(1)) == .open)
        #expect(watch.update(somethingOpen: true, now: at(1.1)) == .open)
        #expect(watch.update(somethingOpen: false, now: at(2)) == .open)
        #expect(watch.update(somethingOpen: false, now: at(2.1)) == .open)
        #expect(watch.update(somethingOpen: false, now: at(2.5)) == .done)
    }
}

@Suite struct MoveTests {
    let model = MenuBarModel(windows: FolderTests.windows, geometry: FolderTests.geometry, own: FolderTests.own)
    func item(_ id: UInt32) -> MenuBarItem { model.items.first { $0.id == id }! }

    @Test func theDropIsLeftOfTheNeighboursMiddle() {
        // Common Keys, 30 pt wide at 926–956, dropped beside the More folder at 1084–1110.
        let more = CGRect(x: 1084, y: 0, width: 26, height: 33)
        let drag = Move.drag(CGRect(x: 926, y: 0, width: 30, height: 33), toJustLeftOf: more, barMidY: 16.5)
        #expect(drag.from == CGPoint(x: 941, y: 16.5))
        #expect(drag.to == CGPoint(x: 1090.5, y: 16.5))
        #expect(drag.to.x < more.midX)
    }

    @Test func thePathEndsWhereItLetsGoAndNeverJumps() {
        let path = Move.path(from: CGPoint(x: 100, y: 10), to: CGPoint(x: 400, y: 10))
        #expect(path.count == Move.steps)
        #expect(path.last == CGPoint(x: 400, y: 10))
        let gaps = zip([CGPoint(x: 100, y: 10)] + path, path).map { $1.x - $0.x }
        #expect(gaps.allSatisfy { abs($0 - 25) < 0.001 })
    }

    @Test func aMoveLandedWhenItsRightEdgeMeetsTheNeighbour() {
        let folder = CGRect(x: 1084, y: 0, width: 26, height: 33)
        #expect(Move.landed(CGRect(x: 1054, y: 0, width: 30, height: 33), justLeftOf: folder))
        #expect(Move.landed(CGRect(x: 1055, y: 0, width: 30, height: 33), justLeftOf: folder))
        #expect(!Move.landed(CGRect(x: 926, y: 0, width: 30, height: 33), justLeftOf: folder))
        // Dropped right of the folder instead: not where it was meant to go.
        #expect(!Move.landed(CGRect(x: 1110, y: 0, width: 30, height: 33), justLeftOf: folder))
    }

    @Test func aMenuUnderItsIconCountsAsOpenedThere() {
        let icon = CGRect(x: 350, y: 0, width: 56, height: 33)
        // Recorded: the second press opened Probe's menu at 346.
        #expect(
            Move.opened(CGRect(x: 346, y: 34, width: 105, height: 34), under: icon, screenMinX: 0, screenMaxX: 1728))
    }

    @Test func aMenuPlacedFromAStaleFrameDoesNot() {
        let icon = CGRect(x: 350, y: 0, width: 56, height: 33)
        // Recorded: the first press opened it where the app last thought the icon was.
        #expect(
            !Move.opened(CGRect(x: -4654, y: 34, width: 105, height: 34), under: icon, screenMinX: 0, screenMaxX: 1728))
        // A popover pinned to the screen's left edge, far from an icon beside a folder.
        let beside = CGRect(x: 1040, y: 0, width: 30, height: 33)
        #expect(
            !Move.opened(CGRect(x: 0, y: 28, width: 226, height: 106), under: beside, screenMinX: 0, screenMaxX: 1728))
    }

    @Test func aDragStartsOnlyUnderTheNotchOrRightOfIt() {
        let notched = FolderTests.geometry
        #expect(Move.reachable(CGRect(x: 880, y: 0, width: 30, height: 33), in: notched))
        #expect(Move.reachable(CGRect(x: 980, y: 0, width: 30, height: 33), in: notched))
        // Behind the app's menus, where a press would open one of them.
        #expect(!Move.reachable(CGRect(x: 350, y: 0, width: 56, height: 33), in: notched))
        #expect(!Move.reachable(CGRect(x: 760, y: 0, width: 30, height: 33), in: notched))
        let plain = MenuBarGeometry(minX: 0, maxX: 1728, height: 24)
        #expect(!Move.reachable(CGRect(x: 600, y: 0, width: 30, height: 24), in: plain))
        #expect(Move.reachable(CGRect(x: 1000, y: 0, width: 30, height: 24), in: plain))
    }

    @Test func anIconsSlotIsTheIconRightOfIt() {
        // Wi‑Fi (#19) sits left of Now Playing (#8088).
        #expect(model.slot(of: item(19))?.id == 8088)
        // Common Keys is nearest the divider: it goes back left of the divider itself.
        #expect(model.slot(of: item(55742)) == nil)
    }

    @Test func aShownIconHasNoSlot() {
        #expect(model.slot(of: item(55478)) == nil)
    }
}
