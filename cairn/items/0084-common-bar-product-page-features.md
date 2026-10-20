---
id: 84
uid: 45922130-48b3-402e-a8fa-0b27dd4cb844
title: Common Bar product page features
type: feature
status: done
assignee: Oddur Sigurdsson
created: 2026-10-20
updated: 2026-10-20
closed_at: 2026-10-20
priority: p2
area: site
part_of:
- 78
---

## Problem

Common Bar's page has its film but no features: the template draws three features beside stills from the film, and Bar has no `page.ts` yet.

## Proposal

Write `site/src/lib/bar/page.ts` with three features, each true of `apps/bar/` on `main`, each beside a settled moment of the film, and render the stills with `pnpm film stills bar`.

## Acceptance criteria

- [x] `site/src/lib/bar/page.ts` has three features, every claim true of `apps/bar/` on `main`
- [x] Stills in `site/static/bar/features/`, light and dark, crisp at 500 px
- [x] `pnpm fmt && pnpm test && pnpm check && pnpm build` pass

## 2026-10-20

Features at poster (grouped dropdown), 8300 ms ("cl" typed, camera nearly settled on the handoff shot) and 9800 ms (Clipboard's menu open beside More). The handoff shot's frame cuts the clock, so feature 3's crop stops short of it and can't share feature 2's.
