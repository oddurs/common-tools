# Working in this repository

Common Shot is a native macOS screenshot tool written in Swift (AppKit plus SwiftUI) with no package dependencies. A shortcut freezes the screen; a drag, click, or Return picks an area, a window, or the screen; the result goes to the clipboard as PNG. It is part of the Common Tools family with Common Stats, Common Keys, Common Bar, Common Glyph, and Common Command.

## The seam

Do all automation through `scripts/task`. CI and the git hooks call nothing else.

```sh
scripts/task fmt       # format in place
scripts/task fmt:check # swift format lint --strict, format only
scripts/task lint      # fmt:check, then a debug build with warnings as errors
scripts/task test      # ShotKit and bundle tests
scripts/task build     # universal build/Common Shot.app
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

- `Sources/ShotKit` holds every decision that can be made from plain values: what a press and release means (`Gesture`), putting Vision's text back in reading order with indentation (`TextLayout`), image sizing and token estimates, the drag-to-selection rectangle, points to pixels (AppKit counts up from the bottom-left in points, an image down from the top-left in pixels), global display coordinates to a screen's own, which window is on top under a point, the shortcut model, and file names. A behaviour change goes here with a test first.
- `Sources/CommonShot` is the app shell. `Capture` freezes every display through ScreenCaptureKit before the overlay appears, and captures a single window on its own. The window list comes from `CGWindowListCopyWindowInfo` because only it is ordered front to back. `Overlay` draws the frozen image in layers, so following the pointer moves shapes and never redraws the picture; the loupe is the same image through a `contentsRect`, which counts from the bottom left. `Recognize` runs Vision without language correction, because correcting identifiers breaks code. `Output` sizes the image, encodes PNG, and writes the clipboard. `History` keeps the PNGs that were copied, newest first, pruned to the limit in Settings; the status item's menu is rebuilt from it each time it opens.
- Prompt sizing exists to save Claude tokens, which follow pixels, not bytes, so the lever is dimensions; recompressing as JPEG would save nothing. `ImageSize` holds the cap and the token estimate; keep them in step with the published vision limits.
- The clipboard gets `public.png` only. Terminals read images through AppleScript's `«class PNGf»`, which is that type.
- Public APIs only. Screen Recording is the one permission; don't add anything that needs Accessibility, Input Monitoring, or Full Disk Access. The hotkey is Carbon's `RegisterEventHotKey`.
- The app activates while the overlay is up, so the crosshair shows and keys arrive, and hands focus back to the previous app when it closes.
- `CommonTools.swift` is shared word for word across the Common Tools apps. Change it in all of them together.
- A bug fix comes with the test that would have caught it.
- For visual review: `swift build && .build/debug/CommonShot --overlay out.png 300,250,640,380` and inspect `out.png`; `--capture out.png` checks the pipeline end to end, clipboard included.
- Screen Recording access is tied to the code signature. `scripts/task build` signs with the "Common Tools Local Signing" identity from `scripts/setup-signing` when the Mac has it, and ad hoc otherwise; with ad hoc, each rebuild must be allowed again, and the old switch looks on but no longer applies.
- The app icon comes from `swift scripts/make-icon.swift`, which writes `Resources/AppIcon.icns`, `docs/icon.png`, and `Resources/CommonTools/shot.png`. Edit the script, not the images.
