---
id: 64
uid: a6905ce9-67c5-400a-998c-99ff6730123b
title: A demo film of Common Bar's new folder dropdown
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

Common Bar's film on the site shows the old NSMenu dropdown. The folder now opens a panel (#85): grouped rows, type-to-filter, a progress mark on the chosen row, and a handoff to the icon's own menu beside the folder. The film is the first thing anyone sees of the app.

## Proposal

Rebuild `site/src/lib/bar/` on the new panel, drawn to the metrics of `FolderPanel` and `MenuPanelSurface` and checked against `CommonBar --render`: a crowded menu bar tidies into More, More opens, typing narrows the list, Return opens a third-party icon whose own menu appears beside the folder, and it goes back.

## Acceptance criteria

- [x] The panel matches the app's renders in light and dark: width, row and header metrics, groups, filter row, footer.
- [x] Every caption is true of the code on main, and `bar/demo.test.ts` pins what each promises.
- [x] The film is re-recorded, light and dark, with both posters checked at landing-page size.
- [x] `pnpm fmt`, `pnpm test` and `pnpm check` pass.
