---
id: 44
uid: d9d9ef30-3d55-431e-9e86-f64acf44c3ac
key: command-quantities
title: 'Common Command: quantities and facts in the search field'
type: milestone
status: backlog
created: 2026-10-18
updated: 2026-10-18
priority: p1
area: command
---

Type a calculation with real-world units, a conversion, or a factual question into Common Command and the answer is the first row: `60 mph * 2h 15min` gives 135 mi, `mass of earth` gives 5.972 × 10²⁴ kg, `1/3 + 1/6` gives 1/2. Computed on the Mac, from cited data, in under a millisecond, by a Swift port of tungsten's core.

## Problem

Common Command answers arithmetic (`Calculator`, 225 lines) and same-kind unit conversions (`Converter`, 129 lines, Foundation's units). It cannot multiply a speed by a time, keep fractions exact, convert to mixed units, explain why `3 m + 2 s` is wrong, or answer `how far is the moon`. tungsten (github.com/oddurs/tungsten, Rust, MIT, about 11,800 lines plus 9,600 lines of TOML data) does all of that offline in about 0.4 ms, and its promise (offline, instant, correct, cited) is the Common Tools promise.

## The experience

- **Answer row.** When the query reads as a quantity, a conversion or a known fact, the first row is the answer in large type with its unit, its interpretation as the subtitle (`60 mph × (2 h + 15 min)`), and Return copies the value. ⌘C copies with the unit.
- **Other units.** The row's secondary actions (→ or the action menu) list the other-units pod: 217.3 km, 237 600 yd; each copies.
- **For scale.** One line under the answer when tungsten would show it: "≈ 5.1 marathons".
- **Errors that teach.** A query that is clearly a calculation but fails (dimension mismatch, unknown unit) shows one quiet row with the hint (`did you mean 3 m / 2 s = 1.5 m/s?`), never an alert, and never above an app that matches the text.
- **Never hijacks.** "Notes", "safari", "mail" still find the apps. An answer appears only when the query has a digit or an operator, or matches a fact pattern, and its rank is computed like any other row's.

## In this milestone

The units engine (dimensions, exact rationals, affine temperatures, conversion to one or several units), the language (numbers, English operators, `in/to/as`, implicit multiplication), the knowledge base (constants, elements, solar system, foods, items) generated from tungsten's data, the answer row with other units and for-scale, error hints, and retiring `Calculator` and `Converter` with their behaviour kept.

## Not in this milestone

Variables, functions and `it` across queries; tungsten's later work (notebooks, solve, plot, error bars, calendars); live currency rates (they need the network, which the promise rules out: currency stays a unit you can compute with, not convert between); and the on-device language model, filed separately for later.

## Technical approach

A Swift port, decided in the first item: a package `packages/Quantities` (library `QuantityKit`, no dependencies) that Command imports and any app can. Two things keep it from drifting from tungsten:

1. **Data is generated, never retyped.** A script reads tungsten's `data/*.toml` at a pinned commit and writes Swift tables, the way `packages/common-ui/build.mjs` writes `Tokens.swift`; a test fails when the output is stale.
2. **Behaviour is pinned by tungsten's own corpus.** tungsten's `tests/queries.txt` (194 queries) and their expected results, exported from tungsten as JSON at the same pinned commit, become QuantityKit's conformance suite. A divergence is either a bug or a recorded, deliberate difference.

Performance is a regression gate (`Benchmark` from CommonTesting): parse and evaluate in well under a millisecond, so the field can ask on every keystroke.

## Permissions and privacy

None added. Nothing leaves the Mac; every fact carries its source.

## Risks and open questions

- The port is the largest single piece of work in Command; the conformance suite is what makes it tractable and keeps it honest.
- Locales that write a decimal comma: tungsten reads `1,500` as a thousand separator; QuantityKit must follow the user's locale as Command does today, recorded as a deliberate difference.
- Ranking: an answer that outranks an app the user wanted is worse than no answer; the gating item measures it against Command's usage tests.

## Release gate

- Every item is done.
- The conformance suite passes for every query in scope, with each deliberate difference listed.
- Typing `60 mph * 2h 15min`, `5'11" in cm`, `mass of earth`, `98.6 °F in °C` and `100000 s in h, min, s` gives the right first row, and `notes`, `safari`, `music` still open the apps.
