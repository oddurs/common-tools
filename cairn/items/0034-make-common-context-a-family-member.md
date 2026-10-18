---
id: 34
uid: af156eba-ea9c-408a-a0de-9af35a928663
title: Make Common Context a family member
type: chore
status: planned
milestone: context-0.1
created: 2026-10-17
updated: 2026-10-17
priority: p2
effort: m
area: context
---

## Purpose

Make Common Context a member of the family before any feature lands, so every later item builds on the shared contract instead of retrofitting it.

## Approach

Follow "Adding an app" in the root CLAUDE.md: an `apps.json` entry (with `PERMISSIONS`), `apps/context/` with a `ContextKit` library target and a thin app target, `CommonTool.all`, `scripts/make-icon context`, `ContractTests.swift` running `AppContract`, a Welcome driven by `WelcomeInfo`, Settings built from `SettingsWindowHost`, `.settingsForm()`, `OpenAtLoginToggle` and `CommonToolsSection()`, a CHANGELOG with `## [Unreleased]`, a README that leads with the family promise, and a page in `site/`. The status item uses `NSStatusBar.commonItem` so it first appears where it can be seen.

## Acceptance criteria

- [ ] `scripts/task check context` and `scripts/task smoke context` pass on a fresh clone.
- [ ] `AppContract` passes with no exemptions.
- [ ] Every other app's Settings lists Common Context in the Common Tools section.
- [ ] The site has a Common Context page that states the promise and the one permission it needs, or that it needs none.
