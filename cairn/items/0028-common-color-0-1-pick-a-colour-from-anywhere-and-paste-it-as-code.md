---
id: 28
uid: 5c4b95c7-5577-4071-bd37-f965c561acd1
key: color-0.1
title: 'Common Color 0.1: pick a colour from anywhere and paste it as code'
type: milestone
status: backlog
created: 2026-10-17
updated: 2026-10-17
priority: p2
area: color
---

Press a shortcut, click any pixel on any screen, and the colour is on the clipboard in the format you write: hex, CSS, SwiftUI or AppKit, converted correctly from the display's colour space. Recent picks wait in the menu, and two picks show their contrast.

## Problem

macOS's Digital Color Meter shows values but copies them awkwardly and in the wrong space for the web; the system colour panel's eyedropper is buried. Designers and developers want a pixel's colour as a line of code, correct for where it will be used.

## The experience

- **Pick.** ⌃⇧⌘C by default: the system's magnifying loupe appears; click to pick, Escape to cancel.
- **Copy.** The colour is copied in the default format (hex by default); the menu lists the same colour in every format for a one-click copy.
- **History.** The last 12 picks as swatches in the menu; click to copy again.
- **Contrast.** Pick two and the menu shows their WCAG contrast ratio with pass/fail for text sizes.

## In this milestone

Picking, formats (hex, `rgb()`, `hsl()`, `oklch()`, `color(display-p3 …)`, SwiftUI `Color`, `NSColor`), history, and contrast for the last two picks.

## Not in this milestone

Palettes and collections, colour naming, image sampling, and sync.

## Technical approach

`NSColorSampler`, which shows the system loupe and returns the picked colour without Screen Recording, so the app needs no permission at all. Conversions in ColorKit through ColorSync-correct maths: sRGB and Display P3 with the right transfer functions, out-of-gamut values flagged rather than clipped silently, and tests against reference values.

## Permissions and privacy

None. Nothing leaves the Mac.

## Risks and open questions

- Whether `NSColorSampler` returns the colour in the display's space on every Mac; verify on a P3 and an sRGB display.

## Release gate

- Every item is done.
- Picks of a known P3 swatch on the owner's display match its published values in every format, within rounding.
