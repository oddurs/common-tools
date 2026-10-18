---
id: 22
uid: 78b981ea-6dc7-4be1-8213-4bcd7166120b
key: awake-0.1
title: 'Common Awake 0.1: keep the Mac awake for exactly as long as something needs it'
type: milestone
status: backlog
created: 2026-10-17
updated: 2026-10-17
priority: p2
area: awake
---

Keep the Mac awake while a build, a download or a long agent session runs, then let it sleep on its own: for a time, until an app quits, until a command finishes, or while on power. The menu also says what else is keeping the Mac awake right now.

## Problem

The usual answer is `caffeinate` in a terminal or an app that keeps the Mac awake until you remember to turn it off. Either way the Mac stays awake for longer than it needs to, and nothing tells you which other app is holding off sleep.

## The experience

- **Click the icon** to keep awake indefinitely; click again to stop. The icon fills while active.
- **The menu** offers: for 15 min, 1 h, 3 h; until an app quits (chosen from running apps); while on power; and stop below a battery level (20 % by default).
- **From a terminal**: `common-awake -- <command>` keeps the Mac awake while the command runs and passes through its exit status.
- **Who else**: the menu lists every other process holding sleep off, with its reason.
- **Display**: by default the display may sleep while the system stays awake; a toggle keeps the display on too.

## In this milestone

Everything above.

## Not in this milestone

Staying awake with the lid closed (macOS allows it only with power and an external display, and Common Awake will not work around that), schedules, and network-activity rules.

## Technical approach

IOKit power assertions (`IOPMAssertionCreateWithName` with `PreventUserIdleSystemSleep`, and `PreventUserIdleDisplaySleep` when asked), always named with the reason so they show in `pmset -g assertions`. Other processes' assertions from `IOPMCopyAssertionsByProcess`. Rules live in AwakeKit as plain values with time as a parameter. The command-line tool ships inside the app bundle and talks to the app over a local socket, or holds its own assertion when the app is not running.

## Permissions and privacy

None. Nothing leaves the Mac.

## Risks and open questions

- Should this be part of Common Battery instead? Decided: its own app, one job each; revisit if Battery grows a power section that duplicates it.

## Release gate

- Every item is done.
- `pmset -g assertions` shows Common Awake's assertion with its reason while active and nothing once a rule ends.
