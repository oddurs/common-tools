---
id: 66
uid: 912ba883-994b-4770-a5b2-60fcaa33d81a
title: Give every app its own colour, and the family a mark
type: feature
status: done
created: 2026-10-20
updated: 2026-10-20
closed_at: 2026-10-20
priority: p2
area: repo
---

## Problem

The owner: "make the icons a spread of colors, create a color system that gives each app its unique flare. consistent icons", "make common color icon better", and "common tools needs a minimalist logo too, but still slightly more branded". Every icon shared one blue body, so the family read as one app.

## Proposal

A `brand` group in `packages/common-ui/tokens.json`: one OKLCH ramp of lightness and chroma, with a hue per app. `build.mjs` renders it for the site and for `scripts/make-icon`. Common Color takes the spectrum, and its glyph becomes the system sampler's loupe. A "C" of the seven hues is the family mark.

## Acceptance criteria

- [x] Each app's icon body takes its hue from the tokens, and its glyph's shadows take the app's deep tone.
- [x] Common Color's icon is a loupe over the spectrum.
- [x] The site gets `--brand-<app>` colours, with a text colour held to AA in both appearances.
- [x] The family mark is generated from the same tokens, and shows in the site's header and as the favicon.
