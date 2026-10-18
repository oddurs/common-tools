---
id: 2
uid: a5d2a267-8355-448d-82a8-66fe2fa15d7b
title: Make Common Record a family member
type: chore
status: planned
milestone: record-0.1
created: 2026-10-17
updated: 2026-10-17
priority: p1
effort: m
area: record
---

## Purpose

Make Common Record a member of the family before any feature lands, so every later item builds on the shared contract instead of retrofitting it.

## Approach

Follow "Adding an app" in the root CLAUDE.md: an `apps.json` entry (with `PERMISSIONS`), `apps/record/` with a `RecordKit` library target and a thin app target, `CommonTool.all`, `scripts/make-icon record`, `ContractTests.swift` running `AppContract`, a Welcome driven by `WelcomeInfo`, Settings built from `SettingsWindowHost`, `.settingsForm()`, `OpenAtLoginToggle` and `CommonToolsSection()`, a CHANGELOG with `## [Unreleased]`, a README that leads with the family promise, and a page in `site/`. The status item uses `NSStatusBar.commonItem` so it first appears where it can be seen.

## Acceptance criteria

- [ ] `scripts/task check record` and `scripts/task smoke record` pass on a fresh clone.
- [ ] `AppContract` passes with no exemptions.
- [ ] Every other app's Settings lists Common Record in the Common Tools section.
- [ ] The site has a Common Record page that states the promise and the one permission it needs, or that it needs none.
