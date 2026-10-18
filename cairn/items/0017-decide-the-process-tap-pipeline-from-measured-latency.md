---
id: 17
uid: 4a2a62e0-f30a-4a8b-a09d-6eaf27af41c9
title: Decide the process-tap pipeline from measured latency
type: chore
status: backlog
milestone: sound-0.1
created: 2026-10-17
updated: 2026-10-17
priority: p1
effort: m
area: sound
---

## Purpose

Per-app volume and routing through process taps is only worth building if the added latency and CPU are small and the audio holds up; measure before committing.

## Approach

A spike in the scratchpad, kept out of the app: tap one process with the original muted, apply gain, and play to a chosen device through an aggregate device. Measure round-trip latency, glitches over ten minutes, and CPU with one and three apps. Record the numbers and the decision in this item.

## Acceptance criteria

- [ ] Added latency, glitches and CPU are recorded for one and three apps.
- [ ] The decision on per-app output for 0.1 is recorded, with what would change it.
