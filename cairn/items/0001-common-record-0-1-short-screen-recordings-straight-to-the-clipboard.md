---
id: 1
uid: 9daa49f8-eb7c-4bd0-929c-186a2074e37d
key: record-0.1
title: 'Common Record 0.1: short screen recordings, straight to the clipboard'
type: milestone
status: backlog
created: 2026-10-17
updated: 2026-10-17
priority: p1
area: record
---

Press a shortcut, choose an area, a window or the screen the way Common Shot does, and stop with the same shortcut: a short MP4 lands on the clipboard and in a corner preview, small enough to attach to a pull request, an issue or a chat without a trip through an editor.

## Problem

Showing a bug, a hover state or an animation takes a recording, and macOS's ⇧⌘5 records full-quality .mov files to the Desktop: too large for a pull request (GitHub takes 10 MB on a free plan), named for the date, and one more file to find, drag, and delete. Every other tool that does better is a large paid suite.

## The experience

- **Start.** ⌥⇧⌘2 by default, recordable in Settings. Common Shot's overlay appears: drag for an area, click for a window, Return for the screen. Recording starts the moment the choice is made, with no countdown; a red dot replaces the menu bar icon and shows the elapsed time.
- **Stop.** The shortcut again, the menu bar icon, or Escape. A recording that reaches the length limit (60 s by default) stops on its own and says so.
- **Result.** The MP4 is on the clipboard as a file, and a preview in the corner shows its first frame, length and size. Drag the preview out as a file, or click it to play it in Quick Look. Hold ⌥ when stopping to make a GIF instead.
- **Cancel.** Escape before anything is chosen, or the menu's Discard while recording, leaves nothing behind.

## In this milestone

- Area, window and screen recording at the display's frame rate, capped at 30 fps for sharing.
- MP4 (H.264, for every paste target) sized to fit 10 MB where the content allows; GIF with ⌥.
- Clipboard, corner preview, and recent recordings in the menu, as Common Shot does for shots.
- Show clicks: an optional ring where the pointer clicks.

## Not in this milestone

Editing beyond nothing at all (no trim, crop or annotation), microphone and system audio, webcam overlay, uploading anywhere, and recordings longer than ten minutes.

## Technical approach

ScreenCaptureKit (`SCStream` with an `SCContentFilter` for the display, window or area) feeding `AVAssetWriter`; `SCRecordingOutput` on macOS 15 where it is simpler. GIF through ImageIO's `CGImageDestination`, with a frame rate and size chosen to fit. The selection overlay is Common Shot's, moved into a shared package rather than copied (a separate item). Bitrate is chosen from the area's size and the length cap so the file fits; a test pins that choice.

## Permissions and privacy

Screen Recording only, asked through Welcome the way Common Shot asks. Nothing leaves the Mac; recordings live in `~/Library/Application Support/Common Record/` and are kept only as long as Settings says.

## Risks and open questions

- The shared overlay must not slow Common Shot's shortcut-to-overlay time; measure both.
- Window recording when the window moves or resizes mid-recording.
- Whether one app per job is right here, or Common Shot should record. Decided: separate apps, shared overlay package; revisit if the two drift into the same settings.

## Release gate

- Every item in this milestone is done.
- The owner has recorded and pasted a recording into a pull request, an issue and a chat, and each played inline.
- A 30-second recording of a full Retina screen at default settings is under 10 MB.
