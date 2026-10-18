---
id: 8
uid: af2e2fb1-7efa-4672-8820-eda751e583cc
key: window-0.1
title: 'Common Window 0.1: window layouts from the keyboard'
type: milestone
status: backlog
created: 2026-10-17
updated: 2026-10-17
priority: p1
area: window
---

Put the frontmost window exactly where it belongs with one shortcut: a half, a third, a quarter, the middle, or the other display. Pressing again cycles through the sizes that make sense. Arrangements you save come back when you dock to the same displays.

## Problem

macOS 15's tiling covers halves and quarters by dragging or through a menu, with shortcuts that need the Globe key and no thirds, no cycling, no "move to the other display at the same place", and no memory of how your windows sat on your desk setup. People who live on the keyboard install a window manager; the good ones are large or paid.

## The experience

- **Layouts.** ⌃⌥ with arrows for halves, ⌃⌥ with U/I/J/K for quarters, ⌃⌥ with D/F/G for thirds, ⌃⌥↩ to fill, ⌃⌥C to centre, ⌃⌥⌫ to restore. All recordable; the defaults avoid the system's own.
- **Cycling.** Pressing a half again goes ½ → ⅓ → ⅔ of the screen on that side.
- **Other display.** ⌃⌥⌘ with arrows moves the window to the display in that direction, keeping its relative place and size.
- **Arrangements.** Save how the windows of chosen apps sit now; Common Window restores it when the same set of displays connects, and from its menu at any time.
- **Gaps.** Follows the system's "Tiled windows have margins" setting.

## In this milestone

The commands above, cycling, moving between displays, saved arrangements per display set, recordable shortcuts with conflict warnings, and an undo of the last move.

## Not in this milestone

Automatic tiling, drag-to-edge snapping (macOS does it), mouse gestures, scripting, and per-Space rules.

## Technical approach

Accessibility (`AXUIElement`, `kAXPositionAttribute` and `kAXSizeAttribute` on the focused window), with the geometry in WindowKit: visible frames per display, mixed scale, menu bar and Dock, minimum sizes, and windows that refuse a size. Full-screen windows are left alone. Display sets are identified by their stable IDs and arrangement. The shortcut recorder and conflict check reuse Common Command's `KeyCombo` and `Conflicts` through a package rather than a copy.

## Permissions and privacy

Accessibility, asked the first time a shortcut is used, never at launch, through Welcome's permission row with Reset and Ask Again. Nothing leaves the Mac; arrangements are stored as app bundle IDs and frames.

## Risks and open questions

- Apps that animate or fight resizing (Electron, some Java apps); measure and fall back to two passes.
- Stage Manager on: decide whether to act or step aside.

## Release gate

- Every item is done.
- The owner has used it for a week on a laptop plus external display, and every layout command lands within one pixel of its target on both.
