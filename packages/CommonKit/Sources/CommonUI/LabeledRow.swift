import SwiftUI

/// A row of a grouped form: an optional leading icon, a title with a secondary line under it, and
/// whatever acts on the row at the trailing edge. VoiceOver reads the row as one element, so the
/// trailing control's name follows the title.
///
/// The leading slot is 32 points square, the size of an app icon in a list, unless `leadingSize`
/// says otherwise. The title is a `String`, or a `Text` when a row needs to style its own: a dimmed
/// name, a bolder word.
///
///     LabeledRow("Common Stats", subtitle: "System stats in the menu bar") {
///         Image(nsImage: icon).resizable()
///     } trailing: {
///         Button("Open") { open() }
///     }
///     LabeledRow("Take a screenshot") { ShortcutRecorder() }
///     LabeledRow(name, subtitle: summary, leadingSize: 52, leading: { GlyphTile(glyph) })
public struct LabeledRow<Leading: View, Trailing: View>: View {
    private let title: Text
    private let subtitle: String?
    private let leading: Leading?
    private let leadingSize: CGFloat
    private let trailing: Trailing?

    public init(
        _ title: String, subtitle: String? = nil, leadingSize: CGFloat = 32, @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(Text(title), subtitle: subtitle, leadingSize: leadingSize, leading: leading(), trailing: trailing())
    }

    public init(
        _ title: Text, subtitle: String? = nil, leadingSize: CGFloat = 32, @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(title, subtitle: subtitle, leadingSize: leadingSize, leading: leading(), trailing: trailing())
    }

    private init(_ title: Text, subtitle: String?, leadingSize: CGFloat, leading: Leading?, trailing: Trailing?) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
        self.leadingSize = leadingSize
        self.trailing = trailing
    }

    public var body: some View {
        HStack(spacing: Tokens.Space.sm) {
            if let leading {
                leading.frame(width: leadingSize, height: leadingSize)
            }
            VStack(alignment: .leading, spacing: 1) {
                title
                if let subtitle {
                    Text(subtitle).font(.footnote).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let trailing {
                trailing
            }
        }
        .accessibilityElement(children: .combine)
    }
}

extension LabeledRow where Leading == EmptyView {
    public init(_ title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.init(Text(title), subtitle: subtitle, leadingSize: 0, leading: nil, trailing: trailing())
    }

    public init(_ title: Text, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.init(title, subtitle: subtitle, leadingSize: 0, leading: nil, trailing: trailing())
    }
}

extension LabeledRow where Trailing == EmptyView {
    public init(
        _ title: String, subtitle: String? = nil, leadingSize: CGFloat = 32, @ViewBuilder leading: () -> Leading
    ) {
        self.init(Text(title), subtitle: subtitle, leadingSize: leadingSize, leading: leading(), trailing: nil)
    }

    public init(_ title: Text, subtitle: String? = nil, leadingSize: CGFloat = 32, @ViewBuilder leading: () -> Leading)
    {
        self.init(title, subtitle: subtitle, leadingSize: leadingSize, leading: leading(), trailing: nil)
    }
}
