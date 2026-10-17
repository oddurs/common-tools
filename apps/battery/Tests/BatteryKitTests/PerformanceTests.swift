import AppKit
import Testing

@testable import BatteryKit

/// Regression gates, not benchmarks of record. Budgets sit roughly 10x above what an M-series Mac
/// measures, so they catch an accidental registry rematch or per-draw text measurement without
/// flaking on a busy CI runner.
@Suite(.serialized)
struct PerformanceTests {
    /// The median time of one call, which ignores the scheduler's stalls but still moves if every
    /// call gets slower.
    func medianMicroseconds(_ iterations: Int, _ body: () -> Void) -> Double {
        body()  // warm caches and the registry match
        let times = (0..<iterations).map { _ in
            let start = DispatchTime.now().uptimeNanoseconds
            body()
            return Double(DispatchTime.now().uptimeNanoseconds - start) / 1000
        }.sorted()
        return times[times.count / 2]
    }

    @Test func samplingIsCheap() {
        let sampler = BatterySampler()
        let us = medianMicroseconds(50) { _ = sampler.sample() }
        print("sample: \(String(format: "%.0f", us)) µs")
        #expect(us < 10_000)
    }

    @Test func drawingIsCheap() throws {
        let renderer = BarRenderer(
            appearance: BarAppearance(style: .percentInIcon, showsTime: true, colorsAlerts: true), height: 24)
        let rep = try #require(
            NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: 120, pixelsHigh: 48, bitsPerSample: 8, samplesPerPixel: 4,
                hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        let context = try #require(NSGraphicsContext(bitmapImageRep: rep))
        let reading = BatteryReading(level: 0.45, state: .charging, minutesRemaining: 52)
        let us = medianMicroseconds(200) {
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = context
            renderer.image(reading).draw(in: CGRect(origin: .zero, size: renderer.size))
            NSGraphicsContext.restoreGraphicsState()
        }
        print("draw: \(String(format: "%.0f", us)) µs")
        #expect(us < 3_000)
    }
}
