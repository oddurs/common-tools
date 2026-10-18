---
id: 30
uid: e586fc72-a215-4b38-b839-2e44e9afade9
title: Pick a pixel with the system sampler
type: feature
status: backlog
milestone: color-0.1
depends_on:
- 29
created: 2026-10-17
updated: 2026-10-17
priority: p2
effort: s
area: color
---

## Problem

Picking must be instant and need no permission.

## Proposal

`NSColorSampler` from a global shortcut and from the menu; the result goes to ColorKit with its colour space.

## Acceptance criteria

- [ ] Picking works with no permission granted to the app.
- [ ] Escape cancels and leaves the clipboard untouched.
