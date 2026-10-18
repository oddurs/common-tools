---
id: 13
uid: 77fb1e58-d195-4b17-9cf1-ea0e4693f77b
title: Recordable shortcuts with conflict warnings
type: feature
status: backlog
milestone: window-0.1
depends_on:
- 9
created: 2026-10-17
updated: 2026-10-18
priority: p1
effort: m
area: window
---

## Problem

Window shortcuts collide with apps' own and with the system's.

## Proposal

A Settings list of commands with a recorder each, reusing Common Command's KeyCombo and conflict check through a shared package; a conflict with a system shortcut or another Common Tools app shows a warning and the option to keep it anyway.

## Acceptance criteria

- [ ] Changing a shortcut takes effect immediately and persists.
- [ ] A known system conflict is flagged.
- [ ] Common Command still passes its tests after the shared code moves.

## 2026-10-18

From color-0.1 (feat/color-picking): CommonKit now has a CommonShortcut product (KeyCombo, HotKey, ShortcutRecorder), built from Command's and Shot's identical copies. HotKey(signature:) gives each instance its own id and ignores other instances' presses, so several shortcuts per app work. It is a separate product because Command and Shot import CommonKit and define their own KeyCombo; moving them onto it, and the conflict check from Command's Conflicts.swift, is this item's work. Common Color is the only user so far.
