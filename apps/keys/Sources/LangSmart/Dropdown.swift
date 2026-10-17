import AppKit
import CommonUI
import SwiftUI
import WorldKey

/// What the dropdown's cards show, taken from the engine when the menu opens. The cards are a pure
/// function of this, so the snapshot tool can render them offscreen.
struct DropdownData {
    struct AppRow: Identifiable {
        var bundleID: String
        var words: Int
        var flag: String?
        var id: String { bundleID }
    }

    var today: UsageStats.Day
    var week: [UsageStats.Day]
    var keyboards: [(id: String, name: String, flag: String)]
    var apps: [AppRow]
    var learnedWords: Int
    var mixedUp: (typed: String, meant: String, count: Int)?
    var hour: Int

    @MainActor
    init(engine: Engine, now: Date = .now) {
        let stats = engine.stats
        today = stats.day(now)
        week = stats.last(7, endingAt: now)
        keyboards = engine.layouts.map { ($0.id, $0.name, $0.flag) }
        apps = today.apps.sorted { $0.value > $1.value }.prefix(3).map { bundleID, words in
            let usual = engine.layoutForApp(bundleID, includeRecent: false, orPreferred: false)
            return AppRow(bundleID: bundleID, words: words, flag: usual.flatMap(engine.layout)?.flag)
        }
        learnedWords = engine.memory.words.count
        mixedUp = engine.memory.confusions.max { $0.count < $1.count }.flatMap { confusion in
            guard let from = engine.layout(confusion.from), let to = engine.layout(confusion.to) else {
                return nil
            }
            let key = [KeyStroke(confusion.keyCode)]
            return (from.text(for: key), to.text(for: key), confusion.count)
        }
        hour = Calendar.current.component(.hour, from: now)
    }

    init(
        today: UsageStats.Day, week: [UsageStats.Day], keyboards: [(id: String, name: String, flag: String)],
        apps: [AppRow], learnedWords: Int, mixedUp: (typed: String, meant: String, count: Int)?, hour: Int
    ) {
        (self.today, self.week, self.keyboards, self.apps) = (today, week, keyboards, apps)
        (self.learnedWords, self.mixedUp, self.hour) = (learnedWords, mixedUp, hour)
    }
}

enum DropdownPanel: CaseIterable {
    case today, languages, tiles
}

struct PanelView: View {
    let data: DropdownData
    let panel: DropdownPanel

    var body: some View {
        Group {
            switch panel {
            case .today: TodayCard(data: data)
            case .languages: LanguagesCard(data: data)
            case .tiles:
                HStack(spacing: Tokens.Space.xs) {
                    WeekTile(week: data.week)
                    NumberTile(
                        symbol: "brain", tint: .pink, title: "Learned", value: "\(data.learnedWords)",
                        caption: data.learnedWords == 1 ? "word" : "words")
                    MixedUpTile(mixedUp: data.mixedUp)
                }
            }
        }
        .padding(.horizontal, Tokens.Space.xs)
        .padding(.vertical, Tokens.Space.xxs)
        .frame(width: Tokens.Layout.menuPanelWidth)
    }
}

// MARK: - Cards

private struct TodayCard: View {
    let data: DropdownData

    var body: some View {
        let day = data.today
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                HStack(spacing: Tokens.Space.xs) {
                    IconBadge(symbol: "keyboard", tint: .blue)
                    Text("Today").font(.headline)
                    Spacer(minLength: Tokens.Space.xs)
                    HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.xxs) {
                        Text("\(day.fixes)").font(.title3.weight(.semibold).monospacedDigit())
                        Text(day.fixes == 1 ? "fix" : "fixes").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                HourBars(counts: day.hourlyFixes, now: data.hour)
                Facts([
                    Fact("Words", day.totalWords.formatted()),
                    Fact("Undone", "\(day.undone)"),
                    Fact(
                        "Kept",
                        day.fixes == 0 ? "—" : percent(Double(day.fixes - day.undone) / Double(day.fixes))),
                ])
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct LanguagesCard: View {
    let data: DropdownData

    var body: some View {
        let words = data.today.words
        let total = max(words.values.reduce(0, +), 1)
        // Keyboards in menu order, so each keeps its place and its shade from day to day.
        let shares = data.keyboards.compactMap { keyboard -> (flag: String, name: String, share: Double)? in
            guard let count = words[keyboard.id], count > 0 else { return nil }
            return (keyboard.flag, keyboard.name, Double(count) / Double(total))
        }
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                HStack(spacing: Tokens.Space.xs) {
                    IconBadge(symbol: "globe", tint: .purple)
                    Text("Languages").font(.headline)
                    Spacer(minLength: Tokens.Space.xs)
                    if let top = shares.max(by: { $0.share < $1.share }) {
                        Text("\(top.flag) \(percent(top.share))").font(.title3.weight(.semibold).monospacedDigit())
                    }
                }
                if shares.isEmpty {
                    Text("Nothing written yet today.").font(.subheadline).foregroundStyle(.secondary)
                } else {
                    Segments(fractions: shares.map(\.share), inks: Ink.steps)
                    Facts(
                        shares.enumerated().map { index, share in
                            Fact(
                                "\(share.flag) \(share.name)", percent(share.share),
                                key: Ink.steps[min(index, 2)])
                        }, columns: 2)
                }
                if !data.apps.isEmpty {
                    Divider()
                    VStack(spacing: Tokens.Space.xxs) {
                        ForEach(data.apps) { AppLine(row: $0) }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct AppLine: View {
    let row: DropdownData.AppRow

    var body: some View {
        let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: row.bundleID)
        HStack(spacing: Tokens.Space.xs) {
            if let url {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path)).resizable().frame(
                    width: 16, height: 16)
            } else {
                Image(systemName: "app.dashed").frame(width: 16, height: 16).foregroundStyle(.tertiary)
            }
            Text(
                url.map {
                    FileManager.default.displayName(atPath: $0.path).replacingOccurrences(
                        of: ".app", with: "")
                } ?? row.bundleID
            )
            .lineLimit(1)
            Spacer(minLength: Tokens.Space.xxs)
            Text("\(row.words.formatted()) words").foregroundStyle(.secondary).monospacedDigit()
            Text(row.flag ?? "·").frame(width: 18).foregroundStyle(.tertiary)
                .help(row.flag == nil ? "Still learning this app's language" : "Usually written in")
        }
        .font(.subheadline)
    }
}

// MARK: - Tiles

private struct WeekTile: View {
    let week: [UsageStats.Day]

    var body: some View {
        let total = week.map(\.fixes).reduce(0, +)
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                TileTitle(symbol: "calendar", tint: .orange, title: "Week")
                Text("\(total)").font(.title2.weight(.semibold).monospacedDigit())
                DayBars(counts: week.map(\.fixes))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(total) fixes this week")
    }
}

private struct NumberTile: View {
    let symbol: String
    let tint: Color
    let title: String
    let value: String
    let caption: String

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                TileTitle(symbol: symbol, tint: tint, title: title)
                Text(value).font(.title2.weight(.semibold).monospacedDigit())
                Text(caption).font(.caption).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value) \(caption)")
    }
}

private struct MixedUpTile: View {
    let mixedUp: (typed: String, meant: String, count: Int)?

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                TileTitle(symbol: "arrow.left.arrow.right", tint: .teal, title: "Mixed up")
                if let mixedUp {
                    HStack(spacing: Tokens.Space.xxs) {
                        Keycap(mixedUp.typed)
                        Image(systemName: "arrow.right").font(.caption2.weight(.bold)).foregroundStyle(.tertiary)
                        Keycap(mixedUp.meant)
                    }
                    Text("\(mixedUp.count)×").font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("—").font(.title2.weight(.semibold))
                    Text("nothing yet").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct TileTitle: View {
    let symbol: String
    let tint: Color
    let title: String

    var body: some View {
        HStack(spacing: Tokens.Space.xxs) {
            IconBadge(symbol: symbol, tint: tint, size: 15)
            Text(title).font(.subheadline.weight(.semibold)).lineLimit(1)
        }
    }
}

/// A key as a key cap: the same tint and hairline as a card, so it reads as a raised piece of it.
private struct Keycap: View {
    let label: String

    init(_ label: String) {
        self.label = label
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous)
        Text(label)
            .font(.callout.weight(.medium))
            .frame(minWidth: 20, minHeight: 20)
            .background(Tokens.Surface.card.color, in: shape)
            .overlay(shape.strokeBorder(Tokens.Color.borderCard.color, lineWidth: 0.5))
    }
}

// MARK: - Shared pieces

private func percent(_ value: Double) -> String {
    value.formatted(.percent.precision(.fractionLength(0)))
}

/// Three steps of the accent colour: the strongest is always the biggest share, and legend dots
/// match the marks. Over a dark menu the lighter steps carry more alpha to stay apart.
enum Ink {
    static let steps = [Color.accentColor, tint(light: 0.62, dark: 0.72), tint(light: 0.36, dark: 0.5)]

    private static func tint(light: CGFloat, dark: CGFloat) -> Color {
        Color(
            nsColor: NSColor(name: nil) { appearance in
                let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                return NSColor.controlAccentColor.withAlphaComponent(isDark ? dark : light)
            })
    }
}

/// Fixes per hour of today, the current hour marked, hours still to come shaded lighter.
private struct HourBars: View {
    let counts: [Int]
    let now: Int

    var body: some View {
        let peak = max(counts.max() ?? 0, 3)
        VStack(spacing: Tokens.Space.xxs) {
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(counts.indices, id: \.self) { hour in
                    ZStack(alignment: .bottom) {
                        if hour <= now {
                            Rectangle().fill(.quaternary)
                        } else {
                            Rectangle().fill(.quinary)
                        }
                        Rectangle()
                            .fill(hour == now ? Ink.steps[0] : Ink.steps[1])
                            .frame(height: 34 * CGFloat(counts[hour]) / CGFloat(peak))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                }
            }
            .frame(height: 34)
            // Labels at 0, 6, 12 and 18 hours: four quarters of the row, each label at its quarter's start.
            HStack(spacing: 0) {
                ForEach(["12 AM", "6 AM", "12 PM", "6 PM"], id: \.self) { label in
                    Text(label).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .accessibilityHidden(true)
    }
}

/// Fixes per day for a week, today on the right.
private struct DayBars: View {
    let counts: [Int]

    var body: some View {
        let peak = max(counts.max() ?? 0, 1)
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(counts.indices, id: \.self) { index in
                ZStack(alignment: .bottom) {
                    Rectangle().fill(.quaternary)
                    Rectangle()
                        .fill(index == counts.count - 1 ? Ink.steps[0] : Ink.steps[1])
                        .frame(height: 14 * CGFloat(counts[index]) / CGFloat(peak))
                }
                .clipShape(RoundedRectangle(cornerRadius: 1.5, style: .continuous))
            }
        }
        .frame(height: 14)
        .accessibilityHidden(true)
    }
}

/// A horizontal bar split into consecutive shares.
private struct Segments: View {
    let fractions: [Double]
    let inks: [Color]

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 1.5) {
                ForEach(fractions.indices, id: \.self) { index in
                    Rectangle()
                        .fill(inks[min(index, inks.count - 1)])
                        .frame(width: max(geo.size.width * min(max(fractions[index], 0), 1) - 1.5, 0))
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

private struct Fact: Identifiable {
    let label: String
    let value: String
    var key: Color?
    var id: String { label }

    init(_ label: String, _ value: String, key: Color? = nil) {
        self.label = label
        self.value = value
        self.key = key
    }
}

/// Label and value pairs on an aligned grid; a fact with a `key` gets a legend dot.
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
                        HStack(spacing: Tokens.Space.xxs) {
                            if let key = fact.key { Circle().fill(key).frame(width: 6, height: 6) }
                            Text(fact.label).foregroundStyle(.secondary)
                        }
                        Text(fact.value)
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
