---
id: 47
uid: 10086ac5-d6da-4c7b-84e4-dcd00c6f20b7
title: A QuantityKit package with dimensions, exact rationals and the unit table
type: feature
status: planned
milestone: command-quantities
depends_on:
- 45
created: 2026-10-18
updated: 2026-10-18
priority: p1
area: command
effort: l
---

## Problem

Everything rests on quantities that know their dimension and stay exact while they can.

## Proposal

`packages/Quantities` (library `QuantityKit`, no dependencies): dimension vectors with rational exponents over tungsten's ten base dimensions (count and information included), an exact rational type with overflow falling back to Double, quantities, and the unit table with SI prefixes, imperial and US customary units, generated from tungsten's `data/units.toml` by the sync script with a staleness test.

## Acceptance criteria

- [ ] Unit arithmetic and conversions in the conformance suite pass for the unit-only queries.
- [ ] `1/3 + 1/6` is exactly `1/2`; rationals fall back to Double only on overflow, tested.
- [ ] The generated table fails a test when it is older than the pinned tungsten data.
