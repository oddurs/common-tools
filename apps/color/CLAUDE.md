# Common Color

Common Color is a native macOS menu bar colour picker written in Swift (AppKit plus SwiftUI) with no package dependencies. It is one of the Common Tools apps.

This is one app of the Common Tools monorepo. The workflow, the `scripts/task` seam, and the commit rules are in the root CLAUDE.md; this file holds what is specific to Common Color. Its area is `color`: `scripts/task check color`, `scripts/task run color`, `scripts/release color <version>`.

## Code

- `Sources/ColorKit` holds every decision that can be made from plain values: the colour spaces and their matrices, and the conversions between them. A behaviour change goes here with a test first. `Sources/CommonColor` is the app shell: status item, menu, and Settings.
- Correctness first. A conversion changes only with a test against a published reference value (CSS Color 4, Ottosson, WCAG) or ColorSync. Matrices are derived from the published primaries, not typed in. Nothing is clipped without being flagged.
- The app needs no permission; keep it that way, and don't add private APIs.
- A bug fix comes with the test that would have caught it.
- The app icon comes from `scripts/make-icon color`, which writes `Resources/AppIcon.icns`, `docs/icon.png`, and `shared/CommonTools/color.png`. Edit `icon.swift`, not the images.

## Pull requests

Besides the shared checklist:

- [ ] UI changes include before/after snapshots
- [ ] A conversion change cites the reference value its test checks against
