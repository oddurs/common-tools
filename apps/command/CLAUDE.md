# Common Command

Common Command is a native macOS launcher, a Spotlight replacement, written in Swift (AppKit plus SwiftUI) with no package dependencies. It is part of the Common Tools family with Common Stats, Common Keys, Common Bar, and Common Glyph.

This is one app of the Common Tools monorepo. The workflow, the `scripts/task` seam, and the commit rules are in the root CLAUDE.md; this file holds what is specific to Common Command. Its area is `command`: `scripts/task check command`, `scripts/task run command`, `scripts/release command <version>`.

## Code

- `Sources/CommandKit` holds matching, ranking, usage, the calculator, link detection, and the catalogs, and contains no UI. `Sources/CommonCommand` holds the app shell: hotkey, panel, menu bar item, Settings, and the Spotlight file query.
- Speed is the product. Ranking runs on the main thread on every keystroke and must stay well under a millisecond for a real catalog; `PerformanceTests` enforces budgets. Don't loosen a budget to make a change pass. Anything slower (Spotlight, directory scans) runs off the main thread and never blocks the list.
- Public APIs only, and no permissions: the hotkey is Carbon's `RegisterEventHotKey`, files come from `MDQuery`, panes from the System Settings extension bundles. Don't add anything that needs Accessibility, Input Monitoring, or Full Disk Access.
- The panel is a non-activating `NSPanel`. Don't call `NSApp.activate()` when showing it; the user's app must stay frontmost.
- A bug fix comes with the test that would have caught it. Ranking changes need a test showing the order they fix.
- `CommonTools.swift` is shared word for word across the Common Tools apps. Change it in all of them together.
- For visual review, use `scripts/task build command && apps/command/.build/debug/CommonCommand --snapshot out.png "query" [--theme light|dark]` and inspect `out.png`. It renders offscreen; never drive the live screen with synthesized keys or the global shortcut to check a design.


## Checks

Behaviour that depends on AppKit or Spotlight belongs in the app target; matching, ranking, and parsing belong in CommandKit, where the tests can reach them.

## Pull requests

Besides the shared checklist:

- [ ] UI changes include before/after screenshots
