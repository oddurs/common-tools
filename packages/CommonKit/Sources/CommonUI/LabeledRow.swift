import SwiftUI

/// A row of a grouped form: an optional leading icon, a title with a secondary line under it, and
/// whatever acts on the row at the trailing edge. VoiceOver reads the row as one element, so the
/// trailing control's name follows the title.
///
///     LabeledRow("Common Stats", subtitle: "System stats in the menu bar") {
///         Image(nsImage: icon).resizable()
///     } trailing: {
///         Button("Open") { open() }
///     }
public struct LabeledRow<Leading: View, Trailing: View>: View {
    private let title: String
    private let subtitle: String?
    private let leading: Leading?
    private let trailing: Trailing

    public init(
        _ title: String, subtitle: String? = nil, @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(title, subtitle: subtitle, leading: leading(), trailing: trailing())
    }

    private init(_ title: String, subtitle: String?, leading: Leading?, trailing: Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
        self.trailing = trailing
    }

    public var body: some View {
        HStack(spacing: Tokens.Space.sm) {
            if let leading {
                leading.frame(width: 32, height: 32)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                if let subtitle {
                    Text(subtitle).font(.footnote).foregroundStyle(.secondary)
                }
            }
            Spacer()
            trailing
        }
        .accessibilityElement(children: .combine)
    }
}

extension LabeledRow where Leading == EmptyView {
    public init(_ title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.init(title, subtitle: subtitle, leading: nil, trailing: trailing())
    }
}
