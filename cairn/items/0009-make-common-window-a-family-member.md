---
id: 9
uid: a63f9045-8557-4414-8076-e631efb6594f
title: Make Common Window a family member
type: chore
status: planned
milestone: window-0.1
created: 2026-10-17
updated: 2026-10-17
priority: p1
effort: m
area: window
---

## Purpose

Make Common Window a member of the family before any feature lands, so every later item builds on the shared contract instead of retrofitting it.

## Approach

Follow "Adding an app" in the root CLAUDE.md: an `apps.json` entry (with `PERMISSIONS`), `apps/window/` with a `WindowKit` library target and a thin app target, `CommonTool.all`, `scripts/make-icon window`, `ContractTests.swift` running `AppContract`, a Welcome driven by `WelcomeInfo`, Settings built from `SettingsWindowHost`, `.settingsForm()`, `OpenAtLoginToggle` and `CommonToolsSection()`, a CHANGELOG with `## [Unreleased]`, a README that leads with the family promise, and a page in `site/`. The status item uses `NSStatusBar.commonItem` so it first appears where it can be seen.

## Acceptance criteria

- [ ] `scripts/task check window` and `scripts/task smoke window` pass on a fresh clone.
- [ ] `AppContract` passes with no exemptions.
- [ ] Every other app's Settings lists Common Window in the Common Tools section.
- [ ] The site has a Common Window page that states the promise and the one permission it needs, or that it needs none.
