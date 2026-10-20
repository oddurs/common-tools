---
id: 55
uid: e8bd6306-c1b4-4769-bb85-573b178bfeac
title: Rebuild the Common Stats demo film's menu from the real app
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

The Common Stats demo film's menu was drawn from imagination: coloured tiles for section headers, no memory pressure pill or history, no CPU load and uptime, no mirrored network graph or disk scale. It is the first thing anyone sees of the app.

## Proposal

Redraw the menu in `site/src/lib/stats/` from the app's own view code and `--snapshot` renders, in both appearances; tighten the story (close up, click, live graphs, hover read-back, a busy spike, then the value, graph and gauge styles); check the status item's highlight and the menu's position against how macOS opens a status item menu; re-record.

## Acceptance criteria

- [x] The film's menu matches `CommonStats --snapshot` in layout, symbols, copy and colours, light and dark.
- [x] The story runs 15 to 24 seconds with three or four true captions, a poster and a seamless loop.
- [x] `stats/demo.test.ts` pins what each caption promises.
- [x] Videos and posters re-recorded; `pnpm fmt`, `pnpm test` and `pnpm check` pass.

## 2026-10-20

The menu shows a card for each metric in the menu bar (StatusItemController.menuNeedsUpdate), so the film's bar shows all seven to show the full menu. Ring colours follow the default accent palette; Storage is orange because it is 91% full (MetricTile.ringInk). Found while rendering: on an M5 Pro the device tree tags cores P and M, which CPUTopology doesn't know, so the CPU card shows 15 ungrouped bars with no cluster captions.
