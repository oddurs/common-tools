---
id: 48
uid: 9c45ef42-3ad1-4932-a218-2f9003238ec9
title: Parse quantities written in a mix of English and math
type: feature
status: backlog
milestone: command-quantities
depends_on:
- 47
created: 2026-10-18
updated: 2026-10-18
priority: p1
area: command
effort: l
---

## Problem

People type `3 coffees a day for a year in grams`, `5'11" in cm` and `60 mph * 2h 15min`; a launcher's parser has to take all of them.

## Proposal

A normaliser and lexer (unicode ², ×, ÷, smart quotes, filler words) and a Pratt parser with implicit multiplication, English operators (`per`, `a`, `of`, `times`, `squared`, `in/to/as` at lowest precedence), feet and inches, mixed units, and the user's locale for decimal and grouping separators.

## Acceptance criteria

- [ ] Every parse-level query in the conformance suite gives tungsten's interpretation.
- [ ] A locale with a decimal comma reads `1,5 km` as 1.5 km, recorded as a deliberate difference.
- [ ] Parsing a 40-character query takes well under a millisecond (Benchmark gate).
