---
id: 38
uid: 4d61360d-4213-410e-bb66-eea728b981c2
key: agents-0.1
title: 'Common Agents 0.1: know when a coding agent is waiting for you'
type: milestone
status: backlog
created: 2026-10-17
updated: 2026-10-17
priority: p2
area: agents
---

A menu bar view of the coding-agent sessions running on this Mac, with what each is doing, and a notification the moment one needs you or finishes, so a long session never sits idle waiting for an answer nobody saw.

## Problem

Running several agent sessions across terminals means checking each one to see whether it is still working, finished, or blocked on a question. The time lost is the time a session waits unseen.

## The experience

- **Menu.** One row per session: project folder, the tool, state (working, waiting for you, finished, failed) and for how long. Click a row to bring its terminal forward.
- **Notifications.** When a session starts waiting for input or finishes, a notification names the project; clicking it brings the terminal forward.
- **Icon.** Shows a count of sessions waiting for you.
- **Setup.** One button installs the hooks for supported tools (Claude Code first), showing exactly what it will add to which file and asking before writing.

## In this milestone

The local event channel and its command-line client, the hooks installer for Claude Code, the session list, notifications, and focusing the terminal app.

## Not in this milestone

Reading or showing what the agent said, controlling sessions, remote machines, and tools without a hook mechanism (a generic `common-agents run -- <cmd>` wrapper covers those at the level of "finished").

## Technical approach

A small command-line client inside the bundle (`common-agents event <state> --session <id> --cwd <dir>`) that the tools' hooks call; it writes to a Unix socket the app listens on, or to a spool directory when the app is not running. AgentsKit holds the session state machine with time as a parameter. Focusing uses the terminal app's process (from the event's parent chain) and `NSRunningApplication.activate`; focusing a specific tab is out of scope.

## Permissions and privacy

Notifications only. Nothing leaves the Mac; events carry state, a folder path and a session ID, never prompts or output.

## Risks and open questions

- Hook formats change between tool versions; the installer must detect and show what it wrote, and uninstall cleanly.
- This is specific to how the owner works; ship it only if it is used daily.

## Release gate

- Every item is done.
- The owner has run three sessions at once for a day and was told every time one waited.
