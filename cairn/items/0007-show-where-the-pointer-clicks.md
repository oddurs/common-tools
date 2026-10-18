---
id: 7
uid: fe91658a-4671-4737-840e-845a3583ec31
title: Show where the pointer clicks
type: feature
status: backlog
milestone: record-0.1
depends_on:
- 2
created: 2026-10-17
updated: 2026-10-17
priority: p1
effort: s
area: record
---

## Problem

In a recording of a UI, clicks are invisible, so viewers miss what happened.

## Proposal

An optional ring drawn at each click while recording, from a listen-only event tap if that needs no extra permission beyond Screen Recording; otherwise this item records why it was dropped.

## Acceptance criteria

- [ ] Clicks show as a ring in the recording when the setting is on, and never when it is off.
- [ ] No permission beyond Screen Recording is asked for, or the item records the finding and is dropped.
