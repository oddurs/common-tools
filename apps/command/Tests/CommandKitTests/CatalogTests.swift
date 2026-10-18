import Foundation
import Testing

@testable import CommandKit

@Suite struct AppCatalogTests {
    func makeTree(_ paths: [String]) throws -> URL {
        let root = FileManager.default.temporaryDirectory.appending(path: "catalog-\(UUID().uuidString)")
        for path in paths {
            try FileManager.default.createDirectory(at: root.appending(path: path), withIntermediateDirectories: true)
        }
        return root
    }

    @Test func findsAppsInFoldersButNotInsideApps() throws {
        let root = try makeTree([
            "Safari.app/Contents", "Utilities/Terminal.app", "Suite/Tools/Deep.app", "Suite/Tools/Deeper/Hidden.app",
            "Xcode.app/Contents/Applications/Instruments.app", "Notes.txt", ".Secret.app",
        ])
        defer { try? FileManager.default.removeItem(at: root) }
        let names = Set(
            AppCatalog.scan(roots: [root], extras: []) { $0.deletingPathExtension().lastPathComponent }.map(
                \.item.title))
        #expect(names == ["Safari", "Terminal", "Deep", "Xcode"])
    }

    @Test func aSymlinkAndItsTargetAreOneApp() throws {
        let root = try makeTree(["Real/Safari.app"])
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createSymbolicLink(
            at: root.appending(path: "Safari.app"), withDestinationURL: root.appending(path: "Real/Safari.app"))
        #expect(AppCatalog.scan(roots: [root], extras: []).count == 1)
    }

    @Test func theFileNameIsAnAlternativeToALocalisedName() throws {
        let root = try makeTree(["System Settings.app"])
        defer { try? FileManager.default.removeItem(at: root) }
        let candidate = try #require(AppCatalog.scan(roots: [root], extras: []) { _ in "Systemeinstellungen" }.first)
        #expect(candidate.names.map(\.string) == ["Systemeinstellungen", "System Settings"])
    }

    @Test func findsTheRealApplicationsFolder() {
        let titles = Set(AppCatalog.scan().map(\.item.title))
        #expect(titles.contains("Finder"))
        #expect(titles.contains("Safari"))
        #expect(titles.contains("Terminal"))
    }
}

@Suite struct SettingsPaneTests {
    @Test func prefersTheLocalisedName() {
        #expect(SettingsPanes.readableName(localized: "Menu Bar", raw: "ControlCenterSettings") == "Menu Bar")
    }

    @Test func dropsInternalNames() {
        #expect(SettingsPanes.readableName(localized: nil, raw: "PowerPreferences") == nil)
        #expect(SettingsPanes.readableName(localized: nil, raw: "HeadphoneSettingsExtension") == nil)
        #expect(SettingsPanes.readableName(localized: "", raw: nil) == nil)
    }

    @Test func keepsPlainNames() {
        #expect(SettingsPanes.readableName(localized: nil, raw: "Bluetooth") == "Bluetooth")
        #expect(SettingsPanes.readableName(localized: nil, raw: "VPN") == "VPN")
        #expect(SettingsPanes.readableName(localized: nil, raw: "Touch ID & Password") == "Touch ID & Password")
    }

    @Test func findsPanesAndTopicsOnThisMac() {
        let found = SettingsPanes.scan(isPortable: true)
        let panes = found.filter { !$0.item.id.contains("#") }
        #expect(panes.count > 10)
        #expect(found.count > panes.count)
        #expect(found.allSatisfy { $0.item.kind == .settings })
        #expect(Set(found.map(\.item.id)).count == found.count)
    }

    let terms: [String: Any] = [
        "Main": [
            "localizableStrings": [
                ["title": "Appearance", "index": "light, dark, theme, Dark Mode"],
                ["title": "Accent color", "index": "button, selection"],
                ["title": "Accent Color", "index": "duplicate"],
                ["title": "Low Power Mode", "index": "save battery", "portableOnly": true],
                ["title": "UPS", "index": "uninterruptible power", "desktopOnly": true],
                ["index": "no title"],
            ]
        ]
    ]
    let target = URL(string: "x-apple.systempreferences:com.apple.Appearance-Settings.extension")!

    @Test func topicsFollowWhetherTheMacHasABattery() {
        #expect(SettingsPanes.topics(in: terms, isPortable: true).map(\.title).contains("Low Power Mode"))
        #expect(!SettingsPanes.topics(in: terms, isPortable: true).map(\.title).contains("UPS"))
        #expect(SettingsPanes.topics(in: terms, isPortable: false).map(\.title).contains("UPS"))
        #expect(
            SettingsPanes.topics(in: terms, isPortable: true).first?.keywords == [
                "light", "dark", "theme", "Dark Mode",
            ])
    }

    @Test func aTopicNamedLikeItsPaneLendsThePaneItsKeywords() {
        let candidates = SettingsPanes.candidates(
            identifier: "appearance", name: "Appearance", topics: SettingsPanes.topics(in: terms, isPortable: true),
            target: target, icon: nil)
        #expect(candidates.map(\.item.title) == ["Appearance", "Accent color", "Low Power Mode"])
        #expect(candidates[0].item.subtitle == "")
        #expect(candidates[1].item.subtitle == "Appearance")
        #expect(candidates[1].weight < candidates[0].weight)
        #expect(Fuzzy.keywordScore(Fuzzy.prepare("dark"), candidates[0].keywords) != nil)
    }

    @Test func aPaneWithoutAReadableNameStillOffersItsTopics() {
        let candidates = SettingsPanes.candidates(
            identifier: "battery", name: nil,
            topics: [.init(title: "Battery", keywords: ["charge"]), .init(title: "Low Power Mode", keywords: [])],
            target: target, icon: nil)
        #expect(candidates.map(\.item.title) == ["Battery", "Low Power Mode"])
        #expect(candidates.allSatisfy { $0.item.subtitle == "" })
        #expect(candidates.allSatisfy { $0.matchesWordStarts })
    }
}

@Suite struct FileQueryTests {
    @Test func everyWordMustStartAWordInTheName() {
        #expect(
            FileQuery.spotlightQuery(for: " tax  2024 ")
                == #"kMDItemDisplayName == "tax*"cdw && kMDItemDisplayName == "2024*"cdw && kMDItemContentType != "com.apple.application-bundle""#
        )
    }

    @Test func escapesQuotesAndWildcards() {
        #expect(FileQuery.escape(#"a"b*c\d'e"#) == #"a\"b\*c\\d\'e"#)
    }

    @Test func emptyQueryRunsNothing() {
        #expect(FileQuery.spotlightQuery(for: "   ") == nil)
    }
}

@Suite struct KeyComboTests {
    @Test func displaysModifiersInTheSystemOrder() {
        let combo = KeyCombo(keyCode: 40, modifiers: [.command, .shift, .option, .control])
        #expect(combo.display { _ in "k" } == "⌃⌥⇧⌘K")
        #expect(KeyCombo.standard.display { _ in nil } == "⌥Space")
    }

    @Test func convertsToCarbonModifiers() {
        #expect(KeyCombo(keyCode: 49, modifiers: [.command, .option]).carbonModifiers == 0x0900)
        #expect(KeyCombo(keyCode: 49, modifiers: [.control, .shift]).carbonModifiers == 0x1200)
    }

    @Test func dropsFlagsThatArentModifiers() {
        #expect(KeyCombo(keyCode: 49, modifiers: .init(rawValue: 1 << 23 | 1 << 19)).modifiers == .option)
    }

    @Test func needsAModifierUnlessItsAFunctionKey() {
        #expect(!KeyCombo(keyCode: 49, modifiers: []).isUsable)
        #expect(!KeyCombo(keyCode: 0, modifiers: .shift).isUsable)
        #expect(KeyCombo(keyCode: 0, modifiers: .control).isUsable)
        #expect(KeyCombo(keyCode: 122, modifiers: []).isUsable)
    }

    @Test func roundTripsThroughJSON() throws {
        let combo = KeyCombo(keyCode: 49, modifiers: [.command])
        #expect(try JSONDecoder().decode(KeyCombo.self, from: JSONEncoder().encode(combo)) == combo)
    }
}

@Suite struct LayoutTests {
    let size = PanelSize.medium

    @Test func theFieldAloneIsOneCapsule() {
        #expect(size.height(rows: 0, headers: 0, visible: 8) == size.fieldHeight)
        #expect(size.fieldRadius * 2 == size.fieldHeight)
    }

    @Test func theCardSitsBelowTheFieldWithAGap() {
        let card = size.cardHeight(rows: 2, headers: 1, visible: 8)
        #expect(size.height(rows: 2, headers: 1, visible: 8) == size.fieldHeight + size.gap + card)
        #expect(card == 2 * size.rowHeight + size.headerHeight + 2 * size.cardPadding)
    }

    @Test func growsWithResultsUntilItScrolls() {
        #expect(size.height(rows: 3, headers: 2, visible: 8) < size.height(rows: 8, headers: 2, visible: 8))
        #expect(size.height(rows: 9, headers: 3, visible: 8) == size.height(rows: 30, headers: 5, visible: 8))
    }

    @Test func theSelectionsCornersNestInTheCards() {
        #expect(PanelSize.allCases.allSatisfy { $0.rowRadius + $0.cardPadding == $0.cardRadius })
    }

    @Test func everySizeIsSmallerThanSpotlight() {
        // Spotlight on macOS 26 is about 680 points wide.
        #expect(PanelSize.allCases.allSatisfy { $0.width < 680 })
    }
}

@Suite struct FileResultsTests {
    let now = Date(timeIntervalSince1970: 1_000_000)
    let home = "/Users/me"

    func found(_ path: String, folder: Bool = false, used: TimeInterval? = 0) -> FileResults.Found {
        FileResults.Found(path: path, isFolder: folder, lastUsed: used.map { now.addingTimeInterval(-$0) })
    }

    @Test func aFileSpotlightListsTwiceShowsOnce() {
        let results = FileResults.candidates(
            [found("/Users/me/Notes/calculators", folder: true), found("/Users/me/Notes/calculators", folder: true)],
            home: home, now: now)
        #expect(results.count == 1)
    }

    @Test func leavesOutClutter() {
        let results = FileResults.candidates(
            [
                found("/Users/me/Library/Caches/x.txt"), found("/Users/me/.config/x.txt"),
                found("/Users/me/code/app/target/doc/x.js"), found("/Users/me/code/web/node_modules/x/index.js"),
                found("/Users/me/Documents/x.txt"),
            ], home: home, now: now)
        #expect(results.map(\.item.title) == ["x.txt"])
        #expect(results.first?.item.subtitle == "~/Documents")
    }

    @Test func abbreviatesOnlyTheHomeFolderItself() {
        let results = FileResults.candidates(
            [found("/Users/me/a.txt"), found("/Users/me2/b.txt"), found("/Volumes/Disk/c.txt")], home: home, now: now)
        #expect(results.map(\.item.subtitle) == ["~", "/Users/me2", "/Volumes/Disk"])
    }

    @Test func recentlyUsedFilesRankHigherThanNeverOpenedOnes() {
        let results = FileResults.candidates(
            [
                found("/Users/me/week.txt", used: 3600), found("/Users/me/old.txt", used: 400 * 86400),
                found("/Users/me/generated.txt", used: nil),
            ], home: home, now: now)
        #expect(results.map(\.weight) == [8, 0, -12])
    }

    @Test func foldersAreFolders() {
        let results = FileResults.candidates([found("/Users/me/Projects", folder: true)], home: home, now: now)
        #expect(results.first?.item.kind == .folder)
        #expect(results.first?.item.fileURL?.hasDirectoryPath == true)
    }
}

@Suite struct PlacesTests {
    let now = Date(timeIntervalSince1970: 1_000_000)
    let home = "/Users/me"
    var options: SearchOptions {
        var options = SearchOptions()
        options.locale = Locale(identifier: "en_US")
        options.webSearch = false
        return options
    }

    /// The places `Places.standard` lists, for a home folder at /Users/me.
    var places: [Candidate] {
        let main = [
            "/Applications", "/System/Applications/Utilities", home, "\(home)/Desktop", "\(home)/Documents",
            "\(home)/Downloads", "\(home)/Pictures", "\(home)/Movies", "\(home)/Music", "\(home)/Library",
            "\(home)/Library/Mobile Documents/com~apple~CloudDocs", "\(home)/Public",
        ].map { (path: $0, weight: Places.mainWeight) }
        let system = [
            ("/System/Applications", Places.systemWeight), ("/Applications/Utilities", Places.systemWeight),
            ("/Library", Places.systemWeight), ("/System/Library", Places.systemWeight - 1),
        ].map { (path: $0.0, weight: $0.1) }
        return Places.candidates(
            (main + system).map {
                Places.Place(url: URL(filePath: $0.path, directoryHint: .isDirectory), weight: $0.weight)
            },
            home: home, yieldingTo: [app("Music"), app("Safari")],
            displayName: { $0.lastPathComponent == "com~apple~CloudDocs" ? "iCloud Drive" : $0.lastPathComponent })
    }

    func folder(_ path: String, used: TimeInterval?) -> FileResults.Found {
        FileResults.Found(path: path, isFolder: true, lastUsed: used.map { now.addingTimeInterval(-$0) })
    }

    /// What Spotlight's home-scoped query returned for "applications" on a real Mac, plus a backup copy
    /// opened this month and a folder inside an app.
    var spotlightApplications: [FileResults.Found] {
        [
            folder("/Users/me/Applications", used: 3600),
            folder("/Users/me/Code/brand/app/(chapters)/applications", used: nil),
            folder("/Users/me/Code/brand/components/applications", used: nil),
            folder("/Users/me/Backups/Old Mac/Applications", used: 10 * 86400),
            folder("/Users/me/Code/Foo.app/Contents/Applications", used: 3600),
        ]
    }

    func ranked(
        _ query: String, apps: [Candidate] = [], found: [FileResults.Found] = [], usage: Usage = Usage(),
        scope: Scope = .all
    ) -> [Ranked] {
        var options = options
        options.scope = scope
        return Results.compose(
            query: query, candidates: apps, files: FileResults.candidates(found, home: home, now: now),
            places: places, usage: usage, now: now, options: options
        ).rows
    }

    func paths(_ rows: [Ranked]) -> [String] { rows.compactMap { $0.item.fileURL?.path } }

    @Test func theMainApplicationsFolderWinsItsName() {
        let rows = ranked("applications", found: spotlightApplications)
        print("applications:", rows.map { "\($0.item.fileURL!.path) \($0.score)" })
        #expect(
            paths(rows) == [
                "/Applications", "/Users/me/Applications", "/System/Applications",
                "/Users/me/Backups/Old Mac/Applications", "/Users/me/Code/brand/components/applications",
            ])
        // Without the places, the folder opened this week came first and /Applications not at all.
        let spotlightOnly = Ranker.rank(
            FileResults.candidates(spotlightApplications, home: home, now: now), query: "applications",
            usage: Usage(), now: now, limit: 5)
        #expect(paths(spotlightOnly).first == "/Users/me/Applications")
    }

    @Test func eachMainFolderWinsItsName() {
        // Each with a look-alike opened in the last hour.
        let cases = [
            ("utilities", "/System/Applications/Utilities", "/Users/me/Code/site/src/css/utilities"),
            ("downloads", "/Users/me/Downloads", "/Users/me/tensorflow_datasets/downloads"),
            ("documents", "/Users/me/Documents", "/Users/me/Code/app/Documents"),
            ("desktop", "/Users/me/Desktop", "/Users/me/Backups/Desktop"),
            ("pictures", "/Users/me/Pictures", "/Users/me/Backups/Pictures"),
            ("movies", "/Users/me/Movies", "/Users/me/Backups/Movies"),
            ("public", "/Users/me/Public", "/Users/me/Code/site/public"),
            (
                "icloud drive", "/Users/me/Library/Mobile Documents/com~apple~CloudDocs",
                "/Users/me/Backups/iCloud Drive"
            ),
            ("home", "/Users/me", "/Users/me/Code/home"),
            ("me", "/Users/me", "/Users/me/Code/me"),
        ]
        for (query, main, lookAlike) in cases {
            #expect(paths(ranked(query, found: [folder(lookAlike, used: 3600)])).first == main, "\(query)")
        }
    }

    @Test func theHomeLibraryComesBeforeTheSystemOnes() {
        let rows = ranked("library", found: [folder("/Users/me/Code/max/Library", used: 3600)])
        #expect(
            paths(rows) == [
                "/Users/me/Library", "/Users/me/Code/max/Library", "/Library", "/System/Library",
            ])
    }

    @Test func appsKeepTheirNames() {
        let safari = ranked("safari", apps: [app("Safari")], found: [folder("/Users/me/Projects/Safari", used: nil)])
        #expect(safari.first?.item.kind == .application)
        // A place named like an app yields to it, and still leads the folders.
        let music = ranked("music", apps: [app("Music")], found: [folder("/Users/me/Backups/Music", used: 40 * 86400)])
        #expect(music.map(\.item.id) == ["app:Music", "file:/Users/me/Music", "file:/Users/me/Backups/Music"])
    }

    @Test func choosingAnotherFolderStillWins() throws {
        let before = ranked("applications", found: spotlightApplications)
        let main = try #require(before.first { $0.item.id == "file:/Applications" })
        let mine = try #require(before.first { $0.item.id == "file:/Users/me/Applications" })
        #expect(main.score - mine.score == Places.mainWeight - 8)

        var usage = Usage()
        usage.record(mine.item.id, query: "applications", at: now)
        let after = ranked("applications", found: spotlightApplications, usage: usage)
        print("after choosing ~/Applications:", after.map { "\($0.item.fileURL!.path) \($0.score)" })
        #expect(after.first?.item.id == mine.item.id)
        // The choice (+120) and one use (+12) against the place's lead of 2.
        #expect(after.first!.score == mine.score + Usage.choiceBoost + 12)

        // Opened often enough under other queries, frecency alone overtakes it too.
        var frequent = Usage()
        for _ in 0..<3 { frequent.record(mine.item.id, query: "", at: now) }
        #expect(ranked("applications", found: spotlightApplications, usage: frequent).first?.item.id == mine.item.id)
    }

    @Test func spotlightsCopyOfAPlaceShowsOnce() {
        let rows = ranked("downloads", found: [folder("/Users/me/Downloads", used: 3600)])
        #expect(rows.filter { $0.item.id == "file:/Users/me/Downloads" }.count == 1)
        #expect(rows.first?.score == Fuzzy.match("downloads", in: SearchText("Downloads"))!.score + Places.mainWeight)
    }

    @Test func placesStayOutOfOtherScopesAndTheRecentList() {
        #expect(ranked("applications", apps: [app("Safari")], scope: .apps).isEmpty)
        #expect(
            ranked("", found: [folder("/Users/me/Projects", used: 60)], scope: .files).map(\.item.title) == ["Projects"]
        )
        #expect(paths(ranked("applications", scope: .files)).first == "/Applications")
    }

    @Test func aLocalisedNameStillMatchesTheFolderName() {
        let downloads = Places.candidates(
            [Places.Place(url: URL(filePath: "/Users/me/Downloads"), weight: Places.mainWeight)], home: home,
            displayName: { _ in "Téléchargements" })
        #expect(downloads.first?.item.title == "Téléchargements")
        #expect(Ranker.rank(downloads, query: "downl", usage: Usage(), now: now, limit: 1).count == 1)
        #expect(downloads.first?.item.subtitle == "~")
    }

    @Test func deeperLookAlikesRankLower() {
        #expect(FileResults.depthPenalty("/Users/me/Projects", home: home) == 0)
        #expect(FileResults.depthPenalty("/Users/me/Code/Projects", home: home) == 0)
        #expect(FileResults.depthPenalty("/Users/me/a/b/Projects", home: home) == 1)
        #expect(FileResults.depthPenalty("/Users/me/a/b/c/d/e/f/g/Projects", home: home) == 3)
        #expect(FileResults.depthPenalty("/Projects", home: home) == 0)
        #expect(FileResults.depthPenalty("/Volumes/Disk/Projects", home: home) == 1)
        // Files keep their weight; only folders are ordered by depth.
        let file = FileResults.candidates(
            [FileResults.Found(path: "/Users/me/a/b/c/d/notes.txt", isFolder: false, lastUsed: nil)], home: home,
            now: now)
        #expect(file.first?.weight == -12)
    }

    @Test func theStandardPlacesAreThisMacsRealFolders() {
        let places = Places.standard()
        let paths = places.map(\.url.path)
        #expect(paths.first == "/Applications")
        #expect(paths.contains(FileManager.default.homeDirectoryForCurrentUser.path))
        #expect(paths.contains("/System/Library"))
        #expect(!paths.contains { $0.contains("Cryptexes") })
        #expect(Set(paths).count == paths.count)
        #expect(places.allSatisfy { FileManager.default.fileExists(atPath: $0.url.path) })
    }
}
