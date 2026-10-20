---
id: 79
uid: fce459ff-0d60-4b6c-a3cf-76226b4eae88
title: Common Stats product page features
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

Common Stats' page has no features under its film since every app's page moved to one template.

## Proposal

Three features in `site/src/lib/stats/page.ts`, each a still from the film: the menu, the CPU graph's hover read-back, and the bar shown as graphs.

## Acceptance criteria

- [x] Three features, each claim true of `apps/stats/` on `main`
- [x] Stills rendered with `pnpm film stills stats`, checked light and dark
- [x] `pnpm fmt`, `pnpm test`, `pnpm check` and `pnpm build` pass

## 2026-10-20

Picked Native (whole menu, 4500), Graphs that tell the truth (poster) and Yours to arrange (graphs mark). Accurate, Light and Private aren't visible in the film. The bar-only still is mostly wallpaper: the film's closest shot of the bar is a 45-pixel strip.
