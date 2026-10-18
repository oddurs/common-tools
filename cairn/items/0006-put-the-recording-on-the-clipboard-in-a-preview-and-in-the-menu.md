---
id: 6
uid: 27c07060-e114-4ecc-bea3-749f7961fde9
title: Put the recording on the clipboard, in a preview and in the menu
type: feature
status: backlog
milestone: record-0.1
depends_on:
- 2
created: 2026-10-17
updated: 2026-10-17
priority: p1
effort: m
area: record
---

## Problem

A recording is only useful once it is pasted; finding a file on the Desktop is the step this app removes.

## Proposal

The finished file goes on the clipboard as a file URL; a corner preview shows its first frame, length and size, drags out as a file, and opens in Quick Look on click. The menu lists recent recordings to copy again. ⌥ while stopping writes a GIF instead, sized to fit.

## Acceptance criteria

- [ ] Pasting into a GitHub comment, Slack and Messages attaches the video.
- [ ] A GIF made with ⌥ plays in a GitHub comment and is under 10 MB for a 10 s area recording.
- [ ] History keeps as many recordings as Settings says and deletes the rest.
