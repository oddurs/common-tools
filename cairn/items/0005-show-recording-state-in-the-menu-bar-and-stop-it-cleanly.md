---
id: 5
uid: b6f30d45-1096-4a8e-9222-bd0dcd0b0d78
title: Show recording state in the menu bar and stop it cleanly
type: feature
status: backlog
milestone: record-0.1
depends_on:
- 2
created: 2026-10-17
updated: 2026-10-17
priority: p1
effort: m
area: record
---

## Problem

Without a clear, always-visible state, a forgotten recording runs until the disk fills.

## Proposal

While recording, the status item becomes a red dot with elapsed time; clicking it stops. The shortcut and Escape stop too. A length cap (60 s default, up to 10 min) stops with a notice. Discard in the menu throws the recording away.

## Acceptance criteria

- [ ] Every stop path produces exactly one file, or none for Discard.
- [ ] A recording at the cap stops on its own and says why.
- [ ] VoiceOver reads the recording state and elapsed time.
