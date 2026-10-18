---
id: 27
uid: 351d4f91-06e4-4188-8c0f-0025d7419f63
title: Show what else is keeping the Mac awake
type: feature
status: backlog
milestone: awake-0.1
depends_on:
- 23
created: 2026-10-17
updated: 2026-10-17
priority: p2
effort: s
area: awake
---

## Problem

When the Mac will not sleep, the cause is usually another app's assertion, and only `pmset` shows it.

## Proposal

A section of the menu lists other processes' active assertions, with app name and reason, refreshed when the menu opens.

## Acceptance criteria

- [ ] A `caffeinate` started in a terminal appears in the list.
- [ ] The list is empty when nothing else holds an assertion.
