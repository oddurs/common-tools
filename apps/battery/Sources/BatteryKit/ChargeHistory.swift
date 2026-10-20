import Foundation

/// The level over the last few hours, for the menu's chart. Samples carry their own time, so a
/// gap while the Mac slept shows as a gap instead of being squeezed out.
public struct ChargeHistory: Sendable {
    public struct Sample: Sendable, Equatable {
        public var time: Date
        public var level: Double
        public var charging: Bool

        public init(time: Date, level: Double, charging: Bool) {
            self.time = time
            self.level = level
            self.charging = charging
        }
    }

    /// How far back the chart reaches.
    public static let span: TimeInterval = 12 * 3600
    /// Samples closer than this to the last are dropped, so a burst of power-source events can't
    /// crowd older history out. At 12 hours across a menu's width a point covers about two
    /// minutes, so the chart can't show the lag; the menu's header shows the live level.
    public static let spacing: TimeInterval = 60

    public private(set) var samples: [Sample] = []

    public init() {}

    public mutating func record(_ reading: BatteryReading, at time: Date) {
        if let last = samples.last, time.timeIntervalSince(last.time) < Self.spacing { return }
        samples.append(Sample(time: time, level: reading.level, charging: reading.state == .charging))
        // At one sample a minute the window holds 720; dropping from the front is rare and short.
        let cutoff = time.addingTimeInterval(-Self.span)
        if let first = samples.firstIndex(where: { $0.time >= cutoff }), first > 0 {
            samples.removeFirst(first)
        }
    }

    /// Runs of samples with no gap longer than `gap` between neighbours, for drawing as separate lines.
    public func runs(gap: TimeInterval = 5 * 60) -> [ArraySlice<Sample>] {
        var runs: [ArraySlice<Sample>] = []
        var start = samples.startIndex
        for i in samples.indices.dropFirst() where samples[i].time.timeIntervalSince(samples[i - 1].time) > gap {
            runs.append(samples[start..<i])
            start = i
        }
        if start < samples.endIndex { runs.append(samples[start...]) }
        return runs
    }
}

/// Where the menu's chart puts each sample: oldest at the left, now at the right, full at the top.
public struct ChartFrame: Sendable {
    /// The dot drawn for a stretch with a single sample.
    public static let dotRadius: CGFloat = 2

    /// The rect the samples are plotted in, inset from the chart's edges so a dot on it stays whole.
    public let plot: CGRect

    /// `cornerRadius` is the chart's clip. A dot (and a point of clear space around it) at a corner
    /// of the plot sits on the corner arc's diagonal, so it must be inset by the radius less its
    /// distance along that diagonal; on a straight edge, by the dot's reach alone.
    public init(size: CGSize, cornerRadius: CGFloat) {
        let reach = Self.dotRadius + 1
        let inset = max(reach, cornerRadius - (cornerRadius - reach) / 2.squareRoot()).rounded(.up)
        plot = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
    }

    public func point(_ sample: ChargeHistory.Sample, now: Date) -> CGPoint {
        let start = now.addingTimeInterval(-ChargeHistory.span)
        return CGPoint(
            x: plot.minX + plot.width * sample.time.timeIntervalSince(start) / ChargeHistory.span,
            y: plot.minY + plot.height * (1 - min(max(sample.level, 0), 1)))
    }
}
