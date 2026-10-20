---
id: 58
uid: 68b88945-014b-4d23-8f9f-28d14f538902
title: Demo film for Common Shot
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

Common Shot is about to be released and its section on the landing page has no film to lead with.

## Proposal

A 15–24 s film in `site/src/lib/shot/`: ⇧⌘2 freezes the screen, a hovered window lights up, a drag over code shows the size pill and loupe, letting go flies the shot into the preview, ⌘V puts it in a chat message, and the menu bar panel shows the history. Every piece drawn to the app's `--render` output.

## Acceptance criteria

- [x] `site/src/lib/shot/demo.ts`, `Demo.svelte` and `demo.test.ts`, with captions pinned by the test
- [x] Overlay, preview and history panel match `CommonShot --render` in light and dark
- [x] `pnpm record shot` videos and posters committed
- [x] `pnpm fmt`, `pnpm test` and `pnpm check` pass

## 2026-10-20

The loupe draws the frozen screen from a pixel model in scene.ts (flat colours, text as strokes per character), since a DOM clone can't be pixelated. Code and Panel keep their colours in Demo.svelte's style block, because tokens.test.ts exempts only *Demo.svelte from the colour-literal rule.
