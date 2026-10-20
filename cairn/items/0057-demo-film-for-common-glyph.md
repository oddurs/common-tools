---
id: 57
uid: 78166688-0ded-4469-a029-fe4fe1108423
title: Demo film for Common Glyph
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

Common Glyph is about to be released and its section on the landing page has no film, so a visitor can't see what the app does before downloading it.

## Proposal

A 15 to 24 second film in `site/src/lib/glyph/`, drawn from the app's SwiftUI views (`GlyphEditor`, `CropEditor`, `Dropdown.swift`, `MenuBarPreview`) since the app has no snapshot command: a photo dropped into the editor, its subject lifted and styled, landing in the menu bar beside the clock, then an emoji and a word glyph, then a glyph's card.

## Acceptance criteria

- [x] `site/src/lib/glyph/` has `demo.ts`, `Demo.svelte` and `demo.test.ts`, and every caption is true of the app's code on `main`
- [x] The film passes the shared film tests: loop, poster, camera inside the screen, closing card
- [x] Light and dark recordings and posters are committed under `site/static/glyph/`

## 2026-10-20

Common Glyph has no snapshot command, so the film is drawn from the SwiftUI code and measured against offscreen renders of GlyphEditor, SettingsView, MenuBarPreview and GlyphCard, compiled into a scratch harness outside the repo. Found while measuring: a text glyph is trimmed to its ink and drawn 85% of the bar tall, so a lowercase word like 'meow' comes out 89 x 19 points, far larger than the clock; the film adds a kaomoji instead of a word.
