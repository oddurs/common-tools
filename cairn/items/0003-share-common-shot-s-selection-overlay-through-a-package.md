---
id: 3
uid: 73e8c950-3837-4f3c-89a0-3ad3a11713e1
title: Share Common Shot's selection overlay through a package
type: feature
status: backlog
milestone: record-0.1
depends_on:
- 2
created: 2026-10-17
updated: 2026-10-17
priority: p1
effort: l
area: record
---

## Problem

Common Record needs exactly the overlay Common Shot has (freeze, drag, window hover, Return for the screen, size pill, loupe). Copying it would let the two drift.

## Proposal

Move the overlay and its geometry into a package both apps import (for example `packages/CommonCapture`), with the geometry and gesture logic tested there. Common Shot keeps its behaviour exactly; Common Record passes what differs, such as whether the screen freezes (it must not, for a recording).

## Acceptance criteria

- [ ] Common Shot's overlay behaves identically before and after, shown by its existing tests and before/after renders.
- [ ] Shortcut-to-overlay latency in Common Shot does not rise, measured before and after.
- [ ] The overlay can run without freezing the screen.
