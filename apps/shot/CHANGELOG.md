# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Precision while you aim: the arrow keys move the pointer by one device pixel (ten with ⇧), and during a drag they move the corner you're dragging; hold Space during a drag to move the whole selection, as in macOS; and a dragged corner settles on the edge of a window, or of the screen, when it comes within 5 points of one. An edge hidden behind another window doesn't count, and the arrow keys never snap.
- A Welcome window on first launch: what Common Shot does, the Screen Recording permission it needs with a live check and a button to System Settings, Open at login, and the Common Tools family.
- An optional update check in Settings › General, off by default. When on, it asks GitHub for the latest release once a day and sends nothing about you or your Mac; a newer version shows as a link under the toggle.
- A global shortcut (⇧⌘2 by default, recordable in Settings) that freezes every display and shows an overlay over them.
- Drag for an area, with its size in pixels and a loupe; click for the window under the pointer, captured on its own; Return for the whole screen; Escape, right-click, or the shortcut again to cancel. A hint along the bottom names the keys.
- Hold ⌥ to copy the text in an area, window, or screen instead of the image, read on the device with Vision. Monospaced text keeps its indentation, and `name. member` is read back as `name.member`.
- Shots go to the clipboard as PNG, sized for prompts by default: the long edge at most 1568 px, which keeps a full screen near 2,100 Claude tokens. Full resolution is a setting.
- A preview of each shot in the screen's corner, with its size and estimated token cost, and a reminder to paste with Ctrl+V when the shot was taken from a terminal. Hover keeps it, dragging the thumbnail drops the PNG as a file, and a click dismisses it.
- Recent shots as thumbnails in the menu bar menu, the newest 6 at the top and the rest in a submenu; click one to copy it again. Keeps the last 10 by default, from none to 100.
- Settings: shortcut, Screen Recording status, image size, preview, history depth, menu bar item, and open at login.

### Changed

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
