---
id: 19
uid: 31fa5f0d-f3f6-44d6-aa66-b4b92c4bcae6
title: Volume and mute for each app
type: feature
status: backlog
milestone: sound-0.1
depends_on:
- 16
- 17
created: 2026-10-17
updated: 2026-10-17
priority: p1
effort: l
area: sound
---

## Problem

The core: turn one app down without touching the others.

## Proposal

Apply gain per tapped process from the menu's slider, with mute; volume is relative to the system volume; settings persist by bundle ID and apply when the app plays again.

## Acceptance criteria

- [ ] Changing one app's volume leaves every other app's level unchanged, measured.
- [ ] A remembered volume applies the next time the app plays.
- [ ] Quitting Common Sound returns every app to its normal output with no lingering mute.
