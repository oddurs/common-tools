# Common Shot

[![CI](https://github.com/oddurs/common-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/oddurs/common-tools/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Screenshots straight to the clipboard, for macOS. Press ⇧⌘2, drag over what you want, and paste it: into Claude, a terminal, a chat, a pull request, or a document.

- **The screen freezes first.** The shortcut captures every display before anything moves, so a menu, a tooltip, or a hover state is still there while you choose.
- **Drag, click, or Return.** Drag for an area, with its size in pixels and what it costs in tokens beside it, and a loupe of whole device pixels for the exact edge. What is outlined is exactly what is copied, on a Retina display or not. Click for the window under the pointer, captured on its own without what overlaps it. Return for the whole screen. Escape, a right-click, or the shortcut again cancels.
- **Hold ⌥ to copy the text instead.** The same gestures read the text in the shot on your Mac and copy that: an error message, a log, a stack trace. Code keeps its indentation. Text is exact and costs a fraction of the tokens an image does.
- **Sized for prompts.** Claude reads an image at about one token per 750 pixels, so by default a shot's long edge is capped at 1568 px: a full Retina screen costs about 2,100 tokens instead of 4,800, and a crop of an error or a few lines of code is left alone. Full resolution is one switch away.
- **PNG on the clipboard, and the file it was saved to.** Claude Code pastes the image with **Ctrl+V**, and a shot taken from a terminal says so. In Ghostty ⌘V pastes the file's path instead, which Claude Code attaches as the image too. Chats, issues, and documents, the Claude app among them, take it with ⌘V. Or drag the preview into the terminal, which drops in the same path.
- **Recent shots in the menu.** The menu bar menu shows the last few as thumbnails with their size and token cost; click one to copy it again. Settings decides how many are kept.
- **A preview in the corner** shows what was copied and roughly what it costs in tokens. It fades on its own; hover to keep it, drag the thumbnail out as a file, or click to dismiss it.

Free forever and open source under the MIT licence. Private: no analytics, no crash reports, no account; nothing you do is ever reported. No network access, and one permission: Screen Recording, which every screenshot tool needs.

## Install

Requires macOS 14 or later.

1. Download [CommonShot.zip](https://oddurs.github.io/common-tools/shot/) from the [latest release](https://oddurs.github.io/common-tools/shot/), unzip it, and move **Common Shot** to Applications.
2. Open it. The build is signed but not notarized, so the first time macOS will say it can't verify the developer. Go to **System Settings › Privacy & Security** and click **Open Anyway**. Alternatively, run:

   ```sh
   xattr -dr com.apple.quarantine "/Applications/Common Shot.app"
   ```

3. The Welcome window asks for Screen Recording access. Click **Open System Settings**, turn on Common Shot in **Privacy & Security › Screen & System Audio Recording**, then click **Quit and Reopen**: macOS applies the switch only after the app reopens. If Common Shot is already on there, that switch belongs to an earlier copy; click **Reset and Ask Again**.
4. Turn on **Open at login** in Settings.

## Usage

| Key | Does |
| --- | --- |
| ⇧⌘2 | Freeze the screen and start (change it in Settings) |
| Drag | Copy that area |
| Click | Copy the highlighted window, on its own |
| ↩ | Copy the whole screen under the pointer |
| ⌥ with any of these | Copy the text in it instead of the image |
| ⎋, right-click, ⇧⌘2 | Cancel |
| Ctrl+V in Claude Code | Paste the shot into the prompt |

Text recognition runs on your Mac with Vision. It reads code well but not perfectly: a line holding only a `}` and an underscore on its own are often missed. When every character matters, copy the image.

## Settings

- **Shortcut**: click and press a new one. Escape cancels; Delete restores ⇧⌘2.
- **Access**: whether Screen Recording is allowed, with a button to the right pane of System Settings.
- **Image**: for prompts (long edge at most 1568 px) or full resolution, and whether to show the preview.
- **History**: keep none, or the last 5 to 100 shots (the newest 6 in the menu, the rest under Older Shots), in `~/Library/Application Support/Common Shot/History`. Show it in Finder or clear it.
- **General**: show in the menu bar, and open at login. With the menu bar item hidden, open Common Shot from Finder to get back to Settings.

## Build from source

The Command Line Tools are enough; Xcode is not required.

```sh
scripts/task build shot  # universal build → build/shot/Common Shot.app
mv "build/shot/Common Shot.app" /Applications/
```

macOS ties Screen Recording access to the app's signature. An ad hoc signature names only the exact binary, so without more, every rebuild needs access again, and the switch already on in Privacy & Security silently applies to the old build. Run `scripts/dev-cert` once per Mac: it creates the self-signed "Common Tools Development" identity that every Common Tools app shares, trusts it for code signing (macOS asks for your password), and clears Common Shot's stale Screen Recording entry. `scripts/task build shot` signs with it from then on, so the grant survives rebuilds, and refuses to build without it rather than sign ad hoc. To undo it, delete that certificate in Keychain Access.

## Development

Common Shot lives in `apps/shot/` of [oddurs/common-tools](https://github.com/oddurs/common-tools), the monorepo for every Common Tools app, and shares [CommonKit](../../packages/CommonKit) with them. From the repository root:

```sh
scripts/setup                      # once: wire the git hooks
scripts/dev-cert                   # optional, once: a stable signing identity, so permissions survive rebuilds
scripts/task run shot              # build, quit the running copy, open the new one
scripts/task check shot            # lint + test + build, what CI runs for this app
scripts/task test shot --filter=X  # only the tests whose name matches
```

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for the workflow: `scripts/agent start`, `scripts/agent ship`, and `scripts/release shot <version>`.

[docs/design.md](docs/design.md) is the design spec: each moment of the flow, benchmarked against macOS and the best third-party tools, and what Shot decides.

To see how a change looks without pressing the shortcut or covering a screen, `.build/debug/CommonShot --render <folder>` draws every state of the overlay (idle, a window hovered, mid-drag with the size and the loupe, ⌥ for text, a drag into a corner, a drag on a 1× display beside a 2× one) and the preview, in light and dark, over a made-up desktop, and writes them as PNGs. It needs no permission and shows nothing on screen.

Two flags check changes end to end. Both need Screen Recording access for the terminal running them, and neither touches your settings:

- `swift build && .build/debug/CommonShot --capture out.png` runs the whole pipeline on the main display: freeze, size, encode, copy to the clipboard, and write what the clipboard holds to `out.png`.
- `.build/debug/CommonShot --overlay out.png 300,250,640,380` shows the overlay with that area dragged (points from the bottom-left), or with the window under the pointer highlighted if no area is given, captures it, and quits.

Layout:

- `Sources/ShotKit`: selection geometry, points to pixels, window hit-testing, what a press and release means, image sizing and token estimates, putting recognised text back in reading order with indentation, the shortcut model, and file naming. No UI, so it can be tested on its own.
- `Sources/CommonShot`: the global shortcut, ScreenCaptureKit, the overlay and loupe, Vision text recognition, the clipboard, the history, the preview, the menu bar item, and Settings.
- `Tests`: ShotKit unit tests, and checks that the app bundle keeps its identity.

## Licence

MIT. See [LICENSE](../../LICENSE).
