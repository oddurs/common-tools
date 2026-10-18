---
id: 14
uid: ee65b5fe-9468-4ee2-80aa-bc03bb6b6454
title: Save and restore arrangements per display set
type: feature
status: backlog
milestone: window-0.1
depends_on:
- 9
- 10
created: 2026-10-17
updated: 2026-10-17
priority: p1
effort: l
area: window
---

## Problem

Docking at a desk means putting the same windows back in the same places every morning.

## Proposal

Save an arrangement of chosen apps' windows; it is tied to the current set of displays and restored automatically when that set connects, or from the menu. Missing apps and windows are skipped.

## Acceptance criteria

- [ ] Disconnecting and reconnecting the external display restores a saved arrangement.
- [ ] An arrangement mentioning an app that is not running restores the rest and says what it skipped.
- [ ] Display sets are recognised by stable identity, not by order.
