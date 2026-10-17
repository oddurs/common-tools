import CommonTesting
import Foundation
import Testing

@Suite struct CommonTestingTests {
    @Test func everyAppKeepsTheContract() throws {
        // Each app checks itself too; this catches a change here that breaks the check for all of them.
        let contract = try AppContract(slug: "stats")
        let apps =
            try JSONSerialization.jsonObject(
                with: Data(contentsOf: contract.repository.appending(path: "apps.json"))) as? [String: Any]
        for slug in try #require(apps).keys.sorted() {
            let violations = try AppContract(slug: slug).violations()
            #expect(violations.isEmpty, "\(slug): \(violations)")
        }
    }

    @Test func anUnknownAppIsOneViolation() throws {
        #expect(try AppContract(slug: "nope").violations() == ["apps.json has no entry for nope"])
    }

    @Test func benchmarksReportTheFastestBatch() {
        var calls = 0
        let us = Benchmark.microseconds(iterations: 10, batches: 3) { calls += 1 }
        #expect(calls == 31)  // one warm-up call, then three batches of ten
        #expect(us >= 0 && us < 1000)
    }
}
