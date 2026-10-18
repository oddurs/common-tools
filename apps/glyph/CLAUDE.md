# Common Glyph

Common Glyph is a native macOS menu bar app written in Swift (AppKit plus SwiftUI) with no package dependencies. It shows any number of images or pieces of text of the user's choosing as status items, one each, managed and edited in Settings.

This is one app of the Common Tools monorepo. The workflow, the `scripts/task` seam, and the commit rules are in the root CLAUDE.md; this file holds what is specific to Common Glyph. Its area is `glyph`: `scripts/task check glyph`, `scripts/task run glyph`, `scripts/release glyph <version>`.

## Code

- `Sources/GlyphKit` holds every decision that can be made from plain values: the `Bitmap` type and its geometry (rotate, flip, crop, trim, downscale), background removal, the three styles, the `Edit` model and the order it applies in, the glyph's size in the menu bar, animation timing, and `GlyphSpec` with the `Library` rules for the list of glyphs (naming, duplicating, and that one glyph always stays visible). It imports nothing but the standard library, so it is tested without a screen.
- `Sources/CommonGlyph` is the thin app shell. `Imaging.swift` converts between Core Graphics and `Bitmap`, decodes files with ImageIO, draws text with Core Text, and lifts subjects with Vision. `GlyphModel` holds one glyph's spec and renders it off the main thread; `GlyphLibrary` owns the list and saves every spec. `MenuBarController` keeps one status item per visible glyph, each with a real `NSMenu` whose card (`Dropdown.swift`) is hosted SwiftUI built only while the menu is open. The SwiftUI views only bind to the models.
- An edit applies in one order: orientation, crop, subject lift, background, style, trim. The crop is stored in the oriented image's space, so `Edit.rotateClockwise()` and `Edit.flip()` move it with the image. Keep new steps in that pipeline, in `Edit`, with a test.
- Template styles (silhouette and ink) paint black and carry the shape in alpha, because macOS reads only a template image's alpha.
- Animation frames are trimmed to one shared box, so the menu bar can draw every frame at the first one's size.
- Each glyph's image is copied into `~/Library/Application Support/Common Glyph`; the specs live as one JSON array under the `glyphs` key in UserDefaults under `com.oddurs.commonglyph`. A new bundle identifier would start without either, so a rename needs a `LegacyIdentity` migration (root `CLAUDE.md`).
- Each status item saves its position under `glyph-<id>`. A new one gets a starting position near the clock written before the item is named, because macOS puts new items at the far left, where a menu bar manager hides them.
- `CommonTools.swift` is shared with Common Stats, Common Keys, and Common Bar. Change it in every repository together.
- Settings follows the Common Tools standard shared with Common Stats, Common Keys, and Common Bar: one grouped `Form` 460 points wide, a live preview first, the app's own sections with footnote footers, then General, then `CommonToolsSection`. A glyph's editor is a sheet over it. Menus follow the same family: cards first, then actions with SF Symbol icons on macOS 26, then Settings… and Quit.
- Nothing needs a permission prompt; keep it that way, and don't add private APIs.
- A behaviour change goes into GlyphKit with a test first. A bug fix comes with the test that would have caught it.
- The app icon comes from `scripts/make-icon glyph`, which writes `Resources/AppIcon.icns`, `docs/icon.png`, and `Resources/CommonTools/glyph.png`. Edit the script, not the images.


## Checks

Behaviour that depends on the live menu bar belongs in the app target; decisions that can be made from plain values belong in a type the tests can reach.

## Pull requests

Besides the shared checklist:

- [ ] UI changes include before/after screenshots
