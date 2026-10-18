# Common Shot

Common Shot is a native macOS screenshot tool written in Swift (AppKit plus SwiftUI) with no package dependencies. A shortcut freezes the screen; a drag, click, or Return picks an area, a window, or the screen; the result goes to the clipboard as PNG. It is one of the Common Tools apps.

This is one app of the Common Tools monorepo. The workflow, the `scripts/task` seam, and the commit rules are in the root CLAUDE.md; this file holds what is specific to Common Shot. Its area is `shot`: `scripts/task check shot`, `scripts/task run shot`, `scripts/release shot <version>`.

## Code

- `Sources/ShotKit` holds every decision that can be made from plain values: what a press and release means (`Gesture`), putting Vision's text back in reading order with indentation (`TextLayout`), image sizing and token estimates, the drag-to-selection rectangle, points to pixels (AppKit counts up from the bottom-left in points, an image down from the top-left in pixels), global display coordinates to a screen's own, which window is on top under a point, snapping a selection to device pixels, where the size pill and the loupe go near an edge or the notch (`Placement`), arrow-key nudges, Space-to-move and settling a corner on visible window edges (`Precision`), the shortcut model, and file names. A behaviour change goes here with a test first.
- `Sources/CommonShot` is the app shell. `Capture` freezes every display through ScreenCaptureKit before the overlay appears, and captures a single window on its own. The window list comes from `CGWindowListCopyWindowInfo` because only it is ordered front to back. `Overlay` draws the frozen image in layers, so following the pointer moves shapes and never redraws the picture; the loupe is the same image through a `contentsRect`, which counts from the bottom left. A system material would blur the live screen behind the overlay, not the frozen one, so `Material` blurs the frozen picture once, small and off the main thread, and the size pill and hint draw their part of it under the window colour; every layer sets `contentsScale`, or it renders at 1× and blurs on Retina. `Shutter` plays the system's own screen-capture sound as a system sound, which makes macOS apply the sound-effects setting, volume and device; don't read those settings by hand. `Toast` is the preview: it flies in from the pick, slides and swipes like the system's thumbnail, and shows before the PNG exists, so `attach(file:)` arms the drag once it does. `Recognize` runs Vision without language correction, because correcting identifiers breaks code. ShotKit's `PNG` sizes the image, converts it to sRGB (prompts read a PNG's numbers as sRGB, whatever its profile), and encodes it, with a Benchmark gate; `Output` writes the file and the clipboard. `Capture` takes every display at once, `Overlay.warmUp` and `Capture.warmUp` move first-use costs to launch, and a hovered window is captured while the pointer is over it, falling back to the frozen picture if it closes. `AppController` logs shortcut-to-overlay and pick-to-clipboard times under the `latency` category. `History` keeps the PNGs that were copied, newest first, pruned to the limit in Settings; the status item's menu is rebuilt from it each time it opens.
- Prompt sizing exists to save Claude tokens, which follow pixels, not bytes, so the lever is dimensions; recompressing as JPEG would save nothing. `ImageSize` holds the cap and the token estimate; keep them in step with the published vision limits.
- The clipboard gets one item: `public.png` and a `public.file-url` to the saved PNG (`ShotKit/Clipboard`). Claude Code's Ctrl+V reads the PNG (natively, or as AppleScript's `«class PNGf»`); a terminal's ⌘V pastes text, and Ghostty turns the file URL into its path; Chromium apps take the file over the image. No plain text, or every text field would get a path. The file is written before the clipboard, so it always exists.
- Public APIs only. Screen Recording is the one permission; don't add anything that needs Accessibility, Input Monitoring, or Full Disk Access. The hotkey is Carbon's `RegisterEventHotKey`.
- The app activates while the overlay is up, so the crosshair shows and keys arrive, and hands focus back to the previous app when it closes.
- `CommonTools.swift` is shared word for word across the Common Tools apps. Change it in all of them together.
- A bug fix comes with the test that would have caught it.
- For visual review: `swift build && .build/debug/CommonShot --render <folder>` writes every overlay state and the preview, light and dark, drawn offscreen over a made-up desktop on a 2× and a 1× display (`Render`); look at the PNGs before claiming anything about how Shot looks. It shows nothing on screen and needs no permission. `--overlay out.png 300,250,640,380` shows the real overlay on your screens and captures it; `--capture out.png` checks the pipeline end to end, clipboard included.
- Screen Recording access is tied to the code signature. With ad hoc signing each rebuild must be allowed again, and the old switch in System Settings looks on but no longer applies; `scripts/dev-cert` once per Mac fixes that for every Common Tools app.
- The app icon comes from the glyph region of `scripts/make-icon shot`, which writes `Resources/AppIcon.icns` and `docs/icon.png`. Edit the script, not the images; `Resources/CommonTools/shot.png` comes from the standard, so a new glyph goes there too.


## Checks

Behaviour that depends on AppKit or ScreenCaptureKit belongs in the app target; geometry, shortcuts, and file naming belong in ShotKit, where the tests can reach them.

## Pull requests

Besides the shared checklist:

- [ ] UI changes include before/after screenshots
