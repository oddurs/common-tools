---
id: 41
uid: 82ddcab7-71ce-473e-acad-34963cdfda4d
title: Install and remove the hooks for Claude Code, with consent
type: feature
status: backlog
milestone: agents-0.1
depends_on:
- 39
- 40
created: 2026-10-17
updated: 2026-10-17
priority: p2
effort: m
area: agents
---

## Problem

Hand-editing hook configuration is error-prone, and silently editing it is unacceptable.

## Proposal

A Settings button that shows the exact hook entries and the file they go in, writes them only on confirmation, keeps a backup, and removes exactly what it added.

## Acceptance criteria

- [ ] Install then uninstall leaves the configuration byte-identical to before.
- [ ] An existing user hook is preserved and never reordered.
