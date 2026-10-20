// Generated from packages/common-ui/tokens.json by packages/common-ui/build.mjs. Do not edit;
// change the source and run `node packages/common-ui/build.mjs`.
// source sha256: c5d29da7dd133b3e043ec92b3624bb2624e0730e7e96198a1efed94c1b90bbba

import AppKit
import SwiftUI

/// The design tokens, as the apps consume them: the semantic colours, the spacing and radius scales,
/// motion, and the layout widths. Type comes from the system text styles, not from here.
public enum Tokens {
    /// SHA-256 of tokens.json when this file was generated. A test compares it to the file.
    public static let sourceHash = "c5d29da7dd133b3e043ec92b3624bb2624e0730e7e96198a1efed94c1b90bbba"

    public enum Text {
        /// Body text and headings. macOS: `labelColor`. Site: #1d1d1f / #f5f5f7.
        public static let primary = SemanticColor(system: .labelColor)

        /// Supporting text: ledes, captions, footers, table headers. macOS: `secondaryLabelColor`. Site: #6e6e73 /
        /// #86868b.
        public static let secondary = SemanticColor(system: .secondaryLabelColor)

        /// Text on an accent fill or over media. macOS: `white`. Site: #ffffff.
        public static let inverse = SemanticColor(system: .white)
    }

    public enum Surface {
        /// The page and window background. macOS: `windowBackgroundColor`. Site: #fbfbfd / #000000.
        public static let base = SemanticColor(system: .windowBackgroundColor)

        /// A card or panel resting on the base surface. macOS has no card colour, so the apps tint the base with a
        /// little of the text colour. macOS: #0000000c / #ffffff0c, ours. Site: #f2f2f5 / #1c1c1e.
        public static let card = SemanticColor(light: 0x000000, alpha: 0.047, dark: 0xffffff, alpha: 0.047)

        /// Behind a poster or video while it loads. Nothing is written on it. macOS has none: #e4e4ea / #1c1c1e,
        /// ours. Site: #e4e4ea / #1c1c1e.
        public static let media = SemanticColor(light: 0xe4e4ea, dark: 0x1c1c1e)

        /// Translucent bars that sit over content, blurred. In the apps this is a system material, not a colour.
        /// macOS has none: #fbfbfdcc / #000000b8, ours. Site: #fbfbfdcc / #000000b8.
        public static let chrome = SemanticColor(light: 0xfbfbfd, alpha: 0.800, dark: 0x000000, alpha: 0.722)

        /// A control floating over media, in either appearance. macOS has none: #1e1e228c / #1e1e228c, ours. Site:
        /// #1e1e228c.
        public static let overlay = SemanticColor(light: 0x1e1e22, alpha: 0.549, dark: 0x1e1e22, alpha: 0.549)
    }

    public enum Color {
        /// Links, focus, and the active state. The user's accent colour on macOS. macOS: `controlAccentColor`. Site:
        /// #0066cc / #2997ff.
        public static let accent = SemanticColor(system: .controlAccentColor)

        /// A filled button. One blue in both appearances so text.inverse keeps its contrast; macOS draws its own
        /// buttons. macOS: `controlAccentColor`. Site: #0071e3.
        public static let accentFill = SemanticColor(system: .controlAccentColor)

        /// Rules between sections and table rows. macOS: `separatorColor`. Site: #00000014 / #ffffff1f.
        public static let border = SemanticColor(system: .separatorColor)

        /// The hairline around a card. macOS has none: #0000000f / #ffffff0f, ours. Site: #0000000f / #ffffff0f.
        public static let borderCard = SemanticColor(light: 0x000000, alpha: 0.059, dark: 0xffffff, alpha: 0.059)

        /// The keyboard focus ring. macOS: `keyboardFocusIndicatorColor`. Site: #0066cc / #2997ff.
        public static let focus = SemanticColor(system: .keyboardFocusIndicatorColor)

        /// An error, or a destructive action. macOS: `systemRed`. Site: #d70015 / #ff453a.
        public static let danger = SemanticColor(system: .systemRed)

        /// Something that needs attention soon but is not yet wrong: memory pressure rising, a disk nearly full.
        /// macOS: `systemOrange`. Site: #c93400 / #ff9f0a.
        public static let warning = SemanticColor(system: .systemOrange)

        /// Something that is going well: charging, allowed, done. macOS: `systemGreen`. Site: #1e7a35 / #30d158.
        public static let success = SemanticColor(system: .systemGreen)
    }

    public enum Weight {
        public static let regular: Font.Weight = .regular
        public static let semibold: Font.Weight = .semibold
        public static let bold: Font.Weight = .bold
    }

    /// One scale for padding, margin, and gap, in points.
    public enum Space {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 40
        public static let xxxl: CGFloat = 56
        public static let section: CGFloat = 72
    }

    /// Radius, in points. xs is for small raised pieces such as a key cap; sm and up for cards and panels.
    public enum Radius {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let full: CGFloat = 9999
    }

    /// Durations in milliseconds and easings. Both surfaces drop to zero when the user asks for reduced motion.
    public enum Motion {
        public static let fast: TimeInterval = 0.15
        public static let base: TimeInterval = 0.25
        public static let slow: TimeInterval = 0.4

        public enum Easing {
            public static let standard = Curve(0.25, 0.1, 0.25, 1)
            public static let decelerate = Curve(0, 0, 0.2, 1)
            public static let accelerate = Curve(0.4, 0, 1, 1)
        }
    }

    /// Widths in points. The settings window and the menu panel are the apps'; the rest is the site's.
    public enum Layout {
        public static let settingsWidth: CGFloat = 460
        public static let menuPanelWidth: CGFloat = 320
        public static let content: CGFloat = 980
        public static let prose: CGFloat = 680
        public static let lede: CGFloat = 600
        public static let gutter: CGFloat = 22
        public static let gutterNarrow: CGFloat = 16
        public static let breakpointNarrow: CGFloat = 760
    }
}
