---
id: 83
uid: 9994b12b-1ec7-4527-aa9d-57614bc918e1
title: Common Battery's page shows three features from its film
type: feature
status: done
assignee: Oddur Sigurdsson
created: 2026-10-20
updated: 2026-10-20
closed_at: 2026-10-20
priority: p2
area: site
effort: s
part_of:
- 78
---

## Problem

Common Battery's page has its film but no features: the template draws three, each a headline and a sentence beside a still from the film, and `site/src/lib/battery/page.ts` doesn't exist yet.

## Proposal

Three features from the old copy, tightened, each on a different moment of the film: the item close up while charging, the 80% notification, and the menu after the unplug, showing the time left.

## Acceptance criteria

- [x] `site/src/lib/battery/page.ts` has three features, every claim true of `apps/battery/` on `main`
- [x] Each still is rendered by `pnpm film stills battery`, light and dark, crisp and on topic
- [x] The page reads well at 1280 and 390, light and dark
- [x] `pnpm fmt`, `pnpm test`, `pnpm check` and `pnpm build` pass

## 2026-10-20

Dropped 'A time left that learns.' as its own feature: no film moment shows learning, and the unplug happens with the menu open, so its still would repeat the menu's. The learning claim moved into the menu feature, whose still (13 s, after the unplug) shows '6:18 remaining'.
