---
id: 81
uid: 050120ae-2de4-4511-8bfc-793f7c5311c5
title: Common Shot product page features
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
effort: s
---

## Problem

Common Shot's page has its hero and film but none of the three features the shared template sets beside stills from the film.

## Proposal

Write `site/src/lib/shot/page.ts` from the old copy, choosing three features the film shows truthfully, and render their stills with `pnpm film stills shot`.

## Acceptance criteria

- [x] `site/src/lib/shot/page.ts` has three features, each true of `apps/shot/` on `main`
- [x] Each feature's still shows what it describes, settled, in light and dark
- [x] The page reads well at 1280 and 390 in both appearances
- [x] `pnpm fmt`, `pnpm test`, `pnpm check` and `pnpm build` pass

## 2026-10-20

Option for text isn't in the film, so the page shows the drag (7000 ms), the preview with its token cost (9800 ms) and the history panel (15600 ms). In the dark film the panel's ⇧⌘2 key cap draws as a blank white capsule: Panel.svelte's <kbd> takes app.css's global kbd style, which follows the site's appearance rather than the film's dark. It shows in still 3-dark and in demo-dark.mp4; worth its own fix in the film.
