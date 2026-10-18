import AppKit
import Testing

@testable import CommandKit

@Suite struct CatalogCacheTests {
    @Test func joinsOnceAndRejoinsWhenAListChanges() {
        var catalog = Catalog()
        catalog.apps = [app("Safari")]
        catalog.panes = [app("Bluetooth", weight: 0)]
        catalog.appActions = Actions.appActions([
            Actions.RunningApp(
                name: "Mail", bundleIdentifier: "com.apple.mail", url: URL(filePath: "/Applications/Mail.app"))
        ])
        #expect(titles(catalog) == ["Safari", "Bluetooth", "Quit Mail", "Hide Mail"])
        #expect(catalog.candidates(includingPanes: false, includingActions: false).map(\.item.title) == ["Safari"])
        catalog.apps.append(app("Notes"))
        #expect(titles(catalog) == ["Safari", "Notes", "Bluetooth", "Quit Mail", "Hide Mail"])
        catalog.appActions = []
        #expect(titles(catalog) == ["Safari", "Notes", "Bluetooth"])
    }

    func titles(_ catalog: Catalog) -> [String] {
        var catalog = catalog
        return catalog.candidates(includingPanes: true, includingActions: true).map(\.item.title)
    }
}

@Suite struct RunningAppsTests {
    func application(_ path: String, id: String? = nil) -> Item {
        Item(
            id: id ?? "app:" + path, title: "App", subtitle: "", kind: .application, action: .open(URL(filePath: path)))
    }

    @Test func findsARunningAppWhateverTheURLsTrailingSlash() {
        let running = RunningApps(bundles: [URL(string: "file:///Applications/Mail.app/")!])
        #expect(running.contains(application("/Applications/Mail.app")))
        #expect(!running.contains(application("/Applications/Notes.app")))
    }

    @Test func findsAnAppListedThroughASymlink() {
        // AppCatalog lists /Applications/Safari.app, a symlink, with the resolved path as its id.
        let running = RunningApps(bundles: [URL(filePath: "/System/Cryptexes/App/System/Applications/Safari.app")])
        #expect(
            running.contains(
                application("/Applications/Safari.app", id: "app:/System/Cryptexes/App/System/Applications/Safari.app"))
        )
    }

    @Test func onlyAppsRun() {
        let running = RunningApps(bundles: [URL(filePath: "/Applications/Mail.app")])
        let file = Item(
            id: "file:/Applications/Mail.app", title: "Mail.app", subtitle: "", kind: .file,
            action: .open(URL(filePath: "/Applications/Mail.app")))
        #expect(!running.contains(file))
    }

    @Test func comparesWhatChanged() {
        let mail = Actions.RunningApp(
            name: "Mail", bundleIdentifier: "com.apple.mail", url: URL(filePath: "/Applications/Mail.app"))
        #expect(RunningApps(actions: [mail], bundles: [mail.url]) == RunningApps(actions: [mail], bundles: [mail.url]))
        #expect(RunningApps(actions: [mail], bundles: [mail.url]) != RunningApps(actions: [], bundles: [mail.url]))
    }
}

@Suite struct IconCacheTests {
    let finder = "/System/Library/CoreServices/Finder.app"

    @Test func drawsAnIconAtRowSizeOffTheMainThread() async throws {
        let cache = IconCache()
        await Task.detached { cache.prerender([finder]) }.value
        let image = try #require(cache.image(forPath: finder))
        #expect(image.width == IconCache.pixels && image.height == IconCache.pixels)
        #expect(IconCache.pixels == Int(PanelSize.large.iconSize * 2))
    }

    @Test func leavesWhatItHasAlone() {
        let cache = IconCache()
        cache.prerender([finder])
        let first = cache.image(forPath: finder)
        cache.prerender([finder])
        #expect(cache.image(forPath: finder) === first)
    }
}

extension IconCacheTests {
    @Test func forgetsEverythingWhenTheAppearanceChanges() {
        let cache = IconCache()
        cache.prerender([finder])
        cache.removeAll()
        #expect(cache.image(forPath: finder) == nil)
    }
}
