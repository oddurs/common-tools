---
id: 31
uid: 3a06195f-d049-4435-ad8e-35b2793a43db
title: Copy a colour in the format you write, converted correctly
type: feature
status: backlog
milestone: color-0.1
depends_on:
- 29
- 30
created: 2026-10-17
updated: 2026-10-17
priority: p2
effort: m
area: color
---

## Problem

A colour copied in the wrong space looks wrong in the browser and nobody knows why.

## Proposal

ColorKit formats: hex, rgb(), hsl(), oklch(), color(display-p3), SwiftUI Color, NSColor, with correct sRGB/P3 conversion and out-of-gamut values flagged. A default format in Settings; every format one click away in the menu.

## Acceptance criteria

- [ ] ColorKit tests match reference conversions for sRGB, P3 and out-of-gamut colours.
- [ ] Each format pastes as valid code in its language (CSS validates, Swift compiles).
