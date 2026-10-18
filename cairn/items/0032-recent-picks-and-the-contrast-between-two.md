---
id: 32
uid: 4b9db0de-ab8e-4fdd-81b9-efc2f739a427
title: Recent picks and the contrast between two
type: feature
status: done
milestone: color-0.1
assignee: Oddur Sigurdsson
depends_on:
- 29
- 31
created: 2026-10-17
updated: 2026-10-18
closed_at: 2026-10-18
priority: p2
effort: s
area: color
---

## Problem

Picking twice and comparing is the most common follow-up, and contrast is the question behind it.

## Proposal

The last 12 picks as swatches in the menu; the last two show their WCAG 2 contrast ratio and pass/fail for normal and large text.

## Acceptance criteria

- [x] History persists across launches and can be cleared.
- [x] ColorKit tests match published WCAG ratios for known pairs.

## 2026-10-18

History: newest 12, a repeat moves to the front (so the newest two are always two colours), saved in the defaults under 'history' as Display P3 components to 6 places, loaded at launch; unreadable data is moved to 'history.unreadable', not overwritten. Clicking a swatch makes it current and copies it. Contrast: WCAG 2 (L1+0.05)/(L2+0.05) with L = Y of XYZ (equal to WCAG's coefficients for sRGB, defined beyond it); compared unrounded, shown truncated to 2 places so #777 on white (4.478) reads 4.47:1 and fails AA normal.

## 2026-10-18

Evidence: HistoryTests.persistsAcrossLaunches saves to a UserDefaults suite and loads it fresh, then clears and reloads empty; setsAsideAnUnreadableHistoryInsteadOfLosingIt. ContrastTests.matchesPublishedRatios: 21 (black/white), 4.48 (#777/white), 4.54 (#767676/white), 8.59 (#00f/white), 4.0 (#f00/white), 1.

## Result

The last 12 picks persist as swatches with Clear; the newest two show their WCAG 2 ratio with AA/AAA pass or fail for normal and large text.
