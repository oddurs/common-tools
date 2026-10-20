---
id: 80
uid: 5c01e41e-3fa2-406d-8778-519c1701340c
title: Common Keys' product page features
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

Common Keys' page has the shared template's hero and film, but no features: the six blocks of the old page didn't come over.

## Proposal

Three features in `site/src/lib/keys/page.ts`, each a title, a sentence and a still from the film, rendered into `site/static/keys/features/` by `pnpm film stills keys`.

## Acceptance criteria

- [x] `site/src/lib/keys/page.ts` names three features, each true of `apps/keys/` on `main`
- [x] Each still is rendered light and dark, settled and legible at page size
- [x] `pnpm fmt && pnpm test && pnpm check && pnpm build` pass in `site/`

## 2026-10-20

Stills at 5250 ms (Notes, cropped 960x600), 9300 ms (Chat, cropped to its window), 17200 ms (whole frame, Chat clicked forward, flag on Russian). The film's ⌘Z had been picking up the site's global kbd key cap since #112, a white box in dark; it is a plain span again, as in Bubble.swift.
