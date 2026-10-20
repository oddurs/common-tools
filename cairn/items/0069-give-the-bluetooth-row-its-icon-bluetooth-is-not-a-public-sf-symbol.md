---
id: 69
uid: a8f53b91-c5f9-467e-9d9c-7eeb9a314218
title: 'Give the Bluetooth row its icon: "bluetooth" is not a public SF Symbol'
type: bug
status: backlog
created: 2026-10-20
updated: 2026-10-20
priority: p1
area: bar
---

## What happens

`Dropdown.symbol` (apps/bar/Sources/BarKit/Dropdown.swift) maps Bluetooth to `"bluetooth"`, which `NSImage(systemSymbolName:)` doesn't resolve, and `RowIcon` falls back to `app.dashed` only when no symbol is named, not when one fails to load. So Bluetooth's row in More's panel has no icon. Shipped in Bar 0.4.0; found while filming. Fix the name or fall back on a failed load, with a test that every symbol `Dropdown.symbol` names resolves.
