# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- A global shortcut (⇧⌘2 by default, recordable in Settings) that freezes every display and shows an overlay over them.
- Drag for an area, with its size in pixels and a loupe; click for the window under the pointer, captured on its own; Return for the whole screen; Escape, right-click, or the shortcut again to cancel. A hint along the bottom names the keys.
- Hold ⌥ to copy the text in an area, window, or screen instead of the image, read on the device with Vision. Monospaced text keeps its indentation, and `name. member` is read back as `name.member`.
- Shots go to the clipboard as PNG, sized for prompts by default: the long edge at most 1568 px, which keeps a full screen near 2,100 Claude tokens. Full resolution is a setting.
- A preview of each shot in the screen's corner, with its size and estimated token cost, and a reminder to paste with Ctrl+V when the shot was taken from a terminal. Hover keeps it, dragging the thumbnail drops the PNG as a file, and a click dismisses it.
- Recent shots as thumbnails in the menu bar menu, the newest 6 at the top and the rest in a submenu; click one to copy it again. Keeps the last 10 by default, from none to 100.
- Settings: shortcut, Screen Recording status, image size, preview, history depth, menu bar item, and open at login.

[Unreleased]: https://github.com/oddurs/common-tools/commits/main/apps/shot
