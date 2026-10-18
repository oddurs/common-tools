---
id: 35
uid: 6a0ebf59-7ee5-4146-a3bf-bc19c4953954
title: Gather files the way git would
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

Pasting a lockfile or a build folder wastes a prompt; missing the one file that mattered wastes the answer.

## Proposal

ContextKit walks the selection with gitignore semantics (nested ignores, negation), skips binary files by content and files over a size limit, and leaves out a short list of common noise unless asked.

## Acceptance criteria

- [ ] Tests compare the included set with `git ls-files` plus untracked-not-ignored on fixture repositories.
- [ ] A binary file with a text extension is still left out.
