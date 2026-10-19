import AppKit
import CommonUI
import ShotKit
import SwiftUI

/// What the menu bar item opens: Take Screenshot, the shots kept, grouped by when they were taken in a
/// grid of thumbnails, and the way to Settings. A click copies a shot again; it drags out as its file;
/// its context menu shows it in Finder or moves it to the Trash. The keyboard does all of it: arrows
/// move, Return copies, Delete moves to the Trash with Undo beside it, Escape closes.
struct ShotsPanel: View {
    struct Actions {
        var capture: () -> Void = {}
        var copy: (History.Shot) -> Void = { _ in }
        var reveal: (History.Shot) -> Void = { _ in }
        var trash: (History.Shot) -> URL? = { _ in nil }
        var restore: (History.Shot, URL) -> Void = { _, _ in }
        var openFolder: () -> Void = {}
        var settings: () -> Void = {}
        var quit: () -> Void = {}
        var close: () -> Void = {}
    }

    let history: History
    /// How many shots Settings keeps; zero is history turned off.
    let limit: Int
    let shortcut: String
    var shortcutProblem: String?
    var now = Date.now
    var actions = Actions()

    @State var selection: Int?
    @State private var trashed: (shot: History.Shot, url: URL)?
    @State private var gridHeight: CGFloat = 0
    @FocusState private var focused: Bool
    @Environment(\.menuPanelMaxHeight) private var maxHeight

    private static let columns = 2
    /// The rows above and below the grid, so the grid scrolls before the panel outgrows the screen.
    private static let chrome: CGFloat = 200
    private static let thumbnailSide: CGFloat = 160

    var body: some View {
        let groups = Shelf.groups(of: history.shots.map(\.date), now: now)
        let order = groups.flatMap(\.indices).map { history.shots[$0] }
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            MenuRow("Take Screenshot", symbol: "camera.viewfinder", shortcut: shortcutProblem == nil ? shortcut : nil) {
                actions.capture()
            }
            if let shortcutProblem {
                SettingsFootnote(shortcutProblem, tone: .danger).padding(.horizontal, Tokens.Space.xs)
            }
            if limit == 0 {
                emptyCard(
                    "History Is Off", symbol: "clock.badge.xmark",
                    "Turn on History in Settings to find your recent shots here, ready to copy again.")
            } else if order.isEmpty {
                emptyCard(
                    "No Shots Yet", symbol: "photo.on.rectangle.angled",
                    "Press \(shortcut) and drag. Your last \(limit) shots wait here, ready to copy again.")
            } else {
                ScrollView {
                    VStack(spacing: Tokens.Space.xs) {
                        ForEach(groups, id: \.period) { group in
                            Card { section(group, order: order) }
                        }
                    }
                    .background(
                        GeometryReader { proxy in Color.clear.preference(key: GridHeight.self, value: proxy.size.height)
                        })
                }
                .scrollIndicators(.automatic)
                .frame(height: min(gridHeight > 0 ? gridHeight : estimate(groups), max(maxHeight - Self.chrome, 160)))
                .onPreferenceChange(GridHeight.self) { gridHeight = $0 }
            }
            if let trashed {
                HStack {
                    Label("Moved to the Trash", systemImage: "trash").foregroundStyle(.secondary)
                    Spacer()
                    Button("Undo") { undo() }.keyboardShortcut("z", modifiers: .command)
                }
                .font(.subheadline)
                .padding(.horizontal, Tokens.Space.xs)
                .accessibilityElement(children: .combine)
                .id(trashed.url)
            }
            Divider().padding(.horizontal, Tokens.Space.xs)
            VStack(spacing: 0) {
                if !history.shots.isEmpty {
                    MenuRow("Open History Folder", symbol: "folder") { actions.openFolder() }
                }
                MenuRow("Settings…", symbol: "gearshape", shortcut: "⌘,") { actions.settings() }
                MenuRow("Quit Common Shot", symbol: "power", shortcut: "⌘Q") { actions.quit() }
            }
        }
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onAppear { focused = true }
        .onKeyPress(keys: [.leftArrow, .rightArrow, .upArrow, .downArrow]) { press in
            let move: Shelf.Move =
                switch press.key {
                case .leftArrow: .left
                case .rightArrow: .right
                case .upArrow: .up
                default: .down
                }
            selection = Shelf.move(move, from: selection, sizes: groups.map(\.indices.count), columns: Self.columns)
            return .handled
        }
        .onKeyPress(.return) {
            guard let selected = selected(in: order) else { return .ignored }
            actions.copy(selected)
            return .handled
        }
        .onKeyPress(keys: [.delete, .deleteForward]) { _ in
            guard let selected = selected(in: order) else { return .ignored }
            trash(selected, order: order)
            return .handled
        }
        .onKeyPress(.escape) {
            actions.close()
            return .handled
        }
    }

    private func section(_ group: Shelf.Group, order: [History.Shot]) -> some View {
        let start = order.firstIndex { $0.url == history.shots[group.indices[0]].url } ?? 0
        let count = group.indices.count
        return VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            SectionHeader(group.period.title, detail: count == 1 ? "1 shot" : "\(count) shots")
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: Tokens.Space.xs, alignment: .top), count: Self.columns),
                spacing: Tokens.Space.sm
            ) {
                ForEach(Array(order[start..<(start + count)].enumerated()), id: \.element.url) { offset, shot in
                    tile(shot, period: group.period, position: start + offset, order: order)
                }
            }
        }
    }

    private func tile(_ shot: History.Shot, period: Shelf.Period, position: Int, order: [History.Shot]) -> some View {
        let tokens = ImageSize.describe(tokens: ImageSize.estimatedTokens(width: shot.width, height: shot.height))
        return ThumbnailTile(
            image: history.thumbnails[shot.url].map(Image.init(nsImage:)),
            title: Shelf.when(shot.date, in: period, now: now),
            subtitle: "\(shot.width) × \(shot.height) · \(tokens)",
            isSelected: selection == position
        ) {
            // Every tile has the slot, so captions line up whether or not the app is known.
            if let icon = AppIcons.icon(for: shot.app) {
                Image(nsImage: icon).resizable()
            } else {
                Image(systemName: "macwindow").foregroundStyle(.tertiary)
            }
        }
        .onTapGesture { actions.copy(shot) }
        .onDrag { NSItemProvider(object: shot.url as NSURL) }
        .contextMenu {
            Button("Copy") { actions.copy(shot) }
            Button("Show in Finder") { actions.reveal(shot) }
            Divider()
            Button("Move to Trash") { trash(shot, order: order) }
        }
        .help("Click to copy again, or drag out as a file")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Copy") { actions.copy(shot) }
        .task { await history.loadThumbnail(for: shot, fitting: Self.thumbnailSide, scale: 2) }
    }

    /// About how tall the grid is, until its first layout says exactly, so the panel opens near its size
    /// rather than growing into it.
    private func estimate(_ groups: [Shelf.Group]) -> CGFloat {
        groups.reduce(0) { height, group in
            let rows = (group.indices.count + Self.columns - 1) / Self.columns
            return height + 48 + CGFloat(rows) * 132
        }
    }

    private func emptyCard(_ title: String, symbol: String, _ text: String) -> some View {
        Card {
            HStack(alignment: .top, spacing: Tokens.Space.sm) {
                IconBadge(symbol: symbol, tint: .gray, size: 32)
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    Text(title).font(.headline)
                    Text(text).font(.subheadline).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func selected(in order: [History.Shot]) -> History.Shot? {
        guard let selection, order.indices.contains(selection) else { return nil }
        return order[selection]
    }

    private func trash(_ shot: History.Shot, order: [History.Shot]) {
        guard let url = actions.trash(shot) else { return }
        trashed = (shot, url)
        // The selection stays in place, on the shot that moved up into it.
        if let selection {
            self.selection = min(selection, order.count - 2) >= 0 ? min(selection, order.count - 2) : nil
        }
    }

    private func undo() {
        guard let trashed else { return }
        actions.restore(trashed.shot, trashed.url)
        self.trashed = nil
    }
}

private struct GridHeight: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// Apps' icons by bundle identifier, looked up once each: what the window server and Launch Services
/// say, with no permission asked.
@MainActor
enum AppIcons {
    private static var cache: [String: NSImage?] = [:]

    static func icon(for bundleIdentifier: String?) -> NSImage? {
        guard let bundleIdentifier else { return nil }
        if let cached = cache[bundleIdentifier] { return cached }
        let icon = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier).map {
            NSWorkspace.shared.icon(forFile: $0.path)
        }
        cache[bundleIdentifier] = icon
        return icon
    }
}
