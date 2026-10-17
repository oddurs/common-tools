# Common Keys

Common Keys is a macOS menu bar app that fixes words typed on the wrong keyboard layout. It runs on **WorldKey**, an engine library that also ships as the `worldkey` CLI. Swift, AppKit plus SwiftUI, no package dependencies.

This is one app of the Common Tools monorepo. The workflow, the `scripts/task` seam, and the commit rules are in the root CLAUDE.md; this file holds what is specific to Common Keys. Its area is `keys`: `scripts/task check keys`, `scripts/task run keys`, `scripts/release keys <version>`.

## Code

- `Sources/WorldKey` is the engine, in layers: keys, keyboards (`KeyLayout`, `Composer`, `InputSources`), evidence (`Scorer`, `Orthography`, `Lexicon`, `Memory`), decisions (`Detector`). A layer never reaches up to the one above it. It holds no UI state.
- `Sources/LangSmart` is the app shell (the target keeps the pre-rename name): event tap and injection (`Engine`), status item and dropdown, Settings, hot keys. `Sources/WorldKeyCLI` is a thin wrapper over the library.
- A key press is a key code plus modifiers, never a character. Read layouts with the system translator; don't hard-code character tables.
- Leaving a correct word alone matters more than fixing a wrong one. Any change to scoring or decisions comes with `worldkey eval` numbers before and after, and "correct words changed" must not rise.
- Text typed in a converting input method (Japanese, Chinese) is the user's pick and is never read back or fixed.
- Nothing leaves the Mac; the app makes no network requests. Typing is never logged: only daily counts and what the user taught (words meant in another layout, words to leave alone, mixed-up keys, per-app layouts) are saved, under `~/Library/Application Support/LangSmart/`.
- A bug fix comes with the test that would have caught it. Tests read the layouts and dictionaries installed on the machine; keep them to ones macOS ships.
- For menu changes, `scripts/task build keys && apps/keys/.build/debug/LangSmart --snapshot out.png` renders the dropdown offscreen in light and dark.
- Old names stay where users' state is keyed to them: the `LangSmart` executable, bundle identifier `com.oddurs.langsmart`, the status item autosave name, the "LangSmart Development" signing identity, and `~/Library/Application Support/LangSmart/`. Renaming any of them loses users' Accessibility grant, settings or learned data.


## Checks

A change to how words are scored or decided needs `worldkey eval` numbers from before and after, so a reviewer can see what it costs in correct words changed.

## Pull requests

Besides the shared checklist:

- [ ] Detector changes include `worldkey eval` numbers before and after
- [ ] Menu changes include before/after snapshots (`.build/debug/LangSmart --snapshot out.png`)
