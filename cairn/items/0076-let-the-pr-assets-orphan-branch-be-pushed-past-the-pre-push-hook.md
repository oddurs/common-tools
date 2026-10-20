---
id: 76
uid: 9b454f6e-9924-43bb-9af9-6b4b23aa3b96
title: Let the pr-assets orphan branch be pushed past the pre-push hook
type: bug
status: backlog
created: 2026-10-20
updated: 2026-10-20
priority: p3
area: repo
---

## What happens

The pre-push hook runs `scripts/task`, which doesn't exist on the orphan `pr-assets` branch, so PR screenshots can't be pushed with git; agents uploaded them through the contents API instead. Let the hook pass a branch without `scripts/task`, or document the API route.
