---
id: 20
uid: 7b7849f4-582f-4ae7-acf0-587831241dad
title: Send each app to its own output device
type: feature
status: backlog
milestone: sound-0.1
depends_on:
- 16
- 19
created: 2026-10-17
updated: 2026-10-17
priority: p1
effort: l
area: sound
---

## Problem

Calls in headphones, music on speakers.

## Proposal

A device menu per app row: System output, or a specific device; built on the spike's decision. A device that disconnects sends its apps back to System output.

## Acceptance criteria

- [ ] Two apps play to two devices at once without glitches for ten minutes.
- [ ] Unplugging a device moves its apps to System output within a second.
- [ ] If the spike ruled this out for 0.1, this item records why and moves to a later milestone.
