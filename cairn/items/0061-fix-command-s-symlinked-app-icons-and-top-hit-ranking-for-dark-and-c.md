---
id: 61
uid: 2b3c08ec-48a6-434a-b0e1-002b054bc901
title: Fix Command's symlinked app icons and top-hit ranking for dark and c
type: bug
status: done
assignee: Oddur Sigurdsson
created: 2026-10-20
updated: 2026-10-20
closed_at: 2026-10-20
priority: p1
area: command
effort: s
---

## What happens

Found with `CommonCommand --snapshot` before Common Command's first release:

- Safari's icon carries Finder's alias arrow. `/Applications/Safari.app` is a symlink into the Safari cryptex, and the icon is read for the symlink.
- "dark" makes Dark Noise, an Accessibility topic, the Top Hit, above Appearance, which System Settings indexes under "dark".
- "c" makes the iCloud Drive folder the Top Hit, above Calendar, Chess and Clock.

## What should happen

- Apps reached through a symlink or a Finder alias show the app's own icon.
- "dark" finds Appearance first, as System Settings' own search does, while an app whose name starts with "dark" still comes before it.
- A name that starts with the query beats one where it only starts a later word or a camel-case hump, by more than the weights between kinds of result.

## Reproduction

1. `scripts/task build command`
2. `CommonCommand --snapshot out.png "saf"`, `"dark"`, `"c"`

## Acceptance criteria

- [x] A test shows a symlinked or aliased app draws the same icon as the app itself, and the fix makes it pass.
- [x] A test shows "dark" ranks Appearance above Dark Noise and below an app named Dark..., and the fix makes it pass.
- [x] A test shows "c" ranks Calendar, Chess and Clock above iCloud Drive, and the fix makes it pass.
- [x] Every existing CommandKit test and the ranking performance gate pass.
- [x] Before/after snapshots of "dark", "c" and "saf" in the pull request.
