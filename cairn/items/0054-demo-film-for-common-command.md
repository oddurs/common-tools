---
id: 54
uid: 1f5623a8-4166-4924-a40d-d718af6c8e06
title: Demo film for Common Command
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

Common Command leads the landing page, and it has no film: the first thing a visitor sees of the family is a still.

## Proposal

A 15 to 24 second film made with `src/lib/film/`, drawn to the real panel's `--snapshot` renders: ⌥Space over a working window, "saf" finds Safari, "dark" finds the Appearance pane, a conversion that Return copies, then a pull back to the closing card.

## Acceptance criteria

- [x] `site/src/lib/command/` has `demo.ts`, `Demo.svelte` and `demo.test.ts`, and the shared film tests pass
- [x] Every row, symbol and caption matches the app's code on `main` and its snapshot renders, light and dark
- [x] `site/static/command/` has the recorded films and posters in both appearances

## 2026-10-20

Results come from CommandKit's Results.compose run over a stock-Mac catalog (scratch harness compiled with the CommandKit sources), not this Mac's apps; icons rendered with NSWorkspace in the RegularLight and RegularDark icon styles. Found while filming: Safari's row icon carries an alias badge (Catalogs.swift keeps /Applications/Safari.app, a symlink into the cryptex), and plain "dark" ranks Accessibility's Dark Noise above Appearance.
