---
id: 33
uid: 9d5e07bd-2707-4859-8f6e-cc4c3e70289d
key: context-0.1
title: 'Common Context 0.1: files and folders as prompt-ready text'
type: milestone
status: backlog
created: 2026-10-17
updated: 2026-10-17
priority: p2
area: context
---

Select files or a folder and copy them as one block of text a model can read: a tree of what is included, then each file in a fenced block under its path, skipping what .gitignore skips and anything binary, with a token count before you paste.

## Problem

Giving a chat model several files means opening each, copying, pasting and labelling it by hand, or running a script. Too much gets pasted (lockfiles, build output) or too little (the file that mattered), and nobody knows how many tokens it cost until the model complains.

## The experience

- **From Finder.** Select files or folders, then Services ▸ Copy as Context, or a Quick Action; or drop them on the menu bar icon.
- **Preview.** A small panel lists what will be included with each file's size and tokens, the total, and checkboxes to leave things out; Return copies.
- **Result.** Markdown by default: a tree, then each file fenced with its language under its relative path. XML-style tags as an option.
- **Rules.** `.gitignore`, `.ignore`, binary files, files over 1 MB, and common noise (lockfiles, `node_modules`, `.build`) are left out unless ticked.

## In this milestone

Services and drop entry points, the preview panel, both formats, the ignore rules, and a token estimate.

## Not in this milestone

Watching folders, summarising, sending anything anywhere, and editors' own integrations.

## Technical approach

An `NSServices` entry and a Quick Action, which need no permission; drop on the status item. ContextKit walks the selection, applies gitignore semantics (tested against git's own behaviour on fixtures), detects binary by content, and estimates tokens with a local heuristic calibrated against published tokenizer counts, labelled as an estimate.

## Permissions and privacy

None beyond what the user selects. Nothing leaves the Mac.

## Risks and open questions

- Token estimates vary by model; show one estimate and say it is approximate.

## Release gate

- Every item is done.
- Copying this repository's `apps/shot` folder gives every Swift file and none of `.build`, and the estimate is within 10 % of a published tokenizer's count.
