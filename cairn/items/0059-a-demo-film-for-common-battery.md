---
id: 59
uid: 25e4e62c-bb73-4f42-859b-ce83e3af5f63
title: A demo film for Common Battery
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

Common Battery is about to be released and its section on the landing page needs a film, made with `site/src/lib/film/` like the other apps', true to the app's code on `main`.

## Proposal

A 15–24 s film in `site/src/lib/battery/`: the menu bar item up close while charging, the alert at the level the user chose, the menu with its 12-hour chart and details, and the switch to time remaining when the adapter comes out. The item is drawn to `BarRenderer`'s metrics and the panel to `PanelView`'s.

## Acceptance criteria

- [x] `site/src/lib/battery/demo.ts` and `Demo.svelte` draw the film, with the item at `BarRenderer`'s metrics
- [x] `demo.test.ts` pins what each caption promises
- [x] Light and dark videos and posters recorded into `site/static/battery/`
- [x] `pnpm fmt`, `pnpm test` and `pnpm check` pass

## 2026-10-20

The system battery slot is hidden by CSS in battery/Demo.svelte, since mac/Screen has no prop for it; a systemItems prop on Screen would be cleaner.

## 2026-10-20

Replaced the CSS override with a hideSystem prop on mac/Screen.svelte, passed through film/Film.svelte; the default draws every system item as before.
