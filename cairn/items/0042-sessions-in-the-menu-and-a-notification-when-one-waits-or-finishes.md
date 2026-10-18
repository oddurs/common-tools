---
id: 42
uid: 13e0840a-557a-4571-9bad-2a05db425d11
title: Sessions in the menu and a notification when one waits or finishes
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

The point of the app: never miss a session waiting for you.

## Proposal

Rows per session with project, state and duration; a notification on waiting and on finished; the icon shows the waiting count; clicking a row or notification activates the terminal app.

## Acceptance criteria

- [ ] A session that asks for input notifies within a second.
- [ ] Clicking the notification brings the right terminal app forward.
- [ ] Sessions that end without a final event expire after a timeout instead of lingering.
