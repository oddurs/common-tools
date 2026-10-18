---
id: 23
uid: 598bd762-0f2c-4f61-83b3-f23606ceb5ac
title: Make Common Awake a family member
type: chore
status: planned
milestone: awake-0.1
created: 2026-10-17
updated: 2026-10-17
priority: p2
effort: m
area: awake
---

## Purpose

Make Common Awake a member of the family before any feature lands, so every later item builds on the shared contract instead of retrofitting it.

## Approach

Follow "Adding an app" in the root CLAUDE.md: an `apps.json` entry (with `PERMISSIONS`), `apps/awake/` with a `AwakeKit` library target and a thin app target, `CommonTool.all`, `scripts/make-icon awake`, `ContractTests.swift` running `AppContract`, a Welcome driven by `WelcomeInfo`, Settings built from `SettingsWindowHost`, `.settingsForm()`, `OpenAtLoginToggle` and `CommonToolsSection()`, a CHANGELOG with `## [Unreleased]`, a README that leads with the family promise, and a page in `site/`. The status item uses `NSStatusBar.commonItem` so it first appears where it can be seen.

## Acceptance criteria

- [ ] `scripts/task check awake` and `scripts/task smoke awake` pass on a fresh clone.
- [ ] `AppContract` passes with no exemptions.
- [ ] Every other app's Settings lists Common Awake in the Common Tools section.
- [ ] The site has a Common Awake page that states the promise and the one permission it needs, or that it needs none.
