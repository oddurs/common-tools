---
id: 30
uid: e586fc72-a215-4b38-b839-2e44e9afade9
title: Pick a pixel with the system sampler
type: feature
status: blocked
milestone: color-0.1
assignee: Oddur Sigurdsson
claimed: 2026-10-18
depends_on:
- 29
created: 2026-10-17
updated: 2026-10-18
priority: p2
effort: s
area: color
---

## Problem

Picking must be instant and need no permission.

## Proposal

`NSColorSampler` from a global shortcut and from the menu; the result goes to ColorKit with its colour space.

## Acceptance criteria

- [ ] Picking works with no permission granted to the app.
- [ ] Escape cancels and leaves the clipboard untouched.

## 2026-10-18

Built: NSColorSampler from ⌃⇧⌘C (CommonKit's new CommonShortcut, Carbon RegisterEventHotKey: no Accessibility or Input Monitoring) and from Pick Color in the menu, which opens the loupe on the next run-loop turn so it doesn't magnify the closing menu. The result goes to ColorKit as ColorValue(NSColor): ColorSync to extended sRGB (clips nothing) to find where it lies, then ColorSync's own Display P3 components when it is inside P3, because ColorSync's quantised P3 profile adds ~0.0003 on a round trip through sRGB (P3 0 1 0 came back 0 1 0.0003).

## 2026-10-18

Permission, verified statically: the app links no ScreenCaptureKit and calls no CGWindowList/CGDisplay capture or CGRequestScreenCaptureAccess; Info.plist has no usage-description keys; apps.json PERMISSIONS is empty. NSColorSampler is Apple's API for exactly this: it shows the system loupe and returns only the clicked colour, without Screen Recording. Escape: the sampler's handler gets nil, and the handler returns before touching history or NSPasteboard. NOT verified hands-on: posting synthetic clicks was off limits, so nobody has yet clicked the loupe in the built app. Criteria 1 and 2 wait for the owner: install, press ⌃⇧⌘C with Screen Recording off for Common Color, click a pixel and paste; press it again and Escape, and paste to see the clipboard unchanged.

## 2026-10-18

Correction to the permission note: the binary does reference CGPreflightScreenCaptureAccess and CGRequestScreenCaptureAccess, linked in from CommonKit's Permission (Permission.swift), but every call is behind WelcomeInfo.permission, which Common Color leaves nil, so nothing in the app reaches them. otool shows no ScreenCaptureKit; the app's own sources call no capture API; Info.plist has no usage keys.
