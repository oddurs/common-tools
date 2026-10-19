# Common Bar: design

The spec a change to Common Bar is checked against. Bar does one thing: it keeps the menu bar tidy on a crowded, notched Mac. The icons you rarely use wait in folders, off-screen, and each is one click and one choice away. Every moment below should feel like part of macOS, and better than macOS where macOS has nothing. "Pure" means restraint: a key, a setting or a pixel of chrome has to pay for itself.

## The benchmark

| | Strong at | Weak at, for this job |
| --- | --- | --- |
| **macOS menus and Control Center** | Menus open on the press, are keyboard-driven from the first frame (arrows, Return, Escape, type-select), never take focus from the app you're in, and follow Reduce Transparency and Increase Contrast. Control Center's modules group controls in cards with quiet headers, and a module drills into its detail in place, with a way back. ⌘-dragging an icon reorders the menu bar; ⌘-dragging one out removes a system item. As of macOS 26, System Settings › Menu Bar lists apps' items with a switch each. | Nothing for a full bar: icons past the notch are simply gone, with no way to reach them. Type-select jumps to an item but never narrows the list. |
| **Bartender 5** | Every hidden icon reachable from a bar under the menu bar. A Settings list of the real icon images in Shown, Hidden and Always Hidden, dragged between sections. Groups, quick search, hotkeys, triggers, styling (tint, shadow, rounded bar), profiles. | Breadth: dozens of options and two permissions up front, Screen Recording among them, to draw the icon images. Its bar is another surface competing with the menu bar. |
| **Ice** | Open source. Visible, Hidden and Always-Hidden sections in a drag-and-drop layout of item images, a bar under the menu bar, hover, click and scroll to show, appearance (tint, borders, split shapes), and item spacing. | Spacing works by writing global defaults and relaunching every app with a menu bar item. Images need Screen Recording. The same inline reveal that strands icons under a notch. |
| **Hidden Bar, Dozer** | One chevron and a line; nothing to learn. | The same inline reveal, which on a notched display puts icons under the notch, where macOS reshuffles them. No editor, no way to see what is hidden. |
| **Raycast-style lists** | Type to filter, from the first key; arrows and Return; sections with quiet headers; a subtitle and an accessory per row; actions that drill in without leaving the window. | A launcher, not a menu bar extra: it activates its app and takes focus. |

Bar's edge is the folder: nothing is ever revealed inline, so nothing lands under the notch, and every hidden icon is reached from a dropdown that behaves like a menu. The design keeps that edge and borrows the best of the rest: Raycast's filter, Control Center's in-place drill-in, Bartender's sections, and the menu's timing and focus.

## The dropdown

**The choice: a panel, not an `NSMenu`.** A real menu gives native feel and keyboard for free, but it can't filter as you type, can't hold a status line or a quiet section header the way Control Center does, and can't turn into the icon's own menu in place. That last one is the owner's ask: "it should replace the whole dropdown with the icon". So the dropdown is Common UI's `MenuPanelHost`: the menu's own material, a non-activating panel that takes the keyboard without taking focus from the app you're in, closed by Escape or a click outside. It must be indistinguishable from a menu in timing and focus, or it isn't worth it.

**1. Opening.** On the press, not the release, like every menu bar extra, with the folder highlighted. The panel and its view are built once and kept; opening is ordering in a window already laid out, under 16 ms of main-thread work, measured and logged. Rows come from the background refresh, never from asking apps on the click. Aligned under the folder with its left edge, as a menu is, and kept inside the screen. A second press on the folder closes it.

**2. Width and stability.** The width is the menu panel width from Common UI, not the longest name, so it never changes as rows refresh. A row that changes while the panel is open updates in place. A row that comes or goes changes the height at the bottom edge, never moving the row under the pointer.

**3. Rows.** The app's own icon at 16 pt, drawn from its icon at the screen's scale. macOS's own items (Wi‑Fi, Battery, Focus, Now Playing, Bluetooth, Sound, the clock) all belong to Control Center, so they show their SF Symbol, not Control Center's icon. The name is the app's, or the item's own label when the app has several or the app is macOS. A status line on the right in the secondary colour when Accessibility already gives one, for free: Wi‑Fi's network state, a battery's percentage. Hover and keyboard selection share one highlight, the accent fill of a menu item.

**4. Groups.** Other apps, then Common Tools, then macOS, with a quiet section header for each when a folder has more than one group, and an app's icons together. A folder's order setting can sort by name instead.

**5. Keyboard.** The first arrow selects the first row; arrows move, Return opens, Escape closes. Typing filters at once: a field appears at the top with what was typed, matching names and labels anywhere in them, the first match selected. Delete edits the filter, Escape clears it first and closes second. A folder's shortcut opens it with the keyboard already in it.

**6. Opening an icon.** The handoff is continuous, never a close and a reopen.
- **An icon a drag can reach:** the dropdown stays up while the icon comes in beside the folder, and closes as the icon's own menu appears under the folder, in the same place.
- **An icon too far along:** the dropdown turns into a copy of the icon's menu in place, headed by the icon with a back arrow. Submenus drill in the same way. Choosing an item presses it in the real menu, opened unseen, and closes the panel.
- **A panel or popover** (Wi‑Fi, Battery): the dropdown closes as the icon's panel appears, wherever that is.
- **Slow or failed:** the chosen row shows a quiet progress mark, never a spinner over the list. A failure says so in the row ("Couldn't open Dropbox") for a moment, and the list stays usable.

**7. Footer.** Two rows, separated: **Edit Folder…** opens the folder manager on this folder; **Settings…** opens Settings. Nothing else.

**8. Empty and missing.** An empty folder says how to fill it: "⌘-drag an icon onto this folder, or choose its icons in Settings." Without Accessibility the panel says why in one sentence, with **Allow Accessibility…** and a count of the icons waiting, never an empty list.

**9. Feel and access.** System menu material, so Reduce Transparency and Increase Contrast apply. A fade on the tokens' fast duration, nothing with Reduce Motion. Every row is a VoiceOver element: its name, its status, its position in its group. The filter field is announced, and so is a change of contents.

## Arranging

**10. ⌘-drag into a folder, in the menu bar.** macOS's own gesture, extended:
- Holding ⌘ and pressing an icon marks every folder as a drop target. A folder under the pointer highlights as a menu bar item does when pressed.
- Dropping an icon on a folder files it there. Bar moves it off-screen, left of the divider, and a small confirmation under the folder names the icon and the folder for a second.
- Dropping it anywhere right of the divider leaves it in the menu bar, which is pinning.
- Bar watches; it never fights macOS's own reorder. It reads where the icon landed from the window list once the drag ends.

**11. The folder manager.** In Settings, a picture of the menu bar as sections: **In the Menu Bar** (pinned), then each folder, then **More**, which holds whatever no folder does.
- Each icon is a tile with its app's icon and name.
- Tiles drag between sections and reorder within one.
- A folder's header holds its symbol (a picker of SF Symbols), its name (renamed in place), what the menu bar shows (symbol, name, or both) and its order (menu bar, name, or manual, which a drag inside it sets).
- Deleting a folder sends its icons to More, with Undo.
- Beside the sections, a preview of the selected folder's dropdown, drawn by the dropdown's own view.
- Moving a tile into **In the Menu Bar** moves the real icon, where a drag can reach it. When it can't, the tile says so and how: ⌘-drag it from the menu bar while its folder is open.

## Settings

**12. Shape.** A sidebar window like System Settings, because Folders now needs room the one-column form doesn't have. Panes:
- **Folders:** the manager.
- **Opening:** opening beside the folder, and the per-folder shortcuts.
- **General:** Open at login, the update check, Accessibility's state, then the Common Tools section last.

The family standard holds inside General. `SettingsWindowHost` gains a sidebar layout as a shared primitive rather than Bar building its own window, and AppContract accepts either shape. That touches every app, and the pull request says so.

**13. Options, each with its reason.**
- **Folder appearance (symbol, name, or both)**, per folder. A name tells folders apart; a symbol saves room.
- **Order inside a folder (menu bar, name, manual)**, per folder. Menu bar order is free, name order is findable, manual is what a drag means.
- **A shortcut per folder**, opening it with the keyboard in it. A keyboard user's way in.
- **Open icons beside their folder**, on by default. Moving an icon plays a ⌘-drag with the pointer; someone who'd rather it didn't can turn it off.

**14. Not doing, and why.**
- **Spacing between menu bar icons.** Only an undocumented global default changes it, and it applies only after every app with an icon relaunches.
- **Live icons through Screen Recording.** The app's icon and, for macOS's items, their SF Symbol already tell rows apart, without a second permission.
- **A choice between icon names and app names.** The row already shows whichever says more.
- **Importing an old hidden set.** Everything earlier versions hid is in More already.
- **Also not:** a bar under the menu bar, triggers, profiles, menu bar tinting. Each is good somewhere; none makes a hidden icon nearer.

## Rules that hold everywhere

- System controls, text styles and materials, and the user's accent colour. A Common UI token only where macOS has nothing.
- Reduce Motion: things appear, nothing slides. Reduce Transparency: materials go solid. Increase Contrast: outlines on every floating piece.
- Nothing is revealed in the menu bar. An icon comes on screen only to be opened or moved, and goes back.
- Never press an icon that isn't wholly on screen, never start a drag behind the app's menus, and never act on another app's icon during development on someone's Mac.
- Logic (geometry, grouping, filtering, keys, drops, order) lives in BarKit with tests on recorded geometry. The dropdown, the manager and Settings render offscreen in every state, light and dark, so a change is judged from pictures, and the owner judges the feel by hand.
