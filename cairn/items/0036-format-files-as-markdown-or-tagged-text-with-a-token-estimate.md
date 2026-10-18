---
id: 36
uid: c7df8ada-1a1c-4394-987b-597edc0f05e7
title: Format files as Markdown or tagged text, with a token estimate
type: feature
status: backlog
milestone: context-0.1
depends_on:
- 34
created: 2026-10-17
updated: 2026-10-17
priority: p2
effort: m
area: context
---

## Problem

Models read structure better than a wall of text, and the cost should be known before pasting.

## Proposal

A tree of included paths, then each file fenced with its language under its relative path; XML-style tags as an option. A local token estimate per file and in total, calibrated and labelled approximate.

## Acceptance criteria

- [ ] Both formats round-trip: every file's content is recoverable exactly from the output.
- [ ] The estimate is within 10 % of a published tokenizer on the calibration set.
