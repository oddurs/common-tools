---
id: 65
uid: d433b85b-f725-49fe-959b-9d040cdfaf91
title: Never convert a correctly typed name the system lexicon knows
type: bug
status: done
assignee: Oddur Sigurdsson
claimed: 2026-10-20
created: 2026-10-20
updated: 2026-10-20
priority: p0
area: keys
effort: s
---

## What happens

On macOS 26.5, `PersonalTests.eagerCorrectionsCannotTeachFalseFixes` fails: after 500 corrections that push toward fixing, "David" typed on U.S. becomes "Вфмшв". English accepts "David" but lists nothing when asked to complete it, so `SystemLexicon.isWord` called it unknown. 22 of 30 common names and places behave the same way on this macOS.

## What should happen

A correctly typed name the system dictionary knows is a word, and is never converted.

## Acceptance criteria

- [x] A capitalised word that a strict dictionary accepts, but refuses in lower case, counts as a word even when completions don't list it.
- [x] Lenient dictionaries (any string passes) still need the word listed.
- [x] The replay gate passes on macOS 26.5, and the Keys suite passes.
