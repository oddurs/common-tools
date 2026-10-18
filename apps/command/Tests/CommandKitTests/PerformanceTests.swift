import CommonTesting
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

    @Test func scanningTheApplicationsFoldersIsFast() {
        let us = Benchmark.microseconds(iterations: 3) { _ = AppCatalog.scan() }
        print("scan apps: \(String(format: "%.0f", us)) µs")
        #expect(us < 500_000)
    }
}
