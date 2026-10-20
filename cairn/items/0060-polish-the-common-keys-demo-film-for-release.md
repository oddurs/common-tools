---
id: 60
uid: 4ee45002-2e24-40a0-9819-6076ca0487b3
title: Polish the Common Keys demo film for release
type: feature
status: done
assignee: Oddur Sigurdsson
created: 2026-10-20
updated: 2026-10-20
closed_at: 2026-10-20
priority: p2
area: site
---

## Problem

The Common Keys film predates the stock menu bar: its flag close-up aims at the old extras position, and a few frames are off-model against the app as it ships (the returning app's layout, the bubble's metrics and shadow, a highlight the app never draws, windows that come forward with no click).

## Proposal

Keep the story, fix what is untrue, frame the menu bar's flag in every push-in so each layout switch is seen where it happens, add pointer clicks for app switches, tighten the pacing, and re-record light and dark.

## Acceptance criteria

- [x] Every caption and frame is true of `apps/keys` on main (layout restored per app, bubble drawn to `Bubble.swift`)
- [x] The menu bar flag is in view when each fix and each app switch changes the layout
- [x] `site/src/lib/keys/demo.test.ts` pins what the captions promise
- [x] Videos and posters re-recorded in light and dark

## 2026-10-20

Notes came back on U.S. in the old cut; the engine restores the layout last used in an app (recent within an hour), so it now comes back on Icelandic. The Korean caption waits for the twelve key caps to clear, since they run under it.
