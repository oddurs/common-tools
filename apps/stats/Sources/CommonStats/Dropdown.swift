import CommonUI
import StatKit
import SwiftUI

/// What the dropdown shows: a card per metric that has a history worth
/// graphing, in menu bar order, then one row of compact gauge tiles for the
/// slow-moving ones. Each panel becomes its own menu item.
enum DropdownPanel: Hashable {
    case card(Metric)
    case tiles([Metric])

    static var width: CGFloat { Tokens.Layout.menuPanelWidth }
    /// The menu item's inset around each panel.
    static var inset: CGFloat { Tokens.Space.xs }

    static func panels(for metrics: [Metric]) -> [DropdownPanel] {
        let tiles = metrics.filter(\.isTile)
        return metrics.filter { !$0.isTile }.map(DropdownPanel.card) + (tiles.isEmpty ? [] : [.tiles(tiles)])
    }
}

extension Metric {
    /// Single current values that read best as a gauge rather than a graph.
    var isTile: Bool { self == .gpu || self == .storage || self == .battery }
}

/// The menu's view of the model. Reading `model.readout` here is what makes
/// an open menu redraw on each sample; `PanelView` is a pure function of a
/// readout, so the snapshot tool can render it offscreen.
struct LivePanel: View {
    let model: AppModel
    let panel: DropdownPanel

    var body: some View {
        PanelView(readout: model.readout, panel: panel, interval: model.layout.interval, palette: model.layout.palette)
    }
}

struct PanelView: View {
    let readout: Readout
    let panel: DropdownPanel
    let interval: TimeInterval
    let palette: Palette
    var previewHover: Int?

    var body: some View {
        Group {
            switch panel {
            case .card(let metric):
                MetricCard(
                    readout: readout, metric: metric, interval: interval, ink: Ink(palette, metric),
                    previewHover: previewHover)
            case .tiles(let metrics):
                HStack(spacing: Tokens.Space.xs) {
                    ForEach(metrics, id: \.self) {
                        MetricTile(readout: readout, metric: $0, ink: Ink(palette, $0))
                    }
                }
            }
        }
        .padding(.horizontal, DropdownPanel.inset)
        .padding(.vertical, Tokens.Space.xxs)
        .frame(width: DropdownPanel.width)
    }
}

// MARK: - Cards

private struct MetricCard: View {
    let readout: Readout
    let metric: Metric
    let interval: TimeInterval
    let ink: Ink
    let previewHover: Int?

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                HStack(alignment: .center, spacing: Tokens.Space.xs) {
                    MetricSymbol(metric: metric, font: .body, width: 18)
                    Text(metric == .disk ? "Disk" : metric.name).font(.headline)
                        .lineLimit(1)
                    if metric == .network, let source = readout.latest.network?.source {
                        Text(source).font(.subheadline).foregroundStyle(.tertiary)
                    }
                    Spacer(minLength: Tokens.Space.xs)
                    headline
                }
                content
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var headline: some View {
        let big = Font.title3.weight(.semibold).monospacedDigit()
        switch metric {
        case .network, .disk:
            let r = readout.rates(metric)
            let (inGlyph, outGlyph) = metric == .network ? ("↓", "↑") : ("R", "W")
            // The glyphs take their graph colours, so the header doubles as the legend.
            HStack(spacing: Tokens.Space.xs) {
                Reading(glyph: inGlyph, value: r.map { Format.rate($0.inbound) }, ink: ink.strong)
                Reading(glyph: outGlyph, value: r.map { Format.rate($0.outbound) }, ink: ink.medium)
            }
            .font(.headline.monospacedDigit())
            .lineLimit(1)
            .fixedSize()
        case .memory:
            if let m = readout.latest.memory {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(Format.memory(m.used)).font(big)
                    Text("of \(Format.memory(m.total))").font(.subheadline).foregroundStyle(.secondary)
                }
            }
        default:
            Text(readout.valueText(metric)).font(big)
        }
    }

    @ViewBuilder private var content: some View {
        switch metric {
        case .cpu: cpu
        case .memory: memory
        case .network, .disk: rates
        case .gpu, .storage, .battery: EmptyView()
        }
    }

    @ViewBuilder private var cpu: some View {
        HistoryChart(
            up: [
                ChartSeries(name: "CPU", history: readout.primary[.cpu], ink: ink.strong, emphasis: true),
                ChartSeries(name: "System", history: readout.secondary[.cpu], ink: ink.soft, emphasis: false),
            ],
            scale: .fraction, interval: interval, format: Format.percent, previewHover: previewHover)
        if let c = readout.latest.cpu {
            Facts([
                Fact("User", Format.percent(c.user), key: ink.strong),
                Fact("System", Format.percent(c.system), key: ink.soft),
                Fact("Idle", Format.percent(1 - c.total)),
            ])
            CoreClusters(
                cores: c.cores, topology: .current, ink: ink.strong,
                width: DropdownPanel.width - 2 * (DropdownPanel.inset + Tokens.Layout.cardInset))
            Facts([
                Fact(
                    "Load",
                    [c.loadAverage.0, c.loadAverage.1, c.loadAverage.2]
                        .map { $0.formatted(.number.precision(.fractionLength(2))) }
                        .joined(separator: " ")),
                Fact("Uptime", Format.uptime(Date().timeIntervalSince(systemBootDate))),
            ])
        }
    }

    @ViewBuilder private var memory: some View {
        if let m = readout.latest.memory {
            HStack(spacing: Tokens.Space.xs) {
                Segments(
                    fractions: [m.app, m.wired, m.compressed].map { Double($0) / Double(m.total) },
                    inks: [ink.strong, ink.medium, ink.soft])
                PressurePill(pressure: m.pressure)
            }
            HistoryChart(
                up: [ChartSeries(name: "Used", history: readout.primary[.memory], ink: ink.strong, emphasis: true)],
                scale: .fraction, interval: interval, format: Format.percent, height: 30, previewHover: previewHover)
            Facts(
                [
                    Fact("App", Format.memory(m.app), key: ink.strong),
                    Fact("Wired", Format.memory(m.wired), key: ink.medium),
                    Fact("Compressed", Format.memory(m.compressed), key: ink.soft),
                    Fact("Cached", Format.memory(m.cached)),
                    Fact("Swap", Format.memory(m.swapUsed)),
                ], columns: 2)
        }
    }

    @ViewBuilder private var rates: some View {
        let network = metric == .network
        HistoryChart(
            up: [
                ChartSeries(
                    name: network ? "Upload" : "Write", history: readout.secondary[metric], ink: ink.medium,
                    emphasis: true)
            ],
            down: [
                ChartSeries(
                    name: network ? "Download" : "Read", history: readout.primary[metric], ink: ink.strong,
                    emphasis: true)
            ],
            scale: .rate(floor: metric.rateFloor), interval: interval, format: { Format.rate($0) },
            previewHover: previewHover)
    }
}

private struct Reading: View {
    let glyph: String
    let value: String?
    let ink: Color

    var body: some View {
        HStack(spacing: 3) {
            Text(glyph).foregroundStyle(ink)
            Text(value ?? Format.missing)
        }
    }
}

// MARK: - Tiles

/// A compact gauge for a single current value: name, ring, and a caption.
private struct MetricTile: View {
    let readout: Readout
    let metric: Metric
    let ink: Ink

    var body: some View {
        Card {
            VStack(spacing: Tokens.Space.xs) {
                HStack(spacing: Tokens.Space.xxs) {
                    MetricSymbol(metric: metric, font: .subheadline, width: 16)
                    Text(metric.name).font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Ring(fraction: readout.fraction(metric) ?? 0, ink: ringInk) {
                    VStack(spacing: 0) {
                        Text(center).font(.callout.weight(.semibold).monospacedDigit())
                        if metric == .battery, readout.latest.battery?.state == .charging {
                            Image(systemName: "bolt.fill").font(.caption2.weight(.bold)).imageScale(.small)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Text(caption).font(.footnote).foregroundStyle(.secondary).lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(metric.name) \(center), \(caption)")
    }

    private var center: String {
        metric == .storage
            ? readout.latest.storage.map { Format.percent($0.usedFraction) } ?? Format.missing
            : readout.valueText(metric)
    }

    private var caption: String {
        switch metric {
        case .storage:
            readout.latest.storage.map { "\(Format.bytes(Double($0.available))) free" } ?? " "
        case .battery:
            readout.latest.battery.map(batteryStatus) ?? " "
        default:
            "Utilization"
        }
    }

    /// Alert colours override the palette only when something needs attention.
    private var ringInk: Color {
        switch metric {
        case .battery:
            if let b = readout.latest.battery, b.level <= 0.1, b.state == .discharging {
                return Tokens.Color.danger.color
            }
        case .storage:
            if let s = readout.latest.storage, s.usedFraction >= 0.9 { return Tokens.Color.warning.color }
        default: break
        }
        return ink.strong
    }

    private func batteryStatus(_ b: BatteryReading) -> String {
        let time = b.minutesRemaining.map { Format.duration(minutes: $0) }
        switch b.state {
        case .charging: return time.map { "\($0) to full" } ?? "Charging"
        case .charged: return "Charged"
        case .onACNotCharging: return "Not charging"
        case .discharging: return time.map { "\($0) left" } ?? "On battery"
        }
    }
}

private struct Ring<Label: View>: View {
    let fraction: Double
    let ink: Color
    @ViewBuilder let label: Label

    var body: some View {
        ZStack {
            Circle().stroke(.quaternary, lineWidth: 5)
            Circle()
                .trim(from: 0, to: min(max(fraction, 0), 1))
                .stroke(ink, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            label
        }
        .frame(width: 48, height: 48)
    }
}

// MARK: - Shared pieces

/// A metric's palette steps (`Shade`) as SwiftUI colours, for one card.
struct Ink {
    let strong: Color
    let medium: Color
    let soft: Color

    init(_ palette: Palette, _ metric: Metric) {
        strong = Color(nsColor: palette.color(for: metric, .strong))
        medium = Color(nsColor: palette.color(for: metric, .medium))
        soft = Color(nsColor: palette.color(for: metric, .soft))
    }
}

/// A metric's symbol beside its name: plain, secondary, at the name's text size. The graphs carry
/// the colour; the symbol only says which card this is, so it stays out of their way. The fixed
/// width keeps names aligned from card to card, whatever each symbol's own width.
private struct MetricSymbol: View {
    let metric: Metric
    let font: Font
    let width: CGFloat

    var body: some View {
        Image(systemName: metric.symbol)
            .font(font)
            .foregroundStyle(.secondary)
            .frame(width: width)
            .accessibilityHidden(true)
    }
}

/// Memory pressure. Only warning and critical take a colour, from the shared tokens; normal stays
/// neutral, because in a red or orange palette a coloured "Normal" would read as the alarm.
private struct PressurePill: View {
    let pressure: MemoryReading.Pressure

    var body: some View {
        let (name, color): (String, Color) =
            switch pressure {
            case .normal: ("Normal", Tokens.Text.secondary.color)
            case .warning: ("Warning", Tokens.Color.warning.color)
            case .critical: ("Critical", Tokens.Color.danger.color)
            }
        HStack(spacing: Tokens.Space.xxs) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(name).font(.footnote.weight(.medium))
        }
        .padding(.horizontal, Tokens.Space.xs)
        .padding(.vertical, 3)
        .background(color.opacity(0.14), in: Capsule())
        .accessibilityLabel("Memory pressure \(name)")
    }
}

private struct Fact: Identifiable {
    let label: String
    let value: String?
    var key: Color?
    var id: String { label }

    init(_ label: String, _ value: String?, key: Color? = nil) {
        self.label = label
        self.value = value
        self.key = key
    }
}

/// Label/value pairs on an aligned grid. A fact with a `key` gets a legend
/// dot in the colour of its chart mark.
private struct Facts: View {
    let facts: [Fact]
    let columns: Int

    init(_ facts: [Fact], columns: Int = 3) {
        self.facts = facts
        self.columns = columns
    }

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: Tokens.Space.xxs, verticalSpacing: Tokens.Space.xxs) {
            ForEach(Array(stride(from: 0, to: facts.count, by: columns)), id: \.self) { start in
                GridRow {
                    ForEach(facts[start..<min(start + columns, facts.count)]) { fact in
                        HStack(spacing: 5) {
                            if let key = fact.key {
                                Circle().fill(key).frame(width: 6, height: 6)
                            }
                            Text(fact.label).foregroundStyle(.secondary)
                        }
                        Text(fact.value ?? "")
                            .monospacedDigit()
                            .padding(.trailing, Tokens.Space.sm)
                            .gridColumnAlignment(.leading)
                    }
                }
            }
        }
        .font(.subheadline)
        .lineLimit(1)
        .fixedSize()
    }
}

/// A horizontal bar split into consecutive segments.
private struct Segments: View {
    let fractions: [Double]
    let inks: [Color]

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 1.5) {
                ForEach(fractions.indices, id: \.self) { i in
                    Rectangle()
                        .fill(inks[min(i, inks.count - 1)])
                        .frame(width: max(geo.size.width * min(max(fractions[i], 0), 1) - 1.5, 0))
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: 6)
        .background(.quaternary)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}

/// Core bars grouped by the kernel's performance levels, each captioned with
/// the kernel's name for it and its average load. Bars keep one width across groups so they compare.
/// Without a known topology, all cores show as one ungrouped row.
private struct CoreClusters: View {
    let cores: [Double]
    let topology: CPUTopology
    let ink: Color
    let width: CGFloat

    private let gap: CGFloat = Tokens.Space.xs
    private let spacing: CGFloat = 2

    var body: some View {
        let clusters = topology.clusters
        if clusters.isEmpty || clusters.map(\.cores.count).reduce(0, +) != cores.count {
            CoreBars(cores: cores, ink: ink)
        } else {
            let gaps = gap * CGFloat(clusters.count - 1) + spacing * CGFloat(cores.count - clusters.count)
            let bar = (width - gaps) / CGFloat(cores.count)
            HStack(alignment: .top, spacing: gap) {
                ForEach(clusters, id: \.name) { cluster in
                    let load = cluster.cores.map { cores[$0] }
                    VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                        CoreBars(cores: load, ink: ink)
                        HStack(spacing: Tokens.Space.xxs) {
                            Text(cluster.name).foregroundStyle(.secondary)
                            Text(Format.percent(load.reduce(0, +) / Double(load.count))).monospacedDigit()
                        }
                        .font(.footnote)
                        .lineLimit(1)
                    }
                    .frame(width: bar * CGFloat(load.count) + spacing * CGFloat(load.count - 1))
                }
            }
        }
    }
}

/// One thin bar per logical core, in kernel order.
private struct CoreBars: View {
    let cores: [Double]
    let ink: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(cores.indices, id: \.self) { i in
                ZStack(alignment: .bottom) {
                    Rectangle().fill(.quaternary)
                    Rectangle().fill(ink)
                        .frame(height: 14 * CGFloat(min(max(cores[i], 0), 1)))
                }
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
            }
        }
        .frame(height: 14)
        .accessibilityHidden(true)
    }
}
