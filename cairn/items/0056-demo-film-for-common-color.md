---
id: 56
uid: 0205f245-b84b-4d90-ad1c-ed2d2d6d8054
title: Demo film for Common Color
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

Common Color is about to be released and its section on the landing page has no film to lead with.

## Proposal

A film in `site/src/lib/color/`, drawn to the app's `--snapshot` renders and ColorKit's own output: ⌃⇧⌘C and the loupe over a poster, the copy card, ⌘V into a stylesheet, then the panel's hero, recent picks, contrast and All Formats.

## Acceptance criteria

- [x] The film shows a pick, the copy card, a paste, and the panel, every string as ColorKit writes it
- [x] `demo.test.ts` pins what each caption promises
- [x] Videos and posters recorded in light and dark
