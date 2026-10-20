# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-10-20

### Added

- Common Color joins the Common Tools family: an eyedropper in the menu bar, the Welcome window on first launch, and Settings with Open at login, the optional update check, and the other apps in the family.
- Pick a color from anywhere: press ⌃⇧⌘C or choose Pick Color, and click any pixel in the system's loupe. Escape cancels and leaves the clipboard alone. No permission is needed.
- The pick is copied in the format you choose in Settings: hex, `rgb()`, `hsl()`, `oklch()`, `color(display-p3 …)`, SwiftUI `Color` or AppKit `NSColor`. A small card beside the pointer says what was copied, with the color and the exact text; Settings can turn it off.
- A panel like Control Center's under the eyedropper. The selected color leads, with a large swatch, its hex, its family and where it sits, and one row that copies it in your format. The other formats are under All Formats.
- The panel works from the keyboard: the arrow keys move through recent picks and the color above follows, Return copies in your format, 1–7 copy a format, Delete removes a pick (with Undo), and Escape closes.
- Correct conversions between sRGB, Display P3 and OKLCH. A color outside sRGB is marked, and the sRGB formats give the nearest color sRGB can show instead of clipping it silently.
- The last 12 picks as swatches, kept across launches: click one to copy it again, right-click to copy it as any format or remove it, or Clear them all.
- The WCAG 2 contrast ratio between the newest two picks, the highest bar it clears, and AA and AAA pass or fail for normal and large text.
- VoiceOver reads a color as its family and hex, each format as what it copies, and the contrast as a sentence.
- The shortcut can be changed in Settings; Delete restores ⌃⇧⌘C.
- `--snapshot` renders every state of the panel, the confirmation, and Settings, light and dark, for review.

[Unreleased]: https://github.com/oddurs/common-tools/commits/main/apps/color
[0.1.0]: https://github.com/oddurs/common-tools/releases/tag/color-v0.1.0
