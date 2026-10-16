# Working in this repository

Common Glyph is a native macOS menu bar app written in Swift (AppKit plus SwiftUI) with no package dependencies. It shows any number of images or pieces of text of the user's choosing as status items, one each, managed and edited in Settings.

## The seam

Do all automation through `scripts/task`. CI and the git hooks call nothing else.

```sh
scripts/task fmt       # format in place
scripts/task lint      # swift-format lint --strict, then a build with warnings as errors
scripts/task test      # GlyphKit and bundle tests
scripts/task build     # universal "build/Common Glyph.app"
scripts/task check     # lint + test + build
```

## Workflow

- Never commit to `main`. It only moves forward when a pull request is merged; the `pre-push` hook and branch protection both enforce this.
- One unit of work gets one worktree, one branch, and one pull request: `scripts/agent start <type>/<slug>`, then work in the printed path, `scripts/agent commit`, `scripts/agent pr`, and `scripts/agent done` after the merge.
- Branch types: `feat fix chore docs perf refactor test`.
- Run `scripts/task check` until it is green before opening a pull request. Never use `--no-verify`.
- In the pull request description, state the problem, the approach, and where a reviewer should be sceptical.

## Commits

Conventional Commits: `type(scope): subject`. Write the subject in the imperative, at most 72 characters, with no trailing period. The body says why. Never add assistant or tool attribution: no co-author trailers, no "generated with" footers. The `commit-msg` hook rejects them.

## Code

- `Sources/GlyphKit` holds every decision that can be made from plain values: the `Bitmap` type and its geometry (rotate, flip, crop, trim, downscale), background removal, the three styles, the `Edit` model and the order it applies in, the glyph's size in the menu bar, animation timing, and `GlyphSpec` with the `Library` rules for the list of glyphs (naming, duplicating, and that one glyph always stays visible). It imports nothing but the standard library, so it is tested without a screen.
- `Sources/CommonGlyph` is the thin app shell. `Imaging.swift` converts between Core Graphics and `Bitmap`, decodes files with ImageIO, draws text with Core Text, and lifts subjects with Vision. `GlyphModel` holds one glyph's spec and renders it off the main thread; `GlyphLibrary` owns the list and saves every spec. `MenuBarController` keeps one status item per visible glyph, each with a real `NSMenu` whose card (`Dropdown.swift`) is hosted SwiftUI built only while the menu is open. The SwiftUI views only bind to the models.
- An edit applies in one order: orientation, crop, subject lift, background, style, trim. The crop is stored in the oriented image's space, so `Edit.rotateClockwise()` and `Edit.flip()` move it with the image. Keep new steps in that pipeline, in `Edit`, with a test.
- Template styles (silhouette and ink) paint black and carry the shape in alpha, because macOS reads only a template image's alpha.
- Animation frames are trimmed to one shared box, so the menu bar can draw every frame at the first one's size.
- Each glyph's image is copied into `~/Library/Application Support/Common Glyph`; the specs live as one JSON array under the `glyphs` key in UserDefaults under `com.oddurs.commonglyph`. `BundleTests` guards the bundle identifier, since changing it would lose both.
- Each status item saves its position under `glyph-<id>`. A new one gets a starting position near the clock written before the item is named, because macOS puts new items at the far left, where a menu bar manager hides them.
- `CommonTools.swift` is shared with Common Stats, Common Keys, and Common Bar. Change it in every repository together.
- Settings follows the Common Tools standard shared with Common Stats, Common Keys, and Common Bar: one grouped `Form` 460 points wide, a live preview first, the app's own sections with footnote footers, then General, then `CommonToolsSection`. A glyph's editor is a sheet over it. Menus follow the same family: cards first, then actions with SF Symbol icons on macOS 26, then Settings… and Quit.
- Nothing needs a permission prompt; keep it that way, and don't add private APIs.
- A behaviour change goes into GlyphKit with a test first. A bug fix comes with the test that would have caught it.
- The app icon comes from `swift scripts/make-icon.swift`, which writes `Resources/AppIcon.icns`, `docs/icon.png`, and `Resources/CommonTools/glyph.png`. Edit the script, not the images.
