---
id: 82
uid: e526abc2-5e1a-41e7-80e9-69497061f5f3
title: Give Common Color's page three features with stills from its film
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

Common Color's page has no features yet: the template draws them from `site/src/lib/color/page.ts`, which doesn't exist.

## Proposal

Three features from the old copy, tightened, each beside a still from the film: the loupe (no permission), the copy card (your format), and the panel (picks and contrast).

## Acceptance criteria

- [x] `site/src/lib/color/page.ts` has three features, every claim true of `apps/color` on `main`
- [x] Stills rendered with `pnpm film stills color`, light and dark, and checked at full size and at 500 px
- [x] The page checked at 1280 and 390 in both appearances
- [x] `pnpm fmt && pnpm test && pnpm check && pnpm build` pass

## 2026-10-20

The panel is taller than a 16:10 crop at a readable size, so the third still shows the whole panel with the editor beside it; the AA and AAA rows are small at 500 px but legible. The card at the pick overlaps the browser's text column in the film itself, so 'Edition' is cut by the card in still 2.
