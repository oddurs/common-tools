# Common Bar

Common Bar is a native macOS menu bar app written in Swift (AppKit plus SwiftUI) with no package dependencies. It hides the menu bar items left of an invisible divider.

This is one app of the Common Tools monorepo. The workflow, the `scripts/task` seam, and the commit rules are in the root CLAUDE.md; this file holds what is specific to Common Bar. Its area is `bar`: `scripts/task check bar`, `scripts/task run bar`, `scripts/release bar <version>`.

## Code

- The app was called Reasonal. Keep the bundle id `com.oddurs.reasonal`, the `Reasonal` executable target, the status item autosave names, and the UserDefaults keys: existing installs keep their item positions, preferences, and login item only while these stay put. `BundleTests` guards the bundle identifiers.
- Only the visible name is Common Bar: `CFBundleName`, `CFBundleDisplayName`, and menu text.
- `Sources/BarKit` holds every decision that can be made from plain values: divider lengths from saved positions (`DividerLayout`), the seed chain and autosave names (`ItemPositions`, `ItemName`), what a click does (`Reveal`), and the ⌘-peek, hover, and scroll state machines (`Peek`, `Hover`, `ScrollGesture`). It imports no AppKit and takes the time as a parameter, so it is tested without a menu bar.
- `Sources/Reasonal` is the thin app shell. `MenuBarController.swift` owns the status items, reads events and defaults, and feeds BarKit. `MenuBar.swift` answers where things are in the menu bar. Nothing needs a permission prompt; keep it that way, and don't add private APIs.
- Status item positions are read from the `NSStatusItem Preferred Position <name>` defaults macOS writes, because item windows aren't laid out at launch.
- A behaviour change goes into BarKit with a test first; the shell should only translate between AppKit and BarKit.
- A bug fix comes with the test that would have caught it.
- The app icon comes from `scripts/make-icon bar`, which writes `Resources/AppIcon.icns` and `docs/icon.png`. Edit the script, not the images.


## Checks

Behaviour that depends on the live menu bar belongs in the app target; decisions that can be made from plain values belong in a type the tests can reach.

## Pull requests

Besides the shared checklist:

- [ ] UI changes include before/after screenshots
