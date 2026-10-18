import CommonTesting
import CoreGraphics
import Foundation
import Testing

@testable import CommandKit

/// Regression gates, not benchmarks of record. Budgets sit roughly 10x above what an M-series Mac
/// measures, so they catch an accidental quadratic loop without flaking on a busy CI runner.
@Suite(.serialized)
struct PerformanceTests {
    /// Two thousand plausible names: far more apps and panes than any Mac has.
    static let catalog: [Candidate] = {
        let words = [
            "Safari", "Mail", "Studio", "Code", "Visual", "System", "Settings", "Photo", "Pro", "Music", "Notes",
            "Terminal", "Utility", "Disk", "Activity", "Monitor", "Preview", "Calendar", "Messages", "Final",
        ]
        // Deterministic, so every run measures the same work.
        return (0..<2000).map { i in
            let name = (0...(i % 4)).map { k in words[(i * 7 + k * 13) % words.count] }.joined(separator: " ")
            return app("\(name) \(i)")
        }
    }()

    /// About 0.6 ms in a release build on an M4 Pro, and 10 ms in the debug build the suite runs.
    @Test(arguments: ["s", "vsc", "system settings", "zzz"])
    func rankingTheWholeCatalogTakesWellUnderAFrame(query: String) {
        let catalog = Self.catalog
        let now = Date()
        let us = Benchmark.microseconds(iterations: 4) {
            _ = Ranker.rank(catalog, query: query, usage: Usage(), now: now, limit: 8)
        }
        print("rank 2,000 for \"\(query)\": \(String(format: "%.0f", us)) µs")
        #expect(us < 40_000)
    }

    /// A keystroke's whole ranking: the catalog, a full page of Spotlight folders, and the places among them.
    @Test func composingWithFilesAndPlacesTakesWellUnderAFrame() {
        let catalog = Self.catalog
        let now = Date()
        let files = FileResults.candidates(
            // 60 is the cap FileSearch puts on a Spotlight query.
            (0..<60).map {
                FileResults.Found(path: "/Users/me/Code/project \($0)/Library", isFolder: true, lastUsed: nil)
            }, home: "/Users/me", now: now)
        let places = Places.candidates(Places.standard(), home: "/Users/me")
        let us = Benchmark.microseconds(iterations: 4) {
            _ = Results.compose(
                query: "library", candidates: catalog, files: files, places: places, usage: Usage(), now: now,
                options: SearchOptions())
        }
        print("compose 2,000 + \(files.count) files + \(places.count) places: \(String(format: "%.0f", us)) µs")
        #expect(us < 40_000)
    }

    /// Each keystroke asks for the whole catalog; it is joined once, not copied every time. About 0.1 ms
    /// a keystroke for a real catalog when it was rejoined.
    @Test func askingForTheCatalogIsFreeUntilItChanges() {
        var catalog = Catalog()
        catalog.apps = Self.catalog
        catalog.panes = Self.catalog
        _ = catalog.candidates(includingPanes: true, includingActions: true)
        let us = Benchmark.microseconds(iterations: 4) {
            for _ in 0..<100 { _ = catalog.candidates(includingPanes: true, includingActions: true) }
        }
        print("catalog x100: \(String(format: "%.0f", us)) µs")
        #expect(us < 1_000)
    }

    /// SwiftUI builds the action menu of every row each time the list draws. Asking the system which apps
    /// run took about 0.8 ms a row; the set answers a full list in microseconds.
    @Test func theActionMenuOfAFullListIsCheap() {
        let bundles = (0..<120).map { URL(filePath: "/Applications/App \($0).app") }
        let running = RunningApps(bundles: bundles)
        let rows = (0..<20).map { app("App \($0 * 7)") }
        let us = Benchmark.microseconds(iterations: 4) {
            for row in rows { _ = ItemCommand.commands(for: row.item, isRunning: running.contains(row.item)) }
        }
        print("action menus for 20 rows: \(String(format: "%.0f", us)) µs")
        #expect(us < 2_000)
    }

    /// A prerendered icon is a small bitmap; drawing one costs microseconds, not the 7–20 ms Icon Services
    /// takes the first time it draws an app's icon.
    @Test func drawingAPrerenderedIconIsCheap() throws {
        let cache = IconCache()
        cache.prerender(["/System/Library/CoreServices/Finder.app"])
        let icon = try #require(cache.image(forPath: "/System/Library/CoreServices/Finder.app"))
        let context = try #require(
            CGContext(
                data: nil, width: 48, height: 48, bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        let us = Benchmark.microseconds(iterations: 20) {
            context.draw(icon, in: CGRect(x: 0, y: 0, width: 48, height: 48))
        }
        print("draw prerendered icon: \(String(format: "%.0f", us)) µs")
        #expect(us < 2_000)
    }

    @Test func scanningTheApplicationsFoldersIsFast() {
        let us = Benchmark.microseconds(iterations: 3) { _ = AppCatalog.scan() }
        print("scan apps: \(String(format: "%.0f", us)) µs")
        #expect(us < 500_000)
    }
}
