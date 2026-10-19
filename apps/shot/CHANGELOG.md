# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- The screenshot sound, the one macOS plays for its own, as you let go. It follows "Play user interface sound effects", the alert volume and the sound-effects device in System Settings, and Settings › Image can turn it off.
- The shot shrinks from where you picked it into the preview in the corner, a quarter of a second; with Reduce Motion the preview just appears. VoiceOver announces what was copied.
- Precision while you aim: the arrow keys move the pointer by one device pixel (ten with ⇧), and during a drag they move the corner you're dragging; hold Space during a drag to move the whole selection, as in macOS; and a dragged corner settles on the edge of a window, or of the screen, when it comes within 5 points of one. An edge hidden behind another window doesn't count, and the arrow keys never snap.
- A Welcome window on first launch: what Common Shot does, the Screen Recording permission it needs with a live check and a button to System Settings, Open at login, and the Common Tools family.
- An optional update check in Settings › General, off by default. When on, it asks GitHub for the latest release once a day and sends nothing about you or your Mac; a newer version shows as a link under the toggle.
- A global shortcut (⇧⌘2 by default, recordable in Settings) that freezes every display and shows an overlay over them.
- Drag for an area, with its size in pixels and a loupe; click for the window under the pointer, captured on its own; Return for the whole screen; Escape, right-click, or the shortcut again to cancel. A hint along the bottom names the keys.
- Hold ⌥ to copy the text in an area, window, or screen instead of the image, read on the device with Vision. Monospaced text keeps its indentation, and `name. member` is read back as `name.member`.
- Shots go to the clipboard as PNG, sized for prompts by default: the long edge at most 1568 px, which keeps a full screen near 2,100 Claude tokens. Full resolution is a setting.
- A preview of each shot in the screen's corner, with its size and estimated token cost, and a reminder to paste with Ctrl+V when the shot was taken from a terminal. Hover keeps it, dragging the thumbnail drops the PNG as a file, and a click dismisses it.
- Recent shots in the panel the menu bar item opens, grouped under Today, Yesterday, Earlier This Week and Older, as a grid of thumbnails, each with when it was taken, the app it came from, its size and its token cost. Click one to copy it again, drag it out as a file, or use its context menu to show it in Finder or move it to the Trash. The keyboard does it all: arrows move, Return copies, Delete moves to the Trash with Undo (⌘Z), Escape closes. Keeps the last 10 by default, from none to 100.
- Settings: shortcut, Screen Recording status, image size, preview, history depth, menu bar item, and open at login.

### Changed

- The menu bar item opens a panel instead of a menu, in the family's look: Take Screenshot with its shortcut, the history in cards by day, then Open History Folder, Settings and Quit. It closes on a click outside or Escape, scrolls when the history is taller than the screen, and says so plainly when there are no shots yet or History is off.
- The menu shows the shortcut beside Take Screenshot, where macOS shows every menu's, instead of on a line of its own; that line now appears only when the shortcut couldn't be registered.
- Settings is shorter and plainer: Access appears only while Screen Recording is missing, "Image" is now "Shots" (size on the clipboard, the preview, the sound), and the footnotes name the keys, Option for text included.
- The preview behaves like the system's thumbnail: it slides in from the screen's right edge and back out when its time is up, and a two-finger swipe or a drag to the right sends it away early. It appears as you let go, before the PNG is even encoded, and its thumbnail can be dragged out as soon as the file is written.
- Faster from the shortcut to the overlay and from letting go to the clipboard. ScreenCaptureKit and the overlay are warmed up at launch, every display is captured at once, and a window is captured while you hover it, so a click copies it at once. On an M-series MacBook Pro the overlay is up about 25 ms after the shortcut, a dragged area is on the clipboard about 15 ms after you let go, and a whole Retina screen about 65 ms.
- Shots are converted to sRGB. A capture comes in the display's own colour space, and prompts and most of the web read a PNG's colours as sRGB whatever its profile says, so colours pasted from a wide-gamut display could look shifted.
- A window that closes between the click and its capture is copied from the frozen screen, as it was when you picked it, instead of failing with an error.
- The overlay is sharper and quieter. The selection's edge is one device pixel in your accent colour on any display, and what it outlines is exactly what is copied, down to the pixel. The size sits in a small capsule of material by the selection's corner with what the shot costs in tokens; near an edge or the notch it moves inside the selection or above it instead of off the screen. Hovering a window shows its size too.
- The loupe magnifies whole device pixels on a faint grid, rings the one under the pointer in black and white so it shows on any colour, and steps around the size rather than covering it.
- The hint along the bottom names the keys in the same material, shows only on the display with the pointer, and gets out of the way when the pointer comes near it.
- With Increase Contrast the dimming is stronger and the edge two device pixels; with Reduce Transparency the capsules are solid. VoiceOver reads the overlay's keys and the size of what is selected.
- The menu bar icon first appears beside the system's icons, where it can be seen, instead of at the far left, where Common Bar, the notch or an app's menus would hide it.
- Settings fits the screen it opens on and scrolls past that, instead of a fixed 720 pt cap, so it uses a tall display and still fits a 13-inch one. Under **Open at login** the General section now says “Starts when you log in.”, or what stands in the way, and the Common Tools section carries the family promise: free and open source, forever; nothing leaves your Mac.
- Settings follows the layout shared by every Common Tools app: the same window, width, grouped sections, and footnotes as Common Stats and Common Keys.

[Unreleased]: https://github.com/oddurs/common-tools/commits/main/apps/shot

### Fixed

- A shot pasted with ⌘V in Ghostty, and so in Claude Code or herdr running there, pasted nothing: the clipboard held only the image, and a terminal pastes text. It now also holds the saved PNG as a file, which Ghostty pastes as its path and Claude Code attaches as the image. Ctrl+V still pastes the image, and the Claude app and browsers take the file.
- Welcome answers clicks: it is now a plain titled window, built like Settings. It shows once for the whole Common Tools family, from whichever app opens first, and never on top of another app's; a later app shows it only for a permission it is missing.
- Settings no longer opens by itself on first launch. When Screen Recording is missing, Welcome, the shortcut's alert, and Settings offer **Reset and Ask Again**, which clears a switch left by an earlier copy (on in System Settings, but not for this one), and **Quit and Reopen**, since macOS applies the switch only after the app reopens.
