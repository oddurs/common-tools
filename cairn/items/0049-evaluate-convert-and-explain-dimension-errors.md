---
id: 49
uid: 12dad15b-8c24-44ef-b1d2-bcdc9afdf121
title: Evaluate, convert and explain dimension errors
type: feature
status: backlog
milestone: command-quantities
depends_on:
- 48
created: 2026-10-18
updated: 2026-10-18
priority: p1
area: command
effort: l
---

## Problem

The value of the port is answers that are right, and errors that say why.

## Proposal

An evaluator over the AST with exact rationals, affine temperatures (readings versus differences, as tungsten's concept §3 defines), conversion to one or several target units (`in h, min, s`), significant-figure formatting, and errors carrying the spans and dimensions of both sides plus tungsten's did-you-mean hint.

## Acceptance criteria

- [ ] The conformance suite passes for arithmetic, conversion and error queries.
- [ ] `20 °C + 5 °C` suggests `Δ°C`, as tungsten does.
- [ ] Errors carry enough to render a one-line hint without re-parsing.
