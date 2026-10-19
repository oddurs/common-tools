import AppKit
import BarKit
import CommonUI
import Observation
import SwiftUI

/// What one folder's dropdown shows, and what the keyboard and the opener do to it. One model serves
/// every folder; it is filled for the folder being opened.
@MainActor
@Observable
final class FolderPanelModel {
    struct Row: Identifiable, Equatable {
        let id: UInt32
        let name: String
        let status: String?
        /// The SF Symbol for one of macOS's own items; otherwise the app's icon is drawn.
        let symbol: String?
        let pid: Int32
        let group: FolderGroup
    }

    /// The icon's menu, copied in place of the folder's rows: each level a submenu drilled into.
    struct Copy {
        let title: String
        let pid: Int32
        let symbol: String?
        var levels: [(title: String, items: [(node: MenuNode, index: Int)], path: [(index: Int, title: String)])]
    }

    enum Notice: Equatable {
        case permission(asked: Bool, waiting: Int)
        case empty(String)
    }

    var folderName = ""
    var rows: [Row] = []
    var notice: Notice?
    var query = ""
    var selection = Dropdown.Selection()
    var copy: Copy?
    /// The row being opened, and what went wrong with one, shown in place for a moment.
    var busy: UInt32?
    var failure: (id: UInt32, message: String)?
    /// Changes each time the panel opens, so the view takes the keyboard again.
    var opened = 0

    @ObservationIgnored var icons: (Int32) -> NSImage? = { _ in nil }
    @ObservationIgnored var onOpen: (Row) -> Void = { _ in }
    @ObservationIgnored var onEdit: () -> Void = {}
    @ObservationIgnored var onSettings: () -> Void = {}
    @ObservationIgnored var onAllow: () -> Void = {}
    @ObservationIgnored var onReset: () -> Void = {}
    @ObservationIgnored var onClose: () -> Void = {}
    @ObservationIgnored private var choice: CheckedContinuation<MenuPath?, Never>?

    /// The rows that match what was typed, in their groups.
    var visible: [Row] {
        query.isEmpty ? rows : rows.filter { Dropdown.matches(query, name: $0.name, status: $0.status) }
    }

    /// What the arrows walk: the rows (or the copied menu's items), then the footer's two.
    var targetCount: Int {
        if let level = copy?.levels.last { return level.items.filter { !$0.node.isSeparator }.count }
        return visible.count + 2
    }

    func type(_ characters: String) {
        query += characters
        selection.settle(count: targetCount, filtering: true)
    }

    func deleteBackward() {
        guard !query.isEmpty else { return }
        query.removeLast()
        selection.settle(count: targetCount, filtering: !query.isEmpty)
    }

    /// Escape: out of a submenu, then out of a copied menu, then clears what was typed; false when
    /// there is nothing left to undo and the panel should close.
    func escape() -> Bool {
        if var copy, copy.levels.count > 1 {
            copy.levels.removeLast()
            self.copy = copy
        } else if copy != nil {
            leaveCopy()
        } else if !query.isEmpty {
            query = ""
        } else {
            return false
        }
        selection = Dropdown.Selection()
        return true
    }

    func activate() {
        guard let index = selection.index else { return }
        if copy != nil {
            chooseCopyItem(at: index)
            return
        }
        let rows = visible
        if index < rows.count {
            onOpen(rows[index])
        } else if index == rows.count {
            onEdit()
        } else {
            onSettings()
        }
    }

    // MARK: Copied menus

    /// Shows a copy of an icon's menu in place of the rows and returns the item chosen, or nil when
    /// the panel closed or went back to the rows first.
    func showCopy(_ nodes: [MenuNode], of row: Row) async -> MenuPath? {
        busy = nil
        copy = Copy(
            title: row.name, pid: row.pid, symbol: row.symbol,
            levels: [(row.name, MenuCopy.tidy(nodes.enumerated().map { ($0.element, $0.offset) }), [])])
        selection = Dropdown.Selection()
        return await withCheckedContinuation { choice = $0 }
    }

    func chooseCopyItem(at index: Int) {
        guard var copy, let level = copy.levels.last else { return }
        let items = level.items.filter { !$0.node.isSeparator }
        guard index < items.count, items[index].node.enabled else { return }
        let item = items[index]
        let path = level.path + [(item.index, item.node.title)]
        if !item.node.children.isEmpty {
            copy.levels.append(
                (item.node.title, MenuCopy.tidy(item.node.children.enumerated().map { ($0.element, $0.offset) }), path))
            self.copy = copy
            selection = Dropdown.Selection()
            return
        }
        choice?.resume(returning: MenuPath(path))
        choice = nil
    }

    func leaveCopy() {
        copy = nil
        choice?.resume(returning: nil)
        choice = nil
    }

    /// The panel closed: a copied menu waiting for a choice gets none.
    func closed() {
        if copy != nil { leaveCopy() }
        if !query.isEmpty { query = "" }
        if selection.index != nil { selection = Dropdown.Selection() }
        if busy != nil { busy = nil }
        if failure != nil { failure = nil }
    }
}

/// The dropdown: a filter that appears as you type, the folder's rows in their groups or a copied
/// menu drilled into, and the footer. Drawn on `MenuPanelSurface`, so it has the menu's material and
/// width, and `--render` draws it alone.
struct FolderPanel: View {
    @Bindable var model: FolderPanelModel
    @Environment(\.menuPanelMaxHeight) private var maxHeight
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !model.query.isEmpty, model.copy == nil {
                filter
                divider
            }
            if let copy = model.copy {
                copyView(copy)
            } else if let notice = model.notice {
                noticeView(notice)
            } else {
                rowsView
            }
            if model.copy == nil {
                divider
                footer
            }
        }
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onAppear { focused = true }
        .onChange(of: model.opened) { focused = true }
        .onKeyPress(.downArrow) { move(1) }
        .onKeyPress(.upArrow) { move(-1) }
        .onKeyPress(.return) {
            model.activate()
            return .handled
        }
        .onKeyPress(.escape) { model.escape() ? .handled : .ignored }
        .onKeyPress(.delete) {
            model.deleteBackward()
            return .handled
        }
        .onKeyPress(.leftArrow) {
            guard model.copy != nil else { return .ignored }
            return model.escape() ? .handled : .ignored
        }
        .onKeyPress(characters: .alphanumerics.union(.punctuationCharacters).union(.whitespaces)) { press in
            guard model.copy == nil, model.notice == nil else { return .ignored }
            model.type(press.characters)
            return .handled
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(model.folderName)
    }

    private func move(_ offset: Int) -> KeyPress.Result {
        model.selection.move(by: offset, count: model.targetCount)
        return .handled
    }

    private var divider: some View {
        Divider().padding(.vertical, Tokens.Space.xxs).padding(.horizontal, Tokens.Space.xs)
    }

    private var filter: some View {
        HStack(spacing: Tokens.Space.xs) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary).frame(width: 16)
            Text(model.query).lineLimit(1)
            Spacer(minLength: 0)
            Text("\(model.visible.count)").foregroundStyle(.tertiary).monospacedDigit()
        }
        .padding(.horizontal, Tokens.Space.xs)
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Filter: \(model.query), \(model.visible.count) matching")
    }

    // MARK: Rows

    private var rowsView: some View {
        let rows = model.visible
        let groups = FolderGroup.allCases.compactMap { group -> (FolderGroup, [(Int, FolderPanelModel.Row)])? in
            let members = rows.enumerated().filter { $0.element.group == group }.map { ($0.offset, $0.element) }
            return members.isEmpty ? nil : (group, members)
        }
        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if rows.isEmpty {
                    Text("Nothing matches “\(model.query)”.").foregroundStyle(.secondary)
                        .padding(.horizontal, Tokens.Space.xs).padding(.vertical, 3)
                }
                ForEach(Array(groups.enumerated()), id: \.element.0) { position, entry in
                    let (group, members) = entry
                    if groups.count > 1 {
                        SectionHeader(group.title)
                            .padding(.horizontal, Tokens.Space.xs)
                            .padding(.top, position == 0 ? 0 : Tokens.Space.xs)
                            .padding(.bottom, Tokens.Space.xxs)
                    }
                    ForEach(members, id: \.1.id) { index, row in
                        FolderRow(
                            row: row, icon: model.icons(row.pid), isSelected: model.selection.index == index,
                            isBusy: model.busy == row.id,
                            failure: model.failure?.id == row.id ? model.failure?.message : nil
                        ) {
                            model.onOpen(row)
                        } hover: {
                            model.selection = Dropdown.Selection(index: index)
                        }
                    }
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxHeight: max(maxHeight - 120, 120))
        .fixedSize(horizontal: false, vertical: true)
    }

    private var footer: some View {
        let first = model.visible.count
        return VStack(spacing: 0) {
            FooterRow(title: "Edit Folder…", isSelected: model.selection.index == first) {
                model.onEdit()
            } hover: {
                model.selection = Dropdown.Selection(index: first)
            }
            FooterRow(title: "Settings…", shortcut: "⌘,", isSelected: model.selection.index == first + 1) {
                model.onSettings()
            } hover: {
                model.selection = Dropdown.Selection(index: first + 1)
            }
        }
    }

    // MARK: Notices

    @ViewBuilder
    private func noticeView(_ notice: FolderPanelModel.Notice) -> some View {
        switch notice {
        case .empty(let message):
            Text(message).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Tokens.Space.xs).padding(.vertical, Tokens.Space.xxs)
        case .permission(let asked, let waiting):
            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                Text("Common Bar needs Accessibility to see which app each icon belongs to and open it.")
                    .fixedSize(horizontal: false, vertical: true)
                if waiting > 0 {
                    Text(waiting == 1 ? "1 icon waits in your folders." : "\(waiting) icons wait in your folders.")
                        .foregroundStyle(.secondary)
                }
                Button(asked ? "Open System Settings…" : "Allow Accessibility…") { model.onAllow() }
                    .keyboardShortcut(.defaultAction)
                if asked {
                    Text("If Common Bar is already on in System Settings, that switch belongs to an earlier copy.")
                        .font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    Button("Reset and Ask Again") { model.onReset() }.controlSize(.small)
                }
            }
            .padding(.horizontal, Tokens.Space.xs).padding(.vertical, Tokens.Space.xxs)
        }
    }

    // MARK: Copied menu

    private func copyView(_ copy: FolderPanelModel.Copy) -> some View {
        let level = copy.levels.last!
        var choosable = -1
        let items = level.items.map { item -> (node: MenuNode, choosable: Int?) in
            if item.node.isSeparator { return (item.node, nil) }
            choosable += 1
            return (item.node, choosable)
        }
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                _ = model.escape()
            } label: {
                HStack(spacing: Tokens.Space.xs) {
                    Image(systemName: "chevron.left").foregroundStyle(.secondary).frame(width: 10)
                    RowIcon(symbol: copy.levels.count == 1 ? copy.symbol : nil, icon: model.icons(copy.pid))
                    Text(level.title).font(.headline).lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, Tokens.Space.xs).padding(.vertical, 3)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back from \(level.title)")
            divider
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                if let index = item.choosable {
                    CopyRow(node: item.node, isSelected: model.selection.index == index) {
                        model.chooseCopyItem(at: index)
                    } hover: {
                        model.selection = Dropdown.Selection(index: index)
                    }
                } else {
                    divider
                }
            }
        }
    }
}

extension FolderGroup {
    var title: String {
        switch self {
        case .apps: "Apps"
        case .commonTools: "Common Tools"
        case .system: "macOS"
        }
    }
}

/// The app's icon, or the SF Symbol of one of macOS's own items, at a menu's 16 pt.
private struct RowIcon: View {
    let symbol: String?
    let icon: NSImage?

    var body: some View {
        Group {
            if let symbol {
                Image(systemName: symbol).imageScale(.medium)
            } else if let icon {
                Image(nsImage: icon).resizable().interpolation(.high)
            } else {
                Image(systemName: "app.dashed")
            }
        }
        .frame(width: 16, height: 16)
        .accessibilityHidden(true)
    }
}

/// A row that highlights as a menu item does, for the pointer and the keyboard alike.
private struct Highlighted<Content: View>: View {
    let isSelected: Bool
    let enabled: Bool
    let action: () -> Void
    let hover: () -> Void
    @ViewBuilder let content: (Bool) -> Content

    var body: some View {
        Button(action: action) {
            content(isSelected && enabled)
                .foregroundStyle(
                    !enabled
                        ? Tokens.Text.secondary.color
                        : isSelected ? Tokens.Text.inverse.color : Tokens.Text.primary.color
                )
                .padding(.horizontal, Tokens.Space.xs)
                .padding(.vertical, 3)
                .contentShape(Rectangle())
                .background(
                    isSelected && enabled ? AnyShapeStyle(Tokens.Color.accentFill.color) : AnyShapeStyle(.clear),
                    in: RoundedRectangle(cornerRadius: Tokens.Radius.xs, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .onHover { if $0 { hover() } }
    }
}

private struct FolderRow: View {
    let row: FolderPanelModel.Row
    let icon: NSImage?
    let isSelected: Bool
    let isBusy: Bool
    let failure: String?
    let action: () -> Void
    let hover: () -> Void

    var body: some View {
        Highlighted(isSelected: isSelected, enabled: true, action: action, hover: hover) { lit in
            HStack(spacing: Tokens.Space.xs) {
                RowIcon(symbol: row.symbol, icon: icon)
                Text(failure ?? row.name).lineLimit(1)
                Spacer(minLength: Tokens.Space.sm)
                if isBusy {
                    ProgressView().controlSize(.mini)
                } else if let status = row.status, failure == nil {
                    Text(status).lineLimit(1)
                        .foregroundStyle(lit ? Tokens.Text.inverse.color : Tokens.Text.secondary.color)
                }
            }
        }
        .accessibilityLabel([row.name, row.status, failure].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct FooterRow: View {
    let title: String
    var shortcut: String?
    let isSelected: Bool
    let action: () -> Void
    let hover: () -> Void

    var body: some View {
        Highlighted(isSelected: isSelected, enabled: true, action: action, hover: hover) { lit in
            HStack {
                Text(title)
                Spacer(minLength: Tokens.Space.sm)
                if let shortcut {
                    Text(shortcut).foregroundStyle(lit ? Tokens.Text.inverse.color : Tokens.Text.secondary.color)
                }
            }
        }
        .accessibilityLabel(shortcut.map { "\(title), \($0)" } ?? title)
    }
}

private struct CopyRow: View {
    let node: MenuNode
    let isSelected: Bool
    let action: () -> Void
    let hover: () -> Void

    var body: some View {
        Highlighted(isSelected: isSelected, enabled: node.enabled, action: action, hover: hover) { lit in
            HStack(spacing: Tokens.Space.xs) {
                Image(systemName: "checkmark").opacity(node.checked ? 1 : 0).frame(width: 12)
                Text(node.title).lineLimit(1)
                Spacer(minLength: Tokens.Space.sm)
                if !node.children.isEmpty {
                    Image(systemName: "chevron.right")
                } else if !node.key.isEmpty {
                    Text("⌘\(node.key)").foregroundStyle(lit ? Tokens.Text.inverse.color : Tokens.Text.secondary.color)
                }
            }
        }
        .accessibilityLabel([node.title, node.checked ? "checked" : nil].compactMap { $0 }.joined(separator: ", "))
    }
}
