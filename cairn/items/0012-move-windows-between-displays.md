---
id: 12
uid: 820954cf-3444-4afb-8096-7f447b1ac376
title: Move windows between displays
type: feature
status: backlog
milestone: window-0.1
depends_on:
- 9
- 10
created: 2026-10-17
updated: 2026-10-17
priority: p1
effort: m
area: window
---

## Problem

With a laptop and a monitor, the most common move is 'this window, over there, same place'.

## Proposal

⌃⌥⌘ with an arrow moves the window to the nearest display in that direction, scaling its frame proportionally to the target's visible frame.

## Acceptance criteria

- [ ] Tests cover left/right/up/down neighbours and a direction with no display (no move, no error).
- [ ] A half on one display arrives as the same half on the other.
