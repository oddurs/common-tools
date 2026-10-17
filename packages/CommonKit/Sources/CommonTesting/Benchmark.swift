import Foundation

/// Microbenchmarks as regression gates, not benchmarks of record. A gate catches an accidental
/// quadratic loop, a per-draw text measurement or a syscall storm; it doesn't track a few percent.
/// Set each budget about ten times above what a quiet M-series Mac measures, so a busy CI runner
/// can't fail it.
public enum Benchmark {
    /// The mean cost of one `body` call, in microseconds, from the fastest of `batches` batches of
    /// `iterations` calls. Other work on the machine can only slow a batch down, never speed one
    /// up, so the fastest batch is the closest to the code's own cost; a mean over everything let
    /// one busy moment fail a gate, and a median still drifts under sustained load.
    public static func microseconds(iterations: Int = 100, batches: Int = 5, _ body: () -> Void) -> Double {
        body()  // Warm caches, lazy registries and the like.
        var fastest = UInt64.max
        for _ in 0..<batches {
            let start = DispatchTime.now().uptimeNanoseconds
            for _ in 0..<iterations { body() }
            fastest = min(fastest, DispatchTime.now().uptimeNanoseconds - start)
        }
        return Double(fastest) / Double(iterations) / 1000
    }
}
