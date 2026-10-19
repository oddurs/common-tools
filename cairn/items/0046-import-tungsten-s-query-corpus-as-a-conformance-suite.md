---
id: 46
uid: b6ff436b-0c33-4f90-9705-1dc5146a177b
title: Import tungsten's query corpus as a conformance suite
type: feature
status: planned
milestone: command-quantities
depends_on:
- 45
created: 2026-10-18
updated: 2026-10-18
priority: p1
area: command
effort: m
---

## Problem

A port without a shared test corpus drifts silently, and nobody can say which answers differ from tungsten's.

## Proposal

A script (`scripts/tungsten-sync`) checks out tungsten at a pinned commit, runs each query in its `tests/queries.txt` through tungsten with structured output (adding a `--json` flag to tungsten if it has none, in tungsten's own repository), and writes `packages/Quantities/Tests/Conformance/queries.json`: query, expected value, unit, interpretation, and error kind. A Swift Testing suite runs every query through QuantityKit and compares; deliberate differences live in a reviewed list with a reason each.

## Acceptance criteria

- [ ] The pinned tungsten commit is recorded in one place and the script is reproducible from it.
- [ ] The suite reports each failing query by text, not just a count.
- [ ] Deliberate differences (locale decimal comma, at least) are listed with reasons.
