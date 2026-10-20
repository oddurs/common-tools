import Foundation
import IOKit

/// Which logical cores belong to which of the kernel's performance levels, and
/// what the kernel calls each level.
///
/// The kernel names its levels in `hw.perflevelN.name` ("Performance" and
/// "Efficiency" on M1–M4, "Super" and "Performance" on M5) and counts each one's
/// cores and L2 cache. Apple Silicon's device tree tags every core with a
/// `cluster-type` and its `l2-cache-size` under its `logical-cpu-id`, which is the
/// index `host_processor_info` uses. Verified by confining busy loops to
/// efficiency cores with `taskpolicy -b` and watching exactly those indices
/// saturate. The tags are opaque letters ("E", "P", "M", …); a tag's cores are
/// the level with their count and L2 size, so no letter is ever interpreted.
public struct CPUTopology: Sendable, Equatable {
    public struct Cluster: Sendable, Equatable {
        /// The kernel's name for this performance level.
        public let name: String
        /// Logical core indices, ascending.
        public let cores: [Int]
    }

    /// One performance level, as `hw.perflevelN` reports it.
    struct Level: Sendable, Equatable {
        let name: String
        let logicalCPUs: Int
        let l2CacheSize: Int
    }

    /// One core, as the device tree reports it.
    struct Core: Sendable, Equatable {
        let id: Int
        let clusterType: String
        let l2CacheSize: Int
    }

    /// Clusters in core order, one per performance level; empty when unknown
    /// (Intel, or a device tree we can't read), in which case cores show ungrouped.
    public let clusters: [Cluster]

    public static let current = CPUTopology(levels: readLevels(), cores: readCores(), coreCount: ProcessInfo.processInfo.processorCount)

    /// Matches each cluster type to the one level with its core count and L2
    /// size. Anything inconsistent (a missing core, a count that doesn't match the
    /// kernel's, a cluster type that fits no level or more than one) yields no
    /// grouping rather than a wrong one.
    init(levels: [Level], cores: [Core], coreCount: Int) {
        let ids = cores.map(\.id)
        let named = Dictionary(grouping: cores, by: \.clusterType).values.compactMap { group -> Cluster? in
            let matches = levels.filter { level in
                level.logicalCPUs == group.count && group.allSatisfy { $0.l2CacheSize == level.l2CacheSize }
            }
            guard matches.count == 1 else { return nil }
            return Cluster(name: matches[0].name, cores: group.map(\.id).sorted())
        }
        guard levels.count > 1, ids.count == coreCount, Set(ids) == Set(0..<coreCount),
            named.count == levels.count, Set(named.map(\.name)).count == levels.count
        else {
            clusters = []
            return
        }
        clusters = named.sorted { $0.cores[0] < $1.cores[0] }
    }

    private static func readLevels() -> [Level] {
        let count: Int32 = sysctlValue("hw.nperflevels") ?? 0
        return (0..<count).compactMap { i in
            guard let name = sysctlString("hw.perflevel\(i).name"),
                let cpus: Int32 = sysctlValue("hw.perflevel\(i).logicalcpu"),
                let l2: Int32 = sysctlValue("hw.perflevel\(i).l2cachesize")
            else { return nil }
            return Level(name: name, logicalCPUs: Int(cpus), l2CacheSize: Int(l2))
        }
    }

    private static func readCores() -> [Core] {
        let cpus = IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:/cpus")
        guard cpus != 0 else { return [] }
        defer { IOObjectRelease(cpus) }
        var iterator: io_iterator_t = 0
        guard IORegistryEntryGetChildIterator(cpus, kIODeviceTreePlane, &iterator) == KERN_SUCCESS else { return [] }
        defer { IOObjectRelease(iterator) }

        var cores: [Core] = []
        while case let cpu = IOIteratorNext(iterator), cpu != 0 {
            defer { IOObjectRelease(cpu) }
            func property(_ key: String) -> Any? {
                IORegistryEntryCreateCFProperty(cpu, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
            }
            guard let id = (property("logical-cpu-id") as? NSNumber)?.intValue,
                let type = property("cluster-type") as? Data,
                let tag = String(bytes: type.prefix { $0 != 0 }, encoding: .ascii),
                let l2 = property("l2-cache-size") as? Data, l2.count == 4
            else { continue }
            // A device-tree cell: 32 bits, little-endian.
            let size = l2.reversed().reduce(0) { $0 << 8 | Int($1) }
            cores.append(Core(id: id, clusterType: tag, l2CacheSize: size))
        }
        return cores
    }
}
