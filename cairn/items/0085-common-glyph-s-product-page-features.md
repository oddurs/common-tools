---
id: 85
uid: 70560700-ada3-4c74-abc8-e3689a07c9a2
title: Common Glyph's product page features
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

Common Glyph's page has the template's hero and film but no features: the three bands of headline, sentence and still from the film that Command's page has.

## Proposal

Write `site/src/lib/glyph/page.ts` with three features drawn from the old copy, each true of `apps/glyph/` on `main`, and render their stills from the film with `pnpm film stills glyph`.

## Acceptance criteria

- [x] `site/src/lib/glyph/page.ts` names three features, each a 2–4 word title and under 30 words of text, every claim true of `apps/glyph/`
- [x] Each feature shows a settled moment of the film, cropped 16:10, with light and dark stills in `site/static/glyph/features/`
- [x] The page reads well at 1280 and 390 in light and dark
- [x] `pnpm fmt && pnpm test && pnpm check && pnpm build` pass in `site/`

## 2026-10-20

Features: 'Anything you like.' at 14500 ms (Settings with three glyphs, light and dark previews), 'Made to fit.' at 6600 ms (editor's Look section: Silhouette, Lift subject), 'A menu for each.' at the poster (Mochi's menu). The film's own <kbd> picked up the site's global key cap from #112 and drew white-on-white shortcuts in dark; glyph/Demo.svelte now resets it. The pointer rests on Silhouette from its click until the camera leaves, so still 2 shows it.
