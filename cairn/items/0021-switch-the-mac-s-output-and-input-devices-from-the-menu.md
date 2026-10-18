---
id: 21
uid: efc07843-414f-4a35-aa87-f727401a9799
title: Switch the Mac's output and input devices from the menu
type: feature
status: backlog
milestone: sound-0.1
depends_on:
- 16
created: 2026-10-17
updated: 2026-10-17
priority: p1
effort: s
area: sound
---

## Problem

Choosing a device takes four clicks in Control Center and System Settings.

## Proposal

The top of the menu lists output and input devices with the current one ticked; choosing one sets it as the system default. No permission needed.

## Acceptance criteria

- [ ] Choosing a device changes the system default immediately.
- [ ] Devices that connect or disconnect appear and disappear while the menu is open.
