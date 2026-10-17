import BatteryKit
import SwiftUI

/// The menu's view of the live state.
struct BatteryPanel: View {
    let state: BatteryState

    var body: some View {
        PanelView(reading: state.reading, history: state.history, now: Date())
    }
}

/// The top of the menu: level and status, the last 12 hours, and the details. A pure function
/// of its inputs, so the snapshot tool can render it offscreen.
struct PanelView: View {
    let reading: BatteryReading?
    let history: ChargeHistory
    let now: Date

    static let width: CGFloat = 300

    var body: some View {
        Card {
            if let reading {
                VStack(alignment: .leading, spacing: 10) {
                    header(reading)
                    ChargeChart(history: history, now: now)
                    facts(reading)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No Battery").font(.system(size: 13, weight: .semibold))
                    Text("This Mac runs on power from the wall.").font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .frame(width: Self.width)
    }

    private func header(_ reading: BatteryReading) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Battery").font(.system(size: 13, weight: .semibold))
                Text(Format.status(reading)).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            Text(Format.percent(reading.percent))
                .font(.system(size: 22, weight: .semibold).monospacedDigit())
                .foregroundStyle(reading.isLow ? Color.red : .primary)
        }
        .accessibilityElement(children: .combine)
    }

    private func facts(_ reading: BatteryReading) -> some View {
        var rows: [(String, String)] = [("Power Source", source(reading))]
        if let watts = reading.watts, abs(watts) >= 0.1 {
            rows.append((watts > 0 ? "Charging At" : "Using", Format.watts(watts)))
        }
        if reading.isLowPowerMode { rows.append(("Low Power Mode", "On")) }
        if let cycles = reading.cycleCount {
            let rated = reading.designCycleCount.map { " of \(Format.count($0))" } ?? ""
            rows.append(("Cycles", Format.count(cycles) + rated))
        }
        // The measured mAh, not a percentage: Apple's Maximum Capacity comes from a calculation it
        // doesn't publish, and a second percentage that disagrees with System Settings misleads.
        if let full = reading.fullChargeCapacity {
            let design = reading.designCapacity.map { " of \(Format.count($0))" } ?? ""
            rows.append(("Full Charge", Format.count(full) + design + " mAh"))
        }
        if let temperature = reading.temperature {
            rows.append(("Temperature", Format.temperature(celsius: temperature)))
        }
        return Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
            ForEach(rows, id: \.0) { label, value in
                GridRow {
                    Text(label).foregroundStyle(.secondary)
                    Text(value).monospacedDigit()
                }
            }
        }
        .font(.system(size: 11))
        .lineLimit(1)
    }

    private func source(_ reading: BatteryReading) -> String {
        guard reading.isOnPower else { return "Battery" }
        return reading.adapterWatts.map { "\($0) W Adapter" } ?? "Power Adapter"
    }
}

/// A Control Center–style module, as in Common Stats: a softly filled rounded panel.
private struct Card<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5))
    }
}

/// The level over the last 12 hours, oldest at the left, now at the right edge. Time while
/// charging is drawn green. Gaps (the Mac asleep, or the app not yet running) stay empty.
struct ChargeChart: View {
    let history: ChargeHistory
    let now: Date

    var body: some View {
        VStack(spacing: 3) {
            Canvas { context, size in
                let start = now.addingTimeInterval(-ChargeHistory.span)
                func point(_ s: ChargeHistory.Sample) -> CGPoint {
                    CGPoint(
                        x: size.width * s.time.timeIntervalSince(start) / ChargeHistory.span,
                        y: size.height * (1 - min(max(s.level, 0), 1)))
                }
                // A 50% line gives the level a scale without an axis.
                context.fill(
                    Path(CGRect(x: 0, y: size.height / 2 - 0.25, width: size.width, height: 0.5)),
                    with: .color(.primary.opacity(0.1)))
                for run in history.runs() {
                    // Split where charging starts or stops; the boundary sample ends one stretch and
                    // starts the next, so the line stays continuous. Each stretch fills as one path, so
                    // no antialiased seams show between samples.
                    var stretches: [[ChargeHistory.Sample]] = []
                    for (i, sample) in run.enumerated() {
                        if i > 0, sample.charging != stretches[stretches.count - 1].last!.charging {
                            stretches[stretches.count - 1].append(sample)
                            stretches.append([sample])
                        } else if i == 0 {
                            stretches.append([sample])
                        } else {
                            stretches[stretches.count - 1].append(sample)
                        }
                    }
                    for stretch in stretches {
                        let points = stretch.map(point)
                        // A stretch takes the colour of what happened during it: its second sample's state.
                        let ink: Color = (stretch.dropFirst().first ?? stretch[0]).charging ? .green : .accentColor
                        guard points.count > 1 else {
                            let p = points[0]
                            context.fill(
                                Path(ellipseIn: CGRect(x: p.x - 2, y: p.y - 2, width: 4, height: 4)), with: .color(ink))
                            continue
                        }
                        var line = Path()
                        line.addLines(points)
                        var area = line
                        area.addLine(to: CGPoint(x: points.last!.x, y: size.height))
                        area.addLine(to: CGPoint(x: points[0].x, y: size.height))
                        area.closeSubpath()
                        context.fill(area, with: .color(ink.opacity(0.25)))
                        context.stroke(
                            line, with: .color(ink),
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    }
                }
            }
            .frame(height: 44)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            HStack {
                Text("12 hours ago")
                Spacer()
                Text("Now")
            }
            .font(.system(size: 9))
            .foregroundStyle(.tertiary)
        }
        .accessibilityHidden(true)
    }
}
