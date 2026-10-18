# Common Keys

Common Keys is a macOS menu bar app that fixes words typed on the wrong keyboard layout. It runs on **KeysKit**, an engine library that also ships as the `common-keys` CLI. Swift, AppKit plus SwiftUI, no package dependencies.

This is one app of the Common Tools monorepo. The workflow, the `scripts/task` seam, and the commit rules are in the root CLAUDE.md; this file holds what is specific to Common Keys. Its area is `keys`: `scripts/task check keys`, `scripts/task run keys`, `scripts/release keys <version>`.

## Code

- `Sources/KeysKit` is the engine, in layers: keys, keyboards (`KeyLayout`, `Composer`, `InputSources`), evidence (`Scorer`, `Orthography`, `Lexicon`, `Memory`), decisions (`Detector`). A layer never reaches up to the one above it. It holds no UI state.
- `Sources/CommonKeys` is the app shell: event tap and injection (`Engine`), status item and dropdown, Settings, hot keys. `Sources/KeysCLI` is a thin wrapper over the library.
- A key press is a key code plus modifiers, never a character. Read layouts with the system translator; don't hard-code character tables.
- Leaving a correct word alone matters more than fixing a wrong one. Any change to scoring or decisions comes with `common-keys eval` numbers before and after, and "correct words changed" must not rise.
- Text typed in a converting input method (Japanese, Chinese) is the user's pick and is never read back or fixed.
- Nothing leaves the Mac; the app makes no network requests. Typing is never logged: only daily counts and what the user taught (words meant in another layout, words to leave alone, mixed-up keys, per-app layouts) are saved, under `~/Library/Application Support/Common Keys/`.
- A bug fix comes with the test that would have caught it. Tests read the layouts and dictionaries installed on the machine; keep them to ones macOS ships.
- For menu changes, `cd apps/keys && swift build && .build/debug/CommonKeys --snapshot out.png` renders the dropdown offscreen in light and dark; `--status` renders the menu bar item's looks instead. (`scripts/task build` makes only a release build.)
- The app had an earlier name. `main.swift` carries its state over with CommonKit's `LegacyIdentity` before the engine loads: the defaults, the status item position (saved under `keys` now), and the Application Support folder, moved to `Common Keys/`. Keep that call while installs from before the rename may be updated. The Accessibility grant can't move, since macOS keys it by bundle identifier, so Welcome asks for it again.


## Checks

A change to how words are scored or decided needs `common-keys eval` numbers from before and after, so a reviewer can see what it costs in correct words changed.

## Pull requests

Besides the shared checklist:

- [ ] Detector changes include `common-keys eval` numbers before and after
- [ ] Menu changes include before/after snapshots (`.build/debug/CommonKeys --snapshot out.png`)
