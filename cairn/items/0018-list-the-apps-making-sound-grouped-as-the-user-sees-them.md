---
id: 18
uid: 2ef4b26a-1469-4eba-ba29-4064b407a4d9
title: List the apps making sound, grouped as the user sees them
type: feature
status: backlog
milestone: sound-0.1
depends_on:
- 16
- 17
created: 2026-10-17
updated: 2026-10-17
priority: p1
effort: m
area: sound
---

## Problem

A per-app control is useless if the list shows helper processes the user has never heard of.

## Proposal

Read Core Audio's process objects and their running-output state; group helper processes under the app that owns them (by responsible process or bundle hierarchy); show icon and name; fade out an app a few seconds after it stops.

## Acceptance criteria

- [ ] A browser playing audio appears once, under the browser's name.
- [ ] The list updates within a second of an app starting or stopping playback.
- [ ] SoundKit tests cover the grouping from recorded process trees.
