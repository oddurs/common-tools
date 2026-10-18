---
id: 31
uid: 3a06195f-d049-4435-ad8e-35b2793a43db
title: Copy a colour in the format you write, converted correctly
type: feature
status: done
milestone: color-0.1
assignee: Oddur Sigurdsson
depends_on:
- 29
- 30
created: 2026-10-17
updated: 2026-10-18
closed_at: 2026-10-18
priority: p2
effort: m
area: color
---

## Problem

A colour copied in the wrong space looks wrong in the browser and nobody knows why.

## Proposal

ColorKit formats: hex, rgb(), hsl(), oklch(), color(display-p3), SwiftUI Color, NSColor, with correct sRGB/P3 conversion and out-of-gamut values flagged. A default format in Settings; every format one click away in the menu.

## Acceptance criteria

- [x] ColorKit tests match reference conversions for sRGB, P3 and out-of-gamut colours.
- [x] Each format pastes as valid code in its language (CSS validates, Swift compiles).

## 2026-10-18

Claimed with --force alongside 30: all three of 30-32 land in one pull request (feat/color-picking), since the formats and history are what a pick feeds.

## 2026-10-18

Formats: hex, rgb(r g b), hsl(h s% l%) to 0.1, oklch(L% C h) with L 2 places, C 4, h 2 and 'none' for a grey, color(display-p3 r g b) to 4 places, Color(.sRGB|.displayP3, red:green:blue:), NSColor(srgbRed:|displayP3Red: ..., alpha: 1). Swift forms use sRGB when the colour fits (numbers match the hex) and Display P3 otherwise. Numbers always use a point. Out of gamut: a colour more than one 8-bit step outside a space is flagged (ColorFormat.isExact false, a triangle in the menu); its sRGB/P3 text is CSS Color 4 gamut mapping (OKLCH chroma reduction, JND 0.02), never a silent clip.

## 2026-10-18

Evidence: ColorKit tests pass against CSS Color 4's OKLCH for #f00/#0f0/#00f (1e-5), Ottosson's XYZ->OKLab table (his 3 places), CSS's rational sRGB and P3 matrices (1e-12), ColorSync P3<->sRGB on a 7^3 grid (0.0005; ColorSync's quantised profile differs from the exact maths by up to 0.0004), rebeccapurple = hsl(270 50% 40%). CSS validity: 35 strings (5 CSS formats x 7 colours incl. P3, beyond-P3, white, black, grey) all accepted by WebKit's CSS.supports('color', ...) in an offscreen WKWebView; 'rgb(1 2)' rejected as a control. Swift: theSwiftFormatsCompile holds the emitted Swift and AppKit forms as code, so the suite wouldn't build otherwise.

## Result

ColorKit converts sRGB, Display P3 and OKLCH correctly and writes seven formats that paste as valid CSS and Swift; out-of-gamut colours are flagged and gamut-mapped, never silently clipped. Settings picks the default; the menu copies any.
