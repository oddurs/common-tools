---
id: 74
uid: 5de5900d-f57e-4ccb-ae1f-9cbe6f2850da
title: Correct the status item render command in apps/keys/CLAUDE.md
type: bug
status: backlog
created: 2026-10-20
updated: 2026-10-20
priority: p3
area: keys
---

## What happens

`apps/keys/CLAUDE.md` gives `--status` for rendering the status item; the working command is `CommonKeys --snapshot out.png --status`. `--status out.png` launches the app instead.
