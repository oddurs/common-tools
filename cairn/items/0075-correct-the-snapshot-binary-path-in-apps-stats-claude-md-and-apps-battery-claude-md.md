---
id: 75
uid: 7c976047-21a1-4454-8678-1489c473a878
title: Correct the snapshot binary path in apps/stats/CLAUDE.md and apps/battery/CLAUDE.md
type: bug
status: backlog
created: 2026-10-20
updated: 2026-10-20
priority: p3
area: stats
---

## What happens

Both CLAUDE.md files say `scripts/task build <app>` and then `.build/debug/<App> --snapshot`, but `build` makes a release build in a bundle; the debug binary exists only after `lint` or `test`, and it can't run outside a bundle (see 0073). Point them at `build/<app>/<Name>.app/Contents/MacOS/<Target> --snapshot`.
