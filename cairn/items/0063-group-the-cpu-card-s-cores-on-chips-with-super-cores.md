---
id: 63
uid: 1be7aa0c-a7d2-466b-9eaa-1515458db4d9
title: Group the CPU card's cores on chips with Super cores
type: bug
status: done
assignee: Oddur Sigurdsson
created: 2026-10-20
updated: 2026-10-20
closed_at: 2026-10-20
priority: p1
area: stats
effort: s
---

## What happens

On an M5 Pro the CPU card shows 15 ungrouped core bars with no cluster captions. The device tree tags the cores `P` and `M`, and `CPUTopology` only knows `E` and `P`, so it finds an unknown tag and gives up. Had it grouped them, it would have called the `P` cores "Performance", while macOS names them "Super" (`hw.perflevel0.name`) and the `M` cores "Performance".

## What should happen

The card groups cores by the kernel's performance levels and captions each group with the name the kernel gives it (`hw.perflevelN.name`), on M5 (Super and Performance) as on M1–M4 (Performance and Efficiency), without a table of letter tags.

## Reproduction

1. On an M5 Pro, open Common Stats' dropdown and look at the CPU card.

## Acceptance criteria

- [x] Cores are grouped and named from `hw.perflevelN`, not from hard-coded `cluster-type` letters
- [x] StatKit tests cover fixtures for M1–M4 (E/P) and the M5 Pro recorded on this Mac (P/M, Super/Performance), and failed before the fix
- [x] The snapshot of the CPU card on this M5 Pro shows a Super and a Performance group
- [x] `apps/stats/CHANGELOG.md` notes the fix under Unreleased

## 2026-10-20

Device tree on an M5 Pro: cluster-type M on logical cpus 0-9 (l2-cache-size 8 MB), P on 10-14 (16 MB). sysctl: hw.perflevel0 Super, 5 cpus, 16 MB L2; hw.perflevel1 Performance, 10 cpus, 8 MB L2. So the device tree's P is the kernel's Super level. Each cluster type is now matched to the one perflevel with its core count and L2 size; counts alone tie on M1/M2/M3 base (4+4) and the 12-core M3 Pro (6+6), and L2 breaks the tie. The old on-device test (currentMachineIsConsistentWithSysctl) already failed on this Mac on main.
