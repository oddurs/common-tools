# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Common Color joins the Common Tools family: an eyedropper in the menu bar, the Welcome window on first launch, and Settings with Open at login, the optional update check, and the other apps in the family.
- Pick a color from anywhere: press ⌃⇧⌘C or choose Pick Color, and click any pixel in the system's loupe. Escape cancels and leaves the clipboard alone. No permission is needed.
- The pick is copied in the format you choose in Settings: hex, `rgb()`, `hsl()`, `oklch()`, `color(display-p3 …)`, SwiftUI `Color` or AppKit `NSColor`. The menu lists the current color in every format, one click each.
- Correct conversions between sRGB, Display P3 and OKLCH. A color outside sRGB is marked, and the sRGB formats give the nearest color sRGB can show instead of clipping it silently.
- The last 12 picks as swatches in the menu, kept across launches: click one to use it again, or Clear them.
- The WCAG 2 contrast ratio between the newest two picks, with AA and AAA pass or fail for normal and large text.
- The shortcut can be changed in Settings; Delete restores ⌃⇧⌘C.
- `--snapshot` renders the menu, light and dark, for review.

[Unreleased]: https://github.com/oddurs/common-tools/commits/main/apps/color
