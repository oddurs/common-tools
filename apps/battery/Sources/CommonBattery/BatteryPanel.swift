import BatteryKit
import CommonUI
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

    var body: some View {
        Card {
            if let reading {
                VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                    header(reading)
                    ChargeChart(history: history, now: now)
                    facts(reading)
                }
            } else {
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    Text("No Battery").font(.headline)
                    Text("This Mac runs on power from the wall.").font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: Tokens.Layout.menuPanelWidth)
        .padding(.horizontal, Tokens.Space.xs)
        .padding(.vertical, Tokens.Space.xxs)
    }

    private func header(_ reading: BatteryReading) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                Text("Battery").font(.headline)
                Text(Format.status(reading)).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Text(Format.percent(reading.percent))
                .font(.title.weight(Tokens.Weight.semibold).monospacedDigit())
                .foregroundStyle(reading.isLow ? Tokens.Color.danger.color : Tokens.Text.primary.color)
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
        return Grid(alignment: .leading, horizontalSpacing: Tokens.Space.sm, verticalSpacing: Tokens.Space.xxs) {
            ForEach(rows, id: \.0) { label, value in
                GridRow {
                    Text(label).foregroundStyle(.secondary)
                    Text(value).monospacedDigit()
                }
            }
        }
        .font(.subheadline)
        .lineLimit(1)
    }

    private func source(_ reading: BatteryReading) -> String {
        guard reading.isOnPower else { return "Battery" }
        return reading.adapterWatts.map { "\($0) W Adapter" } ?? "Power Adapter"
    }
}

/// The level over the last 12 hours, oldest at the left, now at the right edge. Time while
/// charging is drawn green. Gaps (the Mac asleep, or the app not yet running) stay empty.
struct ChargeChart: View {
    let history: ChargeHistory
    let now: Date

    var body: some View {
        VStack(spacing: Tokens.Space.xxs) {
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
                    with: .color(Tokens.Color.border.color))
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
                        // Charging is green, the system's; the rest is the user's accent.
                        let ink: Color =
                            (stretch.dropFirst().first ?? stretch[0]).charging ? .green : Tokens.Color.accent.color
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
            .background(
                Tokens.Surface.card.color, in: RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous)
            )
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous))

            HStack {
                Text("12 hours ago")
                Spacer()
                Text("Now")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .accessibilityHidden(true)
    }
}
