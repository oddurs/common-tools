---
id: 26
uid: 8de8b07e-5506-4025-bc99-15076b018be2
title: Keep awake while a command runs
type: feature
status: backlog
milestone: awake-0.1
depends_on:
- 23
- 24
created: 2026-10-17
updated: 2026-10-17
priority: p2
effort: m
area: awake
---

## Problem

Long builds, test runs and agent sessions start in a terminal; that is where the rule should start too.

## Proposal

A `common-awake` tool inside the bundle (with a Settings button to link it into PATH): `common-awake -- <command>` keeps the Mac awake for the command's life and exits with its status; `common-awake --pid <n>` waits on a running process.

## Acceptance criteria

- [ ] The tool exits with the command's exit status.
- [ ] The assertion ends when the command ends, even if it is killed.
- [ ] It works whether or not the app is running.
