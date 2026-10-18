---
id: 10
uid: 98a69c6f-c6c7-49e3-8755-fd80ae4ea79f
title: Move and size the focused window precisely across displays
type: feature
status: backlog
milestone: window-0.1
depends_on:
- 9
created: 2026-10-17
updated: 2026-10-17
priority: p1
effort: l
area: window
---

## Problem

Everything else rests on putting a window at an exact frame on any display, which Accessibility makes awkward: coordinates are top-left global, sizes are clamped by apps, and some apps resize asynchronously.

## Proposal

A WindowKit geometry core (visible frame per display, mixed scale, menu bar and Dock, gaps) plus a thin AX mover that sets size, position, then size again when an app clamps it, and reads back the result.

## Acceptance criteria

- [ ] WindowKit tests cover halves, thirds and quarters on recorded multi-display geometries, including a display above another and mixed scale.
- [ ] On the owner's Mac, Safari, Finder, Terminal and one Electron app each land within one pixel of the target.
- [ ] A window with a minimum size larger than the target is placed at its minimum, aligned to the target's edge.
