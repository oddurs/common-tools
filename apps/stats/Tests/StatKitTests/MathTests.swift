import Foundation
import Testing

@testable import StatKit

struct CPUUsageTests {
    func ticks(_ user: UInt32, _ system: UInt32, _ idle: UInt32) -> CoreTicks {
        CoreTicks(user: user, system: system, idle: idle, nice: 0)
    }

    @Test func splitsUserAndSystemAcrossCores() throws {
        let old = [ticks(0, 0, 0), ticks(0, 0, 0)]
        let new = [ticks(30, 10, 60), ticks(0, 0, 100)]
        let usage = try #require(cpuUsage(from: old, to: new))
        #expect(usage.user == 0.15)
        #expect(usage.system == 0.05)
        #expect(usage.cores == [0.4, 0])
    }

    @Test func survivesCounterWraparound() throws {
        let old = [ticks(UInt32.max - 9, 0, UInt32.max - 9)]
        let new = [ticks(10, 0, 10)]  // 20 ticks of user, 20 of idle, across the wrap
        let usage = try #require(cpuUsage(from: old, to: new))
        #expect(usage.user == 0.5)
    }

    @Test func rejectsChangedCoreCount() {
        #expect(cpuUsage(from: [ticks(0, 0, 0)], to: [ticks(1, 1, 1), ticks(1, 1, 1)]) == nil)
        #expect(cpuUsage(from: [], to: [ticks(1, 1, 1)]) == nil)
    }

    @Test func noElapsedTicksIsIdleNotNaN() throws {
        let usage = try #require(cpuUsage(from: [ticks(5, 5, 5)], to: [ticks(5, 5, 5)]))
        #expect(usage.user == 0 && usage.system == 0 && usage.cores == [0])
    }
}

struct RateMeterTests {
    typealias Meter = RateMeter<String>

    @Test func firstSampleHasNoRate() {
        var meter = Meter()
        #expect(meter.update(["en0": (100, 100)], nanoseconds: 1) == nil)
    }

    @Test func dividesByElapsedTimeNotNominalInterval() throws {
        var meter = Meter()
        _ = meter.update(["en0": (0, 0)], nanoseconds: 1_000_000_000)
        let rates = meter.update(["en0": (3000, 1500)], nanoseconds: 2_500_000_000)
        let (down, up) = try #require(rates)
        #expect(down == 2000)
        #expect(up == 1000)
    }

    @Test func counterResetContributesNothing() throws {
        var meter = Meter()
        _ = meter.update(["en0": (5000, 5000)], nanoseconds: 0)
        let reset = meter.update(["en0": (10, 10)], nanoseconds: 1_000_000_000)
        #expect(try #require(reset) == (0, 0))
        let rates = meter.update(["en0": (1010, 10)], nanoseconds: 2_000_000_000)
        #expect(try #require(rates).0 == 1000)
    }

    @Test func switchingInterfaceRestartsBaseline() {
        var meter = Meter()
        _ = meter.update(["en0": (5000, 5000)], nanoseconds: 0)
        #expect(meter.update(["en7": (9_000_000, 0)], nanoseconds: 1_000_000_000) == nil)
    }

    @Test func diskAppearingMidStreamIsNotABurst() throws {
        // A 2 TB drive plugged in between samples must not read as 2 TB/s.
        var meter = RateMeter<UInt64>()
        _ = meter.update([1: (1000, 0)], nanoseconds: 0)
        let rates = meter.update([1: (3000, 0), 2: (2_000_000_000_000, 0)], nanoseconds: 1_000_000_000)
        #expect(try #require(rates).0 == 2000)
    }

    @Test func diskLeavingMidStreamIsNotANegativeRate() throws {
        var meter = RateMeter<UInt64>()
        _ = meter.update([1: (1000, 0), 2: (9_000_000, 0)], nanoseconds: 0)
        let rates = meter.update([1: (1500, 0)], nanoseconds: 1_000_000_000)
        #expect(try #require(rates).0 == 500)
    }

    @Test func longGapSuchAsSleepIsDiscarded() {
        var meter = Meter()
        _ = meter.update(["en0": (0, 0)], nanoseconds: 0)
        #expect(meter.update(["en0": (1, 1)], nanoseconds: 60_000_000_000) == nil)
    }
}

let en = Locale(identifier: "en_US")

struct FormatTests {
    @Test(arguments: [
        (0.0, "0 B"), (999, "999 B"), (1000, "1.0 KB"), (9_949, "9.9 KB"), (9_960, "10 KB"),
        (999_400, "999 KB"), (999_700, "1.0 MB"), (12_345_678, "12 MB"), (2.5e12, "2.5 TB"), (-5, "0 B"),
    ])
    func bytes(value: Double, expected: String) {
        #expect(Format.bytes(value, locale: en) == expected)
    }

    @Test func decimalsFollowTheRegion() {
        let de = Locale(identifier: "de_DE")
        #expect(Format.rate(4_000_000, locale: de) == "4,0 MB/s")
        #expect(Format.memory(1536 * 1024 * 1024, locale: de) == "1,5 GB")
        #expect(Format.rate(4_000_000, locale: en) == "4.0 MB/s")
    }

    @Test func percentClampsAndRounds() {
        #expect(Format.percent(0.004) == "0%")
        #expect(Format.percent(0.995) == "100%")
        #expect(Format.percent(1.7) == "100%")
        #expect(Format.percent(-1) == "0%")
    }

    @Test(arguments: [Double.nan, .infinity, -.infinity])
    func nonFiniteValuesShowADashInsteadOfTrapping(value: Double) {
        #expect(Format.percent(value) == Format.missing)
        #expect(Format.bytes(value) == Format.missing)
        #expect(Format.rate(value) == Format.missing)
        #expect(Format.uptime(value) == Format.missing)
    }

    @Test func durations() {
        #expect(Format.duration(minutes: 72) == "1:12")
        #expect(Format.duration(minutes: 5) == "0:05")
        #expect(Format.uptime(59) == "0m")
        #expect(Format.uptime(3 * 3600 + 120) == "3h 2m")
        #expect(Format.uptime(2 * 86400 + 5 * 3600) == "2d 5h")
    }

    @Test func noStringOutgrowsTheWidthTemplates() {
        // The renderer sizes rate cells from templates; every real output must fit one.
        var value = 1.0
        while value < 1e13 {
            let s = Format.rate(value, locale: en)
            #expect(s.count <= "888 KB/s".count, "\(s)")
            value *= 1.37
        }
    }
}

struct HistoryTests {
    @Test func keepsNewestInOrderOnceFull() {
        var h = History(capacity: 3)
        for v in 1...5 { h.append(Double(v)) }
        #expect(h.count == 3)
        #expect(h.suffix(3) == [3, 4, 5])
        #expect(h.suffix(2) == [4, 5])
        #expect(h.suffix(10) == [3, 4, 5])
        #expect(h.last == 5)
        #expect(h.max(last: 2) == 5)
    }

    @Test func emptyHistory() {
        let h = History(capacity: 4)
        #expect(h.last == nil)
        #expect(h.suffix(2).isEmpty)
        #expect(h.max(last: 4) == 0)
    }
}

struct MemoryFormatTests {
    @Test func reportsRAMInBinaryUnitsLikeApple() {
        #expect(Format.memory(24 * 1024 * 1024 * 1024) == "24 GB")
        #expect(Format.memory(16 * 1024 * 1024 * 1024) == "16 GB")
        #expect(Format.memory(1536 * 1024 * 1024, locale: en) == "1.5 GB")
        // The same quantity in decimal units, which is what the menu wrongly showed.
        #expect(Format.bytes(24 * 1024 * 1024 * 1024) == "26 GB")
    }
}

struct CPUTopologyTests {
    typealias Level = CPUTopology.Level
    typealias Core = CPUTopology.Core

    static let mb = 1024 * 1024

    /// A Mac as the kernel and its device tree describe it: `hw.perflevelN`, then
    /// the device tree's cores in logical order, as runs of one `cluster-type`.
    struct Fixture: Sendable, CustomTestStringConvertible {
        let chip: String
        let levels: [Level]
        let runs: [(type: String, count: Int, l2: Int)]
        let expected: [(name: String, cores: Range<Int>)]

        var testDescription: String { chip }

        var cores: [Core] {
            var id = 0
            return runs.flatMap { run in
                (0..<run.count).map { _ in
                    defer { id += 1 }
                    return Core(id: id, clusterType: run.type, l2CacheSize: run.l2)
                }
            }
        }
    }

    // M1–M4: published core counts and L2 sizes, in the order their device trees list them.
    // The M5 Pro is recorded from `sysctl hw.perflevel*` and `ioreg -p IODeviceTree` on one.
    static let fixtures: [Fixture] = [
        Fixture(
            chip: "M1",
            levels: [Level(name: "Performance", logicalCPUs: 4, l2CacheSize: 12 * mb), Level(name: "Efficiency", logicalCPUs: 4, l2CacheSize: 4 * mb)],
            runs: [("E", 4, 4 * mb), ("P", 4, 12 * mb)],
            expected: [("Efficiency", 0..<4), ("Performance", 4..<8)]),
        Fixture(
            chip: "M2",
            levels: [Level(name: "Performance", logicalCPUs: 4, l2CacheSize: 16 * mb), Level(name: "Efficiency", logicalCPUs: 4, l2CacheSize: 4 * mb)],
            runs: [("E", 4, 4 * mb), ("P", 4, 16 * mb)],
            expected: [("Efficiency", 0..<4), ("Performance", 4..<8)]),
        Fixture(
            chip: "M3 Pro",
            levels: [Level(name: "Performance", logicalCPUs: 6, l2CacheSize: 16 * mb), Level(name: "Efficiency", logicalCPUs: 6, l2CacheSize: 4 * mb)],
            runs: [("E", 6, 4 * mb), ("P", 6, 16 * mb)],
            expected: [("Efficiency", 0..<6), ("Performance", 6..<12)]),
        Fixture(
            chip: "M4 Pro",
            levels: [Level(name: "Performance", logicalCPUs: 10, l2CacheSize: 16 * mb), Level(name: "Efficiency", logicalCPUs: 4, l2CacheSize: 4 * mb)],
            runs: [("E", 4, 4 * mb), ("P", 10, 16 * mb)],
            expected: [("Efficiency", 0..<4), ("Performance", 4..<14)]),
        Fixture(
            chip: "M5 Pro",
            levels: [Level(name: "Super", logicalCPUs: 5, l2CacheSize: 16 * mb), Level(name: "Performance", logicalCPUs: 10, l2CacheSize: 8 * mb)],
            runs: [("M", 10, 8 * mb), ("P", 5, 16 * mb)],
            expected: [("Performance", 0..<10), ("Super", 10..<15)]),
    ]

    @Test(arguments: fixtures) func namesClustersAsTheKernelNamesItsPerformanceLevels(_ mac: Fixture) {
        let t = CPUTopology(levels: mac.levels, cores: mac.cores, coreCount: mac.cores.count)
        #expect(t.clusters.map(\.name) == mac.expected.map(\.name))
        #expect(t.clusters.map(\.cores) == mac.expected.map { Array($0.cores) })
    }

    @Test func incompleteOrMismatchedTopologyIsNotGuessed() throws {
        let m5 = try #require(Self.fixtures.last)
        let cores = m5.cores
        // A core missing from the device tree, or a kernel count that disagrees.
        #expect(CPUTopology(levels: m5.levels, cores: cores.filter { $0.id != 3 }, coreCount: 15).clusters.isEmpty)
        #expect(CPUTopology(levels: m5.levels, cores: cores, coreCount: 16).clusters.isEmpty)
        // A cluster type that no performance level accounts for.
        #expect(CPUTopology(levels: m5.levels, cores: cores.map { Core(id: $0.id, clusterType: $0.id == 0 ? "X" : $0.clusterType, l2CacheSize: $0.l2CacheSize) }, coreCount: 15).clusters.isEmpty)
        // Two levels the device tree can't tell apart.
        let twins = [Level(name: "Performance", logicalCPUs: 2, l2CacheSize: Self.mb), Level(name: "Efficiency", logicalCPUs: 2, l2CacheSize: Self.mb)]
        let even = (0..<4).map { Core(id: $0, clusterType: $0 < 2 ? "E" : "P", l2CacheSize: Self.mb) }
        #expect(CPUTopology(levels: twins, cores: even, coreCount: 4).clusters.isEmpty)
        // A single level (Intel-like) has nothing to group.
        let one = [Level(name: "Performance", logicalCPUs: 2, l2CacheSize: Self.mb)]
        #expect(CPUTopology(levels: one, cores: (0..<2).map { Core(id: $0, clusterType: "P", l2CacheSize: Self.mb) }, coreCount: 2).clusters.isEmpty)
    }

    @Test func currentMachineIsConsistentWithSysctl() throws {
        let t = CPUTopology.current
        let levels: Int32 = sysctlValue("hw.nperflevels") ?? 1
        guard levels > 1 else {
            #expect(t.clusters.isEmpty)
            return
        }
        // Every performance level is one cluster, under the kernel's name, with the kernel's count.
        let counts = Dictionary(uniqueKeysWithValues: t.clusters.map { ($0.name, $0.cores.count) })
        #expect(counts.count == Int(levels))
        for level in 0..<levels {
            let name = try #require(sysctlString("hw.perflevel\(level).name"))
            let cpus: Int32 = try #require(sysctlValue("hw.perflevel\(level).logicalcpu"))
            #expect(counts[name] == Int(cpus))
        }
    }
}

struct SmoothingTests {
    func history(_ values: [Double], capacity: Int = 10) -> History {
        var h = History(capacity: capacity)
        values.forEach { h.append($0) }
        return h
    }

    @Test func meanOfTheNewestValues() {
        let h = history([1, 2, 3, 4])
        #expect(h.mean(last: 2) == 3.5)
        #expect(h.mean(last: 99) == 2.5)
        #expect(History(capacity: 3).mean(last: 2) == nil)
    }

    @Test func trailingMeansAverageWhatHistoryExists() {
        let h = history([0, 10, 20, 30, 40])
        #expect(h.trailingMeans(last: 5, window: 2) == [0, 5, 15, 25, 35])
        #expect(h.trailingMeans(last: 2, window: 3) == [20, 30])  // reaches back before the output range
        #expect(h.trailingMeans(last: 3, window: 1) == [20, 30, 40])
    }

    @Test func trailingMeansAcrossTheRingBufferSeam() {
        let h = history([5, 5, 0, 10, 20], capacity: 3)  // holds 0, 10, 20
        #expect(h.trailingMeans(last: 3, window: 2) == [0, 5, 15])
    }

    @Test func windowFollowsTheUpdateInterval() {
        #expect(Smoothing.off.window(interval: 1) == 1)
        #expect(Smoothing.medium.window(interval: 1) == 10)
        #expect(Smoothing.medium.window(interval: 2) == 5)
        #expect(Smoothing.short.window(interval: 5) == 1)  // shorter than one sample is raw
    }

    @Test func readoutAveragesOnlyWhenAsked() {
        var r = Readout()
        for v in [0.1, 0.3, 0.5] {
            var s = Snapshot()
            s.gpu = v
            s.network = RateReading(inbound: v * 1000, outbound: v * 100)
            r.ingest(s)
        }
        #expect(r.fraction(.gpu, window: 1) == 0.5)
        #expect(abs((r.fraction(.gpu, window: 3) ?? 0) - 0.3) < 1e-12)
        #expect(r.valueText(.gpu, window: 3) == "30%")
        let rates = r.rates(.network, window: 2)
        #expect(abs((rates?.inbound ?? 0) - 400) < 1e-9)
        #expect(abs((rates?.outbound ?? 0) - 40) < 1e-9)
    }

    @Test func layoutsWithoutSmoothingDecodeAsOff() throws {
        let l = try JSONDecoder().decode(BarLayout.self, from: Data(#"{"smoothing":"forever"}"#.utf8))
        #expect(l.smoothing == .off)
    }

    @Test func barShowsTheAverageWhenSmoothing() {
        var r = Readout()
        for v in [0.2, 0.4] {
            var s = Snapshot()
            s.cpu = CPUReading(user: v, system: 0, cores: [v], loadAverage: (0, 0, 0))
            r.ingest(s)
        }
        var layout = BarLayout.standard
        layout.smoothing = .short
        #expect(BarRenderer(layout: layout, height: 22).accessibilityText(r).contains("CPU 30%"))
        layout.smoothing = .off
        #expect(BarRenderer(layout: layout, height: 22).accessibilityText(r).contains("CPU 40%"))
    }
}
