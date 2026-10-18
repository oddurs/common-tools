---
id: 16
uid: 77393db7-f2a6-4891-8192-f6def8a9b0ec
title: Make Common Sound a family member
type: chore
status: planned
milestone: sound-0.1
created: 2026-10-17
updated: 2026-10-17
priority: p1
effort: m
area: sound
---

## Purpose

Make Common Sound a member of the family before any feature lands, so every later item builds on the shared contract instead of retrofitting it.

## Approach

Follow "Adding an app" in the root CLAUDE.md: an `apps.json` entry (with `PERMISSIONS`), `apps/sound/` with a `SoundKit` library target and a thin app target, `CommonTool.all`, `scripts/make-icon sound`, `ContractTests.swift` running `AppContract`, a Welcome driven by `WelcomeInfo`, Settings built from `SettingsWindowHost`, `.settingsForm()`, `OpenAtLoginToggle` and `CommonToolsSection()`, a CHANGELOG with `## [Unreleased]`, a README that leads with the family promise, and a page in `site/`. The status item uses `NSStatusBar.commonItem` so it first appears where it can be seen.

## Acceptance criteria

- [ ] `scripts/task check sound` and `scripts/task smoke sound` pass on a fresh clone.
- [ ] `AppContract` passes with no exemptions.
- [ ] Every other app's Settings lists Common Sound in the Common Tools section.
- [ ] The site has a Common Sound page that states the promise and the one permission it needs, or that it needs none.
