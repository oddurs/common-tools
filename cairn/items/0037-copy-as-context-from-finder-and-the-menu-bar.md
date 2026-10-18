---
id: 37
uid: 1fc1041b-9c54-438a-989f-44dbb799affc
title: Copy as Context from Finder and the menu bar
type: feature
status: backlog
milestone: context-0.1
depends_on:
- 34
- 35
- 36
created: 2026-10-17
updated: 2026-10-17
priority: p2
effort: m
area: context
---

## Problem

The value is in not leaving Finder.

## Proposal

An `NSServices` item and a Quick Action for files and folders, and drop onto the status item; each opens the preview panel with checkboxes, sizes, tokens and the total; Return copies.

## Acceptance criteria

- [ ] Services ▸ Copy as Context appears for a Finder selection with no permission prompt.
- [ ] Unticking a file updates the total immediately.
- [ ] The panel is fully usable from the keyboard.
