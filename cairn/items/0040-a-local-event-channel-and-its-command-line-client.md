---
id: 40
uid: bcc4c15b-ac0a-4a8d-9434-82c063b745e8
title: A local event channel and its command-line client
type: feature
status: backlog
milestone: agents-0.1
depends_on:
- 39
created: 2026-10-17
updated: 2026-10-17
priority: p2
effort: m
area: agents
---

## Problem

Agents' hooks need something trivial and fast to call that never blocks the agent.

## Proposal

`common-agents event` writes a small JSON event to the app's Unix socket with a short timeout, or to a spool directory the app drains on launch; AgentsKit turns events into a session state machine.

## Acceptance criteria

- [ ] The client returns in under 50 ms whether or not the app is running.
- [ ] AgentsKit tests cover every state transition and stale-session expiry.
- [ ] No event contains prompt or output text.
