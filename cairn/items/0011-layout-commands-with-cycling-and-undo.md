---
id: 11
uid: f62ba4c5-7f30-42c0-8bee-705fd20e7b16
title: Layout commands with cycling and undo
type: feature
status: backlog
milestone: window-0.1
depends_on:
- 9
- 10
created: 2026-10-17
updated: 2026-10-17
priority: p1
effort: m
area: window
---

## Problem

Halves alone are what macOS already offers; the value is thirds, cycling and an easy way back.

## Proposal

The command set from the milestone, cycling ½ → ⅓ → ⅔ on repeat presses within a second, and ⌃⌥⌫ to restore the window's frame from before the last command.

## Acceptance criteria

- [ ] Each command has a WindowKit test for its target frame.
- [ ] Cycling resets after a second or after another command.
- [ ] Restore returns the exact previous frame.
