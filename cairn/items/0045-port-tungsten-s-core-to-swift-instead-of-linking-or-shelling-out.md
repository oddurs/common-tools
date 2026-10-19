---
id: 45
uid: 4455101b-5a8a-43c5-80c1-471d7ea75e3b
title: Port tungsten's core to Swift instead of linking or shelling out
type: docs
status: done
milestone: command-quantities
created: 2026-10-18
updated: 2026-10-18
priority: p1
area: command
effort: s
---

## Decided: a Swift port, kept honest by tungsten's data and test corpus

Four options were weighed for putting tungsten's answers in Common Command:

| Option | Why not, or why |
| --- | --- |
| Bundle the `tungsten` binary and spawn it per query | 5–10 ms process start per keystroke, a second signed binary, and a JSON output tungsten does not have yet |
| Link the Rust crates through a C ABI, built in CI | Rust in every Command build and CI run, undoing the CI speed work, and an exception to "no package dependencies" |
| Link a prebuilt static library published by tungsten | No Rust in our CI, but a binary blob in the repository and the same dependency exception |
| **Port the core to Swift** | Pure Swift, the family's rules intact, the user's locale handled natively, debuggable in the same tools; the cost is a second implementation |

The owner chose the port. The cost, drift between two implementations, is paid down by generating the data from tungsten's TOML and by running tungsten's own query corpus as the conformance suite (items in this milestone).

## Revisit when

tungsten's language grows faster than the port can follow, or a divergence the conformance suite reports cannot be resolved without copying Rust line by line; then reconsider the prebuilt library.

## Acceptance criteria

- [x] The choice, its evidence, and its consequences are recorded.
