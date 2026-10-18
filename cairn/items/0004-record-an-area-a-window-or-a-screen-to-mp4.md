---
id: 4
uid: 6d3d7177-25ff-49c2-8f83-f953374f605b
title: Record an area, a window or a screen to MP4
type: feature
status: backlog
milestone: record-0.1
depends_on:
- 2
- 3
created: 2026-10-17
updated: 2026-10-17
priority: p1
effort: l
area: record
---

## Problem

The core: turn a selection into a video file that plays everywhere it is pasted.

## Proposal

ScreenCaptureKit into `AVAssetWriter` (H.264, yuv420, faststart). Frame rate from the display, capped at 30 fps. Bitrate chosen in RecordKit from area, frame rate and the length cap so the file fits 10 MB; a window recording follows the window.

## Acceptance criteria

- [ ] A 30 s full-screen Retina recording at defaults is under 10 MB and plays in QuickTime, Safari, and a GitHub pull request.
- [ ] A window recording keeps the window framed when it moves.
- [ ] RecordKit tests pin the bitrate choice for a range of sizes and lengths.
