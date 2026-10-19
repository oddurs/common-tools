# Common Color

Common Color is a native macOS menu bar colour picker written in Swift (AppKit plus SwiftUI) with no package dependencies. A shortcut shows the system's loupe; the pixel clicked goes to the clipboard as code, in the format the user writes. It is one of the Common Tools apps.

This is one app of the Common Tools monorepo. The workflow, the `scripts/task` seam, and the commit rules are in the root CLAUDE.md; this file holds what is specific to Common Color. Its area is `color`: `scripts/task check color`, `scripts/task run color`, `scripts/release color <version>`.

## Code

- `Sources/ColorKit` holds every decision that can be made from plain values: the colour spaces and their matrices, OKLab and OKLCH, CSS Color 4 gamut mapping, the formats, WCAG contrast, the history and how it is saved, and reading an `NSColor`. A behaviour change goes here with a test first. `Sources/CommonColor` is the app shell: status item, the panel (`MenuPanelHost`), picking, the copy confirmation (`ConfirmationHost`), and Settings. ColorKit also holds what the panel decides: colour families and spoken descriptions (`Describe.swift`), the contrast verdict, the arrow keys' moves (`GridMove`), the number keys (`ColorFormat.key`), and removing a pick with Undo.
- Correctness first. A conversion changes only with a test against a published reference value (CSS Color 4, Ottosson, WCAG) or ColorSync. Matrices are derived from the published primaries, not typed in. Nothing is clipped without being flagged: a format that can't hold a colour says so (`ColorFormat.isExact`).
- Every format is code that pastes as it is: CSS that a browser accepts, Swift that compiles. Numbers use a point whatever the Mac's region. `FormatTests` pins each format's text, and `theSwiftFormatsCompile` holds the Swift forms as code.
- Picking is `NSColorSampler` only. It needs no permission; keep it that way, and don't read the screen any other way. Escape gives the sampler's handler nil, and nil must leave the clipboard and history alone.
- The shortcut is CommonKit's `CommonShortcut` (Carbon's `RegisterEventHotKey`), saved under `hotKey`; the format under `format`; the picks under `history`, as Display P3 components. An unreadable history is set aside under `history.unreadable`, never overwritten.
- Swatches draw the picked colour itself through `ColorValue.cgColor`: data, not an interface colour, so Common UI's colour rule doesn't apply to them, and nothing in the app target writes a colour literal.
- A bug fix comes with the test that would have caught it.
- For visual review: `scripts/task build color && "build/color/Common Color.app/Contents/MacOS/CommonColor" --snapshot <folder>` renders every state of the panel, the confirmation, and Settings, light and dark (and Increase Contrast for three), offscreen; look at them before claiming anything about how Color looks. Copy `menu.png` to `docs/menu.png` when the panel changes. SwiftUI's `colorSchemeContrast` can't be set offscreen, so the stronger hairlines under Increase Contrast don't show in those renders.
- The menu bar icon stays the template eyedropper. Tinting it with the last pick was considered and left out: a white or pale pick vanishes on a light menu bar, and a non-template image loses the menu bar's own tinting.
- The app icon comes from `scripts/make-icon color`, which writes `Resources/AppIcon.icns`, `docs/icon.png`, and `shared/CommonTools/color.png`. Edit `icon.swift`, not the images.

## Pull requests

Besides the shared checklist:

- [ ] UI changes include before/after snapshots (`--snapshot`, from the built bundle)
- [ ] A conversion change cites the reference value its test checks against
