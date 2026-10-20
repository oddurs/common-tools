# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- A new folder dropdown. It opens on the press like a menu, in about 10 ms, without taking focus from the app you're in. Rows come in groups with quiet headers. macOS's own items (Wi‑Fi, Battery, Focus, Now Playing) show their own symbol and, where macOS says it, their state. Start typing to narrow the list; arrows, Return and Escape work as in a menu; **Edit Folder…** and **Settings…** sit at the bottom.
- Opening an icon that can't be moved beside its folder turns the dropdown into a copy of the icon's menu, in place, with a way back; submenus open the same way. A row that couldn't be opened says so for a moment instead of the dropdown vanishing.
- Folders of your own. Add, rename, choose a symbol for, reorder, and delete folders in Settings › Folders, and choose the folder for each icon under **Icons in Folders**. More keeps every icon no other folder holds. Each folder is its own item in the menu bar.
- An icon chosen in a folder opens its menu under that folder. One near the divider is ⌘-dragged in beside the folder, the pointer hidden and put back where it was, and dragged back to its place afterwards. One further along has its menu read through Accessibility and shown from the folder, and the item you choose is pressed in the real menu. An icon that shows a panel or popover instead opens wherever it comes on screen. **Open icons beside their folder** in Settings turns this off.

### Changed

- A new icon in the app's own colour. Each Common Tools app now has its own hue on one shared ramp, so the family reads as a set and each app is easy to tell apart.
- Common Bar goes by its own name inside too: the bundle identifier is `com.oddurs.commonbar` and the executable `CommonBar`, like every Common Tools app. The first launch after the update quits the old copy if it's still running and brings your settings and the positions of More and its divider over.
- macOS asks for Accessibility once more after this update, the first time you open More. Permissions belong to the bundle identifier, which changed, so the old grant doesn't carry over. An old Common Bar switch left on in System Settings › Privacy & Security › Accessibility belongs to the earlier copy; select it and click − to remove it.
- Open at login should carry over: the first time the old login item opens Common Bar, the new one takes its place. If Common Bar doesn't open at your next login, turn on **Open at login** in Settings › General again; an old Common Bar entry left in System Settings › General › Login Items can be removed with −.
- More opens at once. It is the status item's own menu now, opened by macOS on the press like any other, and its rows are worked out ahead of time in the background instead of asking every app on each click.
- More's rows come in groups with a line between: other apps' icons, then Common Tools', then macOS's own, each app's icons together.
- Folders show their names beside their symbols. Turn that off with **Show folder names in the menu bar** in Settings.
- Common Bar is now folders. The chevron became **More**, and every icon left of your folders stays off-screen all the time instead of sliding into the menu bar on request, so nothing lands under the notch or behind the app's menus and nothing reshuffles. Click a folder to see its icons, each with its app's icon and name, and choose one to open its menu under that folder. Icons you had hidden, always-hidden ones included, are all in More now; icons right of the chevron stay in the menu bar.
- Common Bar needs Accessibility to list and open the icons in More, and asks the first time you open it, never at launch. Until then More says why and how many icons it holds. Tidying the menu bar still needs no permission.
- Settings never grows taller than the screen it opens on; a long one scrolls. Under **Open at login** the General section now says “Starts when you log in.”, or what stands in the way, and the Common Tools section carries the family promise: free and open source, forever; nothing leaves your Mac.
- Settings follows the layout shared by every Common Tools app: the same window, width, grouped sections, and footnotes as Common Stats and Common Keys.

### Added

- A Welcome window on first launch: what Common Bar does, Open at login, and the Common Tools family.
- An optional update check in Settings › General, off by default. When on, it asks GitHub for the latest release once a day and sends nothing about you or your Mac; a newer version shows as a link under the toggle.

### Removed

- Showing hidden icons in the menu bar: clicking the chevron, hovering over or clicking empty menu bar space, scrolling on the bar, holding ⌘ to see them, ⌥-click, and hiding them again after a few seconds. More replaces all of them.
- The always-hidden section and its dotted line. Settings no longer has Show Hidden Icons When, Hide again after, or Always-hidden section.
- The first-launch tips and **How to Arrange…**, which taught ⌘-dragging icons past the chevron.

### Fixed

- Welcome answers clicks: it is now a plain titled window, built like Settings. It shows once for the whole Common Tools family, from whichever app opens first, and never on top of another app's; a later app shows it only for a permission it is missing.

## [0.3.0] - 2026-10-16

### Added

- A **Common Tools** section at the end of Settings that lists Common Stats, Common Keys, and Common Bar, opens the ones you have, and links to the others. It also shows Common Bar's version.

### Changed

- Settings follows the layout shared by the Common Tools apps: **Show Hidden Icons When** first, then **General** with **Open at login** and **Hide again after**, then **Common Tools**. Labels are in sentence case, as in System Settings.
- A failure to change **Open at login** shows under the General section instead of in an alert.
- Quieter menu bar icons: a smaller chevron and a finer dotted line.
- The always-hidden section is optional and off by default. Turn it on with **Always-hidden section** in Settings → General. While it's off there's no dotted line, ⌥-click acts like a click, and icons that were behind the dotted line hide and show with the rest. Turning it back on restores where the line was.

### Fixed

- Icons dragged just past the chevron now hide. Before, they had to go left of a separate line that could drift away from the chevron, and icons dropped between the two stayed visible. The chevron is now the edge, and the solid line is gone; the dotted always-hidden line is unchanged.

## [0.2.1] - 2026-10-16

### Changed

- New app icon, in the blue glass style shared by Common Stats, Common Keys, and Common Bar.

## [0.2.0] - 2026-10-16

### Added

- A Settings window. Open it with **Settings…** (⌘,) in the chevron's right-click menu, or by opening Common Bar again while it runs.
- **Hide Again After:** choose 5 seconds, 10 seconds, 30 seconds, 1 minute, or Never.
- **Show Hidden Icons When:** turn hovering, scrolling down, and clicking empty menu bar space on or off one by one.

### Changed

- **Open at Login** moved from the right-click menu to Settings.
- Revealed items hide again after 10 seconds by default, up from 8.

## [0.1.0] - 2026-10-16

### Added

- A chevron in the menu bar and an invisible divider to its left. Collapsing stretches the divider so every item left of it moves off-screen.
- Click the chevron to show or hide the items.
- Rest the pointer on empty menu bar space, click it, or swipe down on the menu bar to show hidden items. Swipe up to hide them again.
- Items shown by a click or swipe hide again after 8 seconds, but not while the pointer is in the menu bar or a menu is open. Items shown by hovering hide half a second after the pointer leaves the menu bar.
- An always-hidden section behind a second, dotted divider. Its items stay hidden when the others show; ⌥-click the chevron to show everything.
- Hold ⌘ over the menu bar to show both dividers and every hidden item, then ⌘-drag icons across the dividers to choose what hides.
- If a divider is dragged out of order, it doesn't stretch, so collapsing never pushes the chevron or the visible items off-screen.
- First-launch tips, also available from **How to Arrange…** in the right-click menu, along with **Open at Login** and **Quit**.
- Universal (Apple silicon and Intel) builds for macOS 14 and later.

[Unreleased]: https://github.com/oddurs/common-tools/commits/main/apps/bar
[0.3.0]: https://github.com/oddurs/common-bar/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/oddurs/common-bar/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/oddurs/common-bar/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/oddurs/common-bar/releases/tag/v0.1.0
