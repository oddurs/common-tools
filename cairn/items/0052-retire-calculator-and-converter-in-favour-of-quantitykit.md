---
id: 52
uid: f0e68be3-fc3a-4ec6-90fb-625f88adba8e
title: Retire Calculator and Converter in favour of QuantityKit
type: chore
status: backlog
milestone: command-quantities
depends_on:
- 51
created: 2026-10-18
updated: 2026-10-18
priority: p2
area: command
effort: s
---

## Purpose

Two answer engines in one search field disagree eventually; once QuantityKit covers what they do, they go.

## Approach

Port each `CalculatorTests` and `ConverterTests` case to the QuantityKit catalog, confirm every one still passes (locale handling included), then delete `Calculator.swift` and `Converter.swift` and their catalog entries.

## Acceptance criteria

- [ ] Every former Calculator and Converter test passes against QuantityKit.
- [ ] No behaviour users had is lost, or each loss is listed in the CHANGELOG.
