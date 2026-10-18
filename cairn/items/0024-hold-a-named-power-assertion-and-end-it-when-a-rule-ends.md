---
id: 24
uid: f2754dd1-9cb3-4440-a682-8201da8ec632
title: Hold a named power assertion and end it when a rule ends
type: feature
status: backlog
milestone: awake-0.1
depends_on:
- 23
created: 2026-10-17
updated: 2026-10-17
priority: p2
effort: m
area: awake
---

## Problem

An assertion left behind is worse than none: the Mac never sleeps and nothing says why.

## Proposal

One AwakeKit model of the active rule (indefinite, timer, until app quits, while on power, battery floor) with the time as a parameter, driving one named IOKit assertion; the display assertion only when the toggle is on.

## Acceptance criteria

- [ ] AwakeKit tests cover every rule's start and end, including the battery floor.
- [ ] `pmset -g assertions` shows the reason while active and nothing after, checked for each rule.
- [ ] Quitting Common Awake releases its assertion.
