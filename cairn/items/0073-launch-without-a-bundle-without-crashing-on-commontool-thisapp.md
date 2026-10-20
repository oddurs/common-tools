---
id: 73
uid: c38e9b45-6d7a-42a0-a235-d7e4d91f6087
title: Launch without a bundle without crashing on CommonTool.thisApp
type: bug
status: backlog
created: 2026-10-20
updated: 2026-10-20
priority: p3
area: keys
---

## What happens

`apps/keys/Sources/CommonKeys/main.swift:11` force-unwraps `CommonTool.thisApp!`, so the debug binary crashes when run outside a bundle (Command's does the same in AppController.swift:15). A shipped app is fine unless its bundle identifier ever stops matching; a clear failure message would be kinder to whoever runs the binary.
