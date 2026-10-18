# Common Bar

Common Bar is a native macOS menu bar app written in Swift (AppKit plus SwiftUI) with no package dependencies. A divider left of its More folder stays stretched, so every icon left of it is off-screen all the time; More lists those icons and opens them.

This is one app of the Common Tools monorepo. The workflow, the `scripts/task` seam, and the commit rules are in the root CLAUDE.md; this file holds what is specific to Common Bar. Its area is `bar`: `scripts/task check bar`, `scripts/task run bar`, `scripts/release bar <version>`.

## Code

- The app had an earlier name. `main.swift` carries its defaults (item positions and preferences) over with CommonKit's `LegacyIdentity`, leaving behind `askedForAccessibility`, which belonged to the old identity's grant. Keep that call while installs from before the rename may be updated. The status item autosave names (`ItemName`) hold no old name and stay as they are.
- `Sources/BarKit` holds every decision that can be made from plain values: how far the divider stretches (`DividerLayout`), the seed positions and autosave names (`ItemPositions`, `ItemName`), where every icon is (`MenuBarModel`), which app owns each hidden icon and what to call it, where to bring one to open it, and when what it opened has closed (`Folder.swift`), the folders and which icons each holds (`FolderConfig`), and the ⌘-drag that moves an icon beside its folder and back (`Move`). It imports no AppKit and takes the time as a parameter, so it is tested without a menu bar.
- `Sources/CommonBar` is the thin app shell. `MenuBarController.swift` owns the status items and the folder's menu and feeds BarKit. `MenuBar.swift` reads the window list and, through `MenuBarExtras`, each app's `AXExtrasMenuBar`. Tidying needs no permission; listing and opening icons needs Accessibility, asked the first time the folder opens and never at launch. Don't add private APIs.
- Never press an icon that isn't wholly on screen: its menu opens off-screen, invisible, and still takes the keyboard. `Opener` checks the window server before pressing.
- AppKit's frame for a status item lags its real place after a length change, in Common Bar and in every other app: track Common Bar's own items by window-server id (`windowServerFrame(of:)`), find another app's Accessibility element while its icon is at rest, and expect an app to place its menu from where it last knew its icon to be. `Opener` closes a menu that opened away from its icon and presses again.
- Test opening against a throwaway status item app of your own, never another app's icon, and read `log show --predicate 'subsystem == "com.oddurs.commonbar"'` (categories `folders` and `open`).
- Never press another app's menu bar item while developing on a Mac someone is using. Test opening against your own status items.
- `MenuBarModel` (BarKit) is every status item in a screen's menu bar, built from `CGWindowListCopyWindowInfo` bounds, which need no permission: where each is, whether it can be seen (visible, under the notch, behind the app's menus, off-screen), and which side of the divider it is on. Test it on recorded geometry. On macOS 26 every status item window belongs to Control Center and has no name without Screen Recording, Bar's own included, and the window server calls none of them on screen: list them with `.optionAll`, and recognise Bar's items by frame, never by name or owner. AppKit's window numbers for status items aren't the window server's.
- Status item positions are read from the `NSStatusItem Preferred Position <name>` defaults macOS writes, because item windows aren't laid out at launch.
- A behaviour change goes into BarKit with a test first; the shell should only translate between AppKit and BarKit.
- A bug fix comes with the test that would have caught it.
- The app icon comes from `scripts/make-icon bar`, which writes `Resources/AppIcon.icns` and `docs/icon.png`. Edit the script, not the images.


## Checks

Behaviour that depends on the live menu bar belongs in the app target; decisions that can be made from plain values belong in a type the tests can reach.

## Pull requests

Besides the shared checklist:

- [ ] UI changes include before/after screenshots
