---
id: 39
uid: ab29ad2f-6093-47a8-96fb-3f6c73b4db80
title: Make Common Agents a family member
type: chore
status: planned
milestone: agents-0.1
created: 2026-10-17
updated: 2026-10-17
priority: p2
effort: m
area: agents
---

## Purpose

Make Common Agents a member of the family before any feature lands, so every later item builds on the shared contract instead of retrofitting it.

## Approach

Follow "Adding an app" in the root CLAUDE.md: an `apps.json` entry (with `PERMISSIONS`), `apps/agents/` with a `AgentsKit` library target and a thin app target, `CommonTool.all`, `scripts/make-icon agents`, `ContractTests.swift` running `AppContract`, a Welcome driven by `WelcomeInfo`, Settings built from `SettingsWindowHost`, `.settingsForm()`, `OpenAtLoginToggle` and `CommonToolsSection()`, a CHANGELOG with `## [Unreleased]`, a README that leads with the family promise, and a page in `site/`. The status item uses `NSStatusBar.commonItem` so it first appears where it can be seen.

## Acceptance criteria

- [ ] `scripts/task check agents` and `scripts/task smoke agents` pass on a fresh clone.
- [ ] `AppContract` passes with no exemptions.
- [ ] Every other app's Settings lists Common Agents in the Common Tools section.
- [ ] The site has a Common Agents page that states the promise and the one permission it needs, or that it needs none.
