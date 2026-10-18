---
id: 29
uid: 54e25ad9-d042-4378-8273-2573652f7814
title: Make Common Color a family member
type: chore
status: done
milestone: color-0.1
assignee: Oddur Sigurdsson
created: 2026-10-17
updated: 2026-10-17
closed_at: 2026-10-17
priority: p2
effort: m
area: color
---

## Purpose

Make Common Color a member of the family before any feature lands, so every later item builds on the shared contract instead of retrofitting it.

## Approach

Follow "Adding an app" in the root CLAUDE.md: an `apps.json` entry (with `PERMISSIONS`), `apps/color/` with a `ColorKit` library target and a thin app target, `CommonTool.all`, `scripts/make-icon color`, `ContractTests.swift` running `AppContract`, a Welcome driven by `WelcomeInfo`, Settings built from `SettingsWindowHost`, `.settingsForm()`, `OpenAtLoginToggle` and `CommonToolsSection()`, a CHANGELOG with `## [Unreleased]`, a README that leads with the family promise, and a page in `site/`. The status item uses `NSStatusBar.commonItem` so it first appears where it can be seen.

## Acceptance criteria

- [x] `scripts/task check color` and `scripts/task smoke color` pass on a fresh clone.
- [x] `AppContract` passes with no exemptions.
- [x] Every other app's Settings lists Common Color in the Common Tools section.
- [x] The site has a Common Color page that states the promise and the one permission it needs, or that it needs none.

## 2026-10-17

Identity: slug color, Common Color, com.oddurs.commoncolor, target CommonColor, library ColorKit, PERMISSIONS empty; status item autosave name CommonColor, seeded by NSStatusBar.commonItem. ColorKit starts with the colour-space foundation (sRGB and Display P3, matrices derived from published primaries and D65, equal to CSS Color 4's rationals to 1e-12; checked against ColorSync on a 7x7x7 grid within 0.0005, the size of ColorSync's quantised-profile error) so the scaffold's library target has real content; formats, OKLab, contrast and history arrive with 30-32.

## 2026-10-17

Site: Upcoming gained an optional 'access' line, rendered on the in-development page, so the Color page says it needs no permission. Root README, issue templates and SECURITY.md list the app. Other apps' CLAUDE.md files still mention a CommonTools.swift that no longer exists; left alone (not this area).

## 2026-10-17

Evidence: scripts/task check color kit site passed in a fresh worktree (ContractTests, ConversionTests, all CommonKit suites, site lint/test/build); scripts/task smoke color stayed up 5 s. AppContract(slug: color).violations() == [] with no rule change. CommonToolsSection draws CommonTool.all, now ending with color, so every app's Settings lists it. site/build/color/index.html carries the family promise and 'It needs no permission: ...'.

## Result

Common Color is a family member: apps.json, CommonTool.all, apps/color with ColorKit and a thin app, icon, contract test, Welcome, Settings, CHANGELOG, README and an in-development site page that says it needs no permission.
