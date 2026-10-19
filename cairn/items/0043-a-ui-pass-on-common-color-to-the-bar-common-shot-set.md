---
id: 43
uid: 5584bcdf-7627-4370-b804-e52a24e43a9d
title: A UI pass on Common Color, to the bar Common Shot set
type: feature
status: blocked
milestone: color-0.1
assignee: Oddur Sigurdsson
claimed: 2026-10-18
created_by: common-color
created: 2026-10-18
updated: 2026-10-18
priority: p2
effort: m
area: color
---

## Problem

Common Color's menu was built before Common UI had a panel kit. The owner asked for a UI pass ("ui pass on common color picker tool") held to the bar Common Shot set. Today:
- The current colour doesn't lead.
- Seven format rows wrap their long Swift lines.
- Nothing confirms a copy.
- The keyboard can't reach the recent picks.

## Proposal

- Move the menu onto `MenuPanelHost`, with the current colour as the hero, the default format first and the other formats one step away.
- A brief confirmation after every copy, in the language of Shot's preview.
- Arrow keys, Return, number keys, Delete with Undo, and Escape.
- Settings tidied to the family standard.
- Light, dark, Increase Contrast, Reduce Motion and Transparency, and VoiceOver all checked.
- Logic in ColorKit with tests; anything reusable in CommonUI and on the design page.

## Acceptance criteria

- [x] Offscreen renders of every state (empty, one pick, full history with contrast, out of gamut, the confirmation, Settings), light and dark, before and after, looked at.
- [ ] Every copy is confirmed briefly and names the format; Escape from the loupe leaves the clipboard and history untouched.
- [ ] The panel works from the keyboard: arrows through recent picks, Return copies in the default format, 1–7 copy a format, Delete removes a pick with Undo, Escape closes.
- [ ] VoiceOver reads the colour, its values and the contrast verdict as sentences.
- [x] `scripts/task check color kit site` passes and AppContract holds.

## 2026-10-18

Done: the menu became a MenuPanelHost panel. Hero (64 pt swatch, hex, family and gamut), one 'Copy as <format> ↩' row, and the other six behind All Formats (remembered, keys 1-7), cut at the tail rather than wrapping. Recent uses SectionHeader with a count and Clear; swatches are ringed when selected and washed on hover; the context menu has Copy as / Copy As / Remove; Delete removes with Undo. Contrast leads with the ratio and a verdict ('Large text only') above calmer AA/AAA marks. New CommonUI ConfirmationHost/ConfirmationCard (on the design page, DesignRender redrawn) confirms every copy beside the pointer for 1.4 s, announced to VoiceOver, with no movement under Reduce Motion. Settings: Shortcut, then Copying (Copy as, Show what was copied), then General and Common Tools, as Shot lays its out.

## 2026-10-18

Left out, and why. Reordering recent picks: the order is recency, and dragging would fight it. Pinning favourites: palettes are out of scope for color-0.1. A tinted menu bar icon: a white or pale pick vanishes on a light menu bar, and a non-template image loses the system's tinting. Logic in ColorKit with tests: Describe.swift (family words from OKLCH, spoken strings, contrast verdict), GridMove, ColorFormat.key, History.remove/restore. Renders: '--snapshot <folder>' from the built bundle draws panel empty/one/full/formats/gamut, the confirmation, and Settings, light and dark, plus Increase Contrast versions of three. SwiftUI's colorSchemeContrast can't be forced offscreen, so the stronger hairlines under Increase Contrast are checked by reading the code only.

## 2026-10-18

Waiting on hands-on checks (no synthetic events here), so criteria 2-4 stay open: (2) pick, then copy from the panel, and see the card each time, with Escape from the loupe showing nothing; (3) open the panel, then use the arrows, Return, 1-7, Delete and ⌘Z, and Escape; (4) VoiceOver on the hero, a format row, a swatch and the contrast card.
