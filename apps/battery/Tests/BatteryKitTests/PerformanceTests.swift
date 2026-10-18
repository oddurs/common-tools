import AppKit
import CommonTesting
import Testing

@testable import BatteryKit

/// Regression gates, not benchmarks of record. Budgets sit roughly 10x above what an M-series Mac
/// measures, so they catch an accidental registry rematch or per-draw text measurement without
/// flaking on a busy CI runner.
@Suite(.serialized)
struct PerformanceTests {
    @Test func samplingIsCheap() {
        let sampler = BatterySampler()
        let us = Benchmark.microseconds(iterations: 10) { _ = sampler.sample() }
        print("sample: \(String(format: "%.0f", us)) µs")
        #expect(us < 10_000)
    }

    @Test func drawingIsCheap() throws {
        let renderer = BarRenderer(
            appearance: BarAppearance(parts: [.time, .percent, .battery], iconStyle: .percentInside), height: 24)
        let rep = try #require(
            NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: 120, pixelsHigh: 48, bitsPerSample: 8, samplesPerPixel: 4,
                hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        let context = try #require(NSGraphicsContext(bitmapImageRep: rep))
        let reading = BatteryReading(level: 0.45, state: .charging, minutesRemaining: 52)
        let us = Benchmark.microseconds(iterations: 40) {
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = context
            renderer.image(reading).draw(in: CGRect(origin: .zero, size: renderer.size))
            NSGraphicsContext.restoreGraphicsState()
        }
        print("draw: \(String(format: "%.0f", us)) µs")
        #expect(us < 3_000)
    }
}
