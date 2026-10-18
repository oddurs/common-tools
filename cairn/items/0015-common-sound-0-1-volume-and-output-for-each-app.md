---
id: 15
uid: 003e2cc3-7754-4677-8439-87714c08a263
key: sound-0.1
title: 'Common Sound 0.1: volume and output for each app'
type: milestone
status: backlog
created: 2026-10-17
updated: 2026-10-17
priority: p1
area: sound
---

A menu of the apps making sound right now, each with its own volume, mute and output device: keep a call in your headphones while music plays on the speakers, or turn down one loud tab without touching everything else. Switching the Mac's own output and input is one click away.

## Problem

macOS has one volume for everything and one output for everything. The apps that fix it have long relied on a virtual audio driver installed into the system, which is heavy, needs an administrator, and breaks on upgrades. Since macOS 14.2 Core Audio offers process taps, a public way to do this without a driver.

## The experience

- **Menu.** Click the icon: the output and input devices at the top, then every app currently playing, with its icon, a volume slider and a mute button. An app that stops playing fades out of the list after a few seconds.
- **Per-app output.** Each app row has a device menu: "System output" (follows the Mac) or a specific device.
- **Memory.** Volumes and routes are kept by app and applied when the app plays again.
- **Keyboard.** The volume keys still control the system volume; per-app volume is relative to it.

## In this milestone

Listing playing apps, per-app volume (0–100 %, with a boost to 150 % only if it holds up without clipping), mute, per-app output device, device switching for the system's output and input, and persistence by bundle ID.

## Not in this milestone

Equaliser and effects, input per app, recording, and anything for macOS before 14.2.

## Technical approach

Core Audio process taps (`CATapDescription`, `AudioHardwareCreateProcessTap`) on each playing process with the original muted, fed through an aggregate device to the chosen output where the gain is applied. The process list and running state come from `kAudioHardwarePropertyProcessObjectList` and `kAudioProcessPropertyIsRunningOutput`. A first item is a spike that measures added latency and glitches before the rest is built; drift between devices uses the aggregate device's drift compensation. Minimum macOS for this app is 14.2.

## Permissions and privacy

System Audio Recording (the audio-capture permission process taps require), asked when the first per-app control is used; device switching needs no permission. Audio is processed in memory and never written or sent anywhere.

## Risks and open questions

- Added latency must stay under about 20 ms or video calls drift out of lip sync; the spike decides whether per-app output ships in 0.1.
- Apps that play through a helper process (browsers' audio services) must be grouped under the app the user sees.
- CPU cost with several apps playing; budget it in the spike.

## Release gate

- Every item is done.
- The spike's latency and CPU numbers are recorded in its item and within budget.
- The owner has run a video call in headphones with music on speakers for an hour without a glitch they noticed.
