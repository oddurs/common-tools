---
id: 29
uid: 54e25ad9-d042-4378-8273-2573652f7814
title: Make Common Color a family member
type: chore
status: planned
milestone: color-0.1
created: 2026-10-17
updated: 2026-10-17
priority: p2
effort: m
area: color
---

## Purpose

Make Common Color a member of the family before any feature lands, so every later item builds on the shared contract instead of retrofitting it.

## Approach

Follow "Adding an app" in the root CLAUDE.md: an `apps.json` entry (with `PERMISSIONS`), `apps/color/` with a `ColorKit` library target and a thin app target, `CommonTool.all`, `scripts/make-icon color`, `ContractTests.swift` running `AppContract`, a Welcome driven by `WelcomeInfo`, Settings built from `SettingsWindowHost`, `.settingsForm()`, `OpenAtLoginToggle` and `CommonToolsSection()`, a CHANGELOG with `## [Unreleased]`, a README that leads with the family promise, and a page in `site/`. The status item uses `NSStatusBar.commonItem` so it first appears where it can be seen.

## Acceptance criteria

- [ ] `scripts/task check color` and `scripts/task smoke color` pass on a fresh clone.
- [ ] `AppContract` passes with no exemptions.
- [ ] Every other app's Settings lists Common Color in the Common Tools section.
- [ ] The site has a Common Color page that states the promise and the one permission it needs, or that it needs none.
