---
id: 51
uid: 218d8823-be1c-400a-a53c-d095916d4453
title: Show the answer as Command's first row, without hijacking searches
type: feature
status: backlog
milestone: command-quantities
depends_on:
- 49
created: 2026-10-18
updated: 2026-10-18
priority: p1
area: command
effort: m
---

## Problem

An answer that outranks the app the user wanted is worse than no answer at all.

## Proposal

A QuantityKit catalog in CommandKit: answer only when the query has a digit or an operator, or matches a fact pattern; score by parse confidence (exact parse, then fact lookup, then fuzzy) through the existing Ranker; render the result large with the interpretation as subtitle, other units as secondary actions, one for-scale line, and a quiet hint row for clear-but-failed calculations. Return copies the value, ⌘C with its unit.

## Acceptance criteria

- [ ] `notes`, `safari`, `music`, `mail` and the usage tests' app queries rank exactly as before.
- [ ] The release-gate queries give the right first row.
- [ ] Keystroke-to-results stays within the Ranker's Benchmark budget with QuantityKit in the catalog.
- [ ] Before/after renders of the panel with an answer row, light and dark.
