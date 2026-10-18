import AppKit
import BatteryKit
import CommonUI
import SwiftUI
import UniformTypeIdentifiers

/// The menu bar item, editable in place, after Common Stats' editor. Each part is drawn by the
/// same renderer as the menu bar, from the battery as it is now. Drag parts to reorder them, drag
/// one to the tray to remove it, drag one in from the tray (or click it) to add it, and click a
/// part for its options. The last part can't be removed.
struct BarEditor: View {
    @Bindable var preferences: Preferences
    let reading: BatteryReading?

    @State private var selected: BarPart?
    @State private var hovered: BarPart?
    /// The part being dragged. Every drag starts in this view, so drops read this instead of the pasteboard.
    @State private var dragging: BarPart?
    /// The gap a drag over the strip would drop into, 0...shown count.
    @State private var insertion: Int?
    @State private var frames: [BarPart: CGRect] = [:]
    @State private var trayTargeted = false

    private var height: CGFloat { NSStatusBar.system.thickness }
    private var parts: [BarPart] { preferences.appearance.parts }

    var body: some View {
        VStack(spacing: Tokens.Space.sm) {
            strip
            tray
            Text("Drag to arrange. Click a part for its options.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, Tokens.Space.xxs)
    }

    /// Drops and tray clicks move a part with the family's motion, and none while the user asks for less.
    private var motion: Animation? { Tokens.Motion.animation(Tokens.Motion.fast) }

    // MARK: The strip

    private var strip: some View {
        HStack(spacing: 0) {
            ForEach(parts) { piece($0) }
        }
        .frame(maxWidth: .infinity, minHeight: height + 14)
        .background(.bar, in: RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous)
                .strokeBorder(
                    insertion == nil ? Tokens.Color.borderCard.color : Tokens.Color.border.color, lineWidth: 0.5)
        )
        .overlay(alignment: .topLeading) { indicator }
        .coordinateSpace(name: Self.space)
        .onPreferenceChange(FramesKey.self) { frames = $0 }
        .onDrop(
            of: [UTType.utf8PlainText],
            delegate: StripDrop(
                dragging: dragging, frames: frames, parts: parts, insertion: $insertion,
                drop: { part, slot in
                    withAnimation(motion) { place(part, inSlot: slot) }
                    dragging = nil
                }))
    }

    private static let space = "strip"

    private func piece(_ part: BarPart) -> some View {
        let appearance = preferences.appearance
        let only = BarAppearance(parts: [part], iconStyle: appearance.iconStyle, colorsAlerts: appearance.colorsAlerts)
        let image = BarRenderer(appearance: only, height: height).image(reading)
        return Image(nsImage: image)
            .foregroundStyle(.primary)
            // Half the menu bar's gap on each side, so neighbouring parts sit as far apart as they do there.
            .padding(.horizontal, Tokens.Space.xxs / 2)
            .padding(.vertical, 3)
            // Selected looks like a pressed menu bar item; hover is a lighter hint that it's clickable.
            // The radius is the menu bar's own highlight, which no token holds.
            .background(highlight(for: part), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .opacity(dragging == part && insertion != nil ? 0.35 : 1)
            .background(
                GeometryReader { g in
                    Color.clear.preference(key: FramesKey.self, value: [part: g.frame(in: .named(Self.space))])
                }
            )
            .contentShape(Rectangle())
            .help(part.name)
            .onHover { hovered = $0 ? part : (hovered == part ? nil : hovered) }
            .onTapGesture { selected = selected == part ? nil : part }
            .onDrag {
                dragging = part
                selected = nil
                return NSItemProvider(object: part.rawValue as NSString)
            }
            .popover(
                isPresented: Binding(get: { selected == part }, set: { if !$0, selected == part { selected = nil } }),
                arrowEdge: .bottom
            ) {
                PartInspector(preferences: preferences, part: part) { selected = nil }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(part.name)
            .accessibilityHint("Opens options for this part")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { selected = part }
            // Dragging is invisible to VoiceOver and keyboard users; these are the accessible path.
            .accessibilityActions {
                Button("Move Left") { nudge(part, by: -1) }
                Button("Move Right") { nudge(part, by: 1) }
                if preferences.appearance.canRemove {
                    Button("Remove from Menu Bar") { preferences.appearance.remove(part) }
                }
            }
    }

    private func highlight(for part: BarPart) -> AnyShapeStyle {
        if selected == part { return AnyShapeStyle(.tertiary) }
        if hovered == part { return AnyShapeStyle(.quaternary) }
        return AnyShapeStyle(.clear)
    }

    /// A line in the gap the drop would land in.
    @ViewBuilder private var indicator: some View {
        if let slot = insertion, !parts.isEmpty {
            let x = slot == 0 ? frames[parts[0]]?.minX : frames[parts[slot - 1]]?.maxX
            if let x {
                Capsule().fill(Tokens.Color.accent.color)
                    .frame(width: 2, height: height)
                    .offset(x: x - 1, y: 7)
            }
        }
    }

    private func place(_ part: BarPart, inSlot slot: Int) {
        // Slots count gaps around every shown part, including the dragged one; `place` counts
        // positions once it has left its old place.
        let adjusted = parts.firstIndex(of: part).map { slot > $0 ? slot - 1 : slot } ?? slot
        preferences.appearance.place(part, at: adjusted)
    }

    private func nudge(_ part: BarPart, by offset: Int) {
        guard let i = parts.firstIndex(of: part) else { return }
        preferences.appearance.place(part, at: i + offset)
    }

    // MARK: The tray

    private var tray: some View {
        let hidden = preferences.appearance.hidden
        return HStack(spacing: Tokens.Space.xs) {
            if hidden.isEmpty {
                Text("Everything is in the menu bar")
                    .font(.callout).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            ForEach(hidden) { part in
                Button {
                    withAnimation(motion) { preferences.appearance.place(part, at: .max) }
                } label: {
                    Label(part.name, systemImage: part.symbol)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                        .padding(.horizontal, Tokens.Space.xs)
                        .padding(.vertical, Tokens.Space.xxs)
                        .background(Tokens.Surface.card.color, in: Capsule())
                }
                .buttonStyle(.plain)
                .help("Drag into the menu bar, or click to add")
                .onDrag {
                    dragging = part
                    return NSItemProvider(object: part.rawValue as NSString)
                }
                .accessibilityLabel("Add \(part.name)")
            }
            if !hidden.isEmpty { Spacer(minLength: 0) }
        }
        .frame(minHeight: 30)
        .padding(Tokens.Space.xs)
        .background(
            RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous)
                .strokeBorder(
                    trayTargeted ? Tokens.Color.accent.color : Tokens.Color.border.color,
                    style: StrokeStyle(lineWidth: 1, dash: trayTargeted ? [] : [3, 3]))
        )
        // Dropping a part from the strip here removes it, unless it's the last.
        .dropDestination(for: String.self) { _, _ in
            guard let part = dragging, parts.contains(part), preferences.appearance.canRemove else { return false }
            withAnimation(motion) { preferences.appearance.remove(part) }
            dragging = nil
            return true
        } isTargeted: {
            trayTargeted =
                $0 && preferences.appearance.canRemove && dragging.map { parts.contains($0) } == true
        }
    }
}

/// Tracks a drag over the strip and drops into the gap under the pointer.
private struct StripDrop: DropDelegate {
    let dragging: BarPart?
    let frames: [BarPart: CGRect]
    let parts: [BarPart]
    @Binding var insertion: Int?
    let drop: (BarPart, Int) -> Void

    func validateDrop(info: DropInfo) -> Bool { dragging != nil }

    func dropEntered(info: DropInfo) { insertion = slot(at: info.location.x) }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        insertion = slot(at: info.location.x)
        return DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) { insertion = nil }

    func performDrop(info: DropInfo) -> Bool {
        let slot = slot(at: info.location.x)
        insertion = nil
        guard let dragging else { return false }
        drop(dragging, slot)
        return true
    }

    /// The number of parts whose centre lies left of `x`.
    private func slot(at x: CGFloat) -> Int {
        parts.filter { (frames[$0]?.midX ?? .infinity) < x }.count
    }
}

private struct FramesKey: PreferenceKey {
    static let defaultValue: [BarPart: CGRect] = [:]
    static func reduce(value: inout [BarPart: CGRect], nextValue: () -> [BarPart: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

/// The popover for one part: how the icon is drawn, or take the part out.
private struct PartInspector: View {
    @Bindable var preferences: Preferences
    let part: BarPart
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            Label(part.name, systemImage: part.symbol).font(.headline)
            if part == .battery {
                Picker("Show as", selection: $preferences.appearance.iconStyle) {
                    ForEach(IconStyle.allCases, id: \.self) { Text($0.name) }
                }
                .pickerStyle(.radioGroup)
            }
            Divider()
            Button("Remove from Menu Bar", role: .destructive) {
                preferences.appearance.remove(part)
                dismiss()
            }
            .disabled(!preferences.appearance.canRemove)
            if !preferences.appearance.canRemove {
                Text("The menu bar keeps at least one part.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Tokens.Space.md)
        .frame(width: 230, alignment: .leading)
    }
}
