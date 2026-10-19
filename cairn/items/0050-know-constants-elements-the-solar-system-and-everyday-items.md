---
id: 50
uid: ab7f823c-e954-419c-a247-dd2919fd56b6
title: Know constants, elements, the solar system and everyday items
type: feature
status: backlog
milestone: command-quantities
depends_on:
- 49
created: 2026-10-18
updated: 2026-10-18
priority: p2
area: command
effort: m
---

## Problem

`mass of earth`, `how far is the moon`, `3 coffees in mg of caffeine` are what make it feel intelligent rather than a calculator.

## Proposal

Generate the knowledge base from tungsten's `data/constants.toml`, `elements.toml`, `solar.toml`, `food.toml`, `items.toml` and `properties.toml` with each value's source; resolve entities and properties in the four forms tungsten accepts (`mass of earth`, `earth's mass`, `earth.mass`, `earth mass`) and its question phrasings.

## Acceptance criteria

- [ ] Every knowledge query in the conformance suite passes.
- [ ] Each answer can name its source.
- [ ] The generated tables fail a test when stale against the pinned data.
