---
id: 53
uid: 17a52b95-6010-4463-8cd8-5136db03c50f
title: Interpret loose questions with the on-device language model
type: feature
status: backlog
milestone: command-quantities
depends_on:
- 51
created: 2026-10-18
updated: 2026-10-18
priority: p3
area: command
effort: m
---

## Problem

Some questions are quantities in disguise (`how long to drive 300 km at 110`), and no grammar will catch them all.

## Proposal

On macOS 26 with Apple Intelligence, when QuantityKit cannot parse a query that looks like a question, ask Apple's on-device Foundation Models framework to rewrite it as a QuantityKit query, then compute with QuantityKit; the model only interprets, never answers. Off on Macs without it; nothing leaves the Mac.

## Acceptance criteria

- [ ] The rewritten query is shown as the interpretation, so the user can see what was computed.
- [ ] A wrong rewrite can never produce an answer QuantityKit did not compute.
- [ ] Unavailable models change nothing.
