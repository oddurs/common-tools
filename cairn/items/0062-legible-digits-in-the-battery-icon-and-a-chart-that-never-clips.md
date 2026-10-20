---
id: 62
uid: 1fee3ffb-46f9-4183-9b75-5fe7a248d50f
title: Legible digits in the battery icon, and a chart that never clips
type: bug
status: done
assignee: Oddur Sigurdsson
created: 2026-10-20
updated: 2026-10-20
closed_at: 2026-10-20
priority: p1
area: battery
effort: s
---

## What happens

Seen in `CommonBattery --snapshot out.png` before Common Battery's first release:

1. Percentage in Icon in Low Power Mode: the digits are cut out of the yellow fill, so on a light menu bar the first "5" of "55" shows the pale bar through pale yellow and almost disappears. The plug in the plain icon has the same problem.
2. Percentage in Icon, on power: the plug touches the first digit at "80" and runs into the "1" of "100", and "100" runs into the end of the fill.
3. The menu's chart: a single sample near 100% draws its dot on the top-right rounded corner, where the clip cuts it away, so the chart looks empty.

## What should happen

- Over a template fill the digits knock out of the fill, as the system draws them; over a coloured fill they are drawn in black or white, whichever contrasts with that colour, in both appearances.
- The glyph and the number keep a fixed gap, fit inside the fill area at every level from 0 to 100, and are centred together.
- The chart's points are inset far enough that a dot stays whole at every corner.

## Reproduction

1. `scripts/task build battery && "build/battery/Common Battery.app/Contents/MacOS/CommonBattery" --snapshot out.png`
2. Look at the Percentage in Icon row (third) in `out.png` at 55% Low Power Mode, 80% and 100%, and at the first panel's chart in `out-menu.png`.

## Acceptance criteria

- [x] Tests in BatteryKit's suite that fail on the old renderer: glyph and number clearance for every percent, no holes cut in a coloured fill, AA contrast of the number on red and yellow in light and dark, and a chart dot inside the continuous rounded corners at every extreme.
- [x] Before and after renders of every style, state and level, light and dark, looked at.
- [x] `scripts/task check battery` passes.

## 2026-10-20

Root causes. (1) Every mark inside the body was cut out of the fill with destinationOut, which only works for a template fill: AppKit tints the fill in the bar's text colour, so the bar showing through always contrasts with it. Systemyellow on a light bar does not (about 1.5:1). Over a coloured fill the marks are now drawn in black or white, chosen by WCAG contrast against the fill as it resolves in the current appearance (black on both red and yellow, 5.9:1 and above). (2) The number was centred by its advance in whatever room the plug left: a 9 pt plug, a 0.5 pt gap, and "100" (17.6 pt of ink) don't fit in 29 pt. The glyph and the number's ink are now centred together with a 1.5 pt gap, and the plug is sized to fit beside "100" with 1 pt to spare at each end (about 5.3 pt tall, was 6). (3) The chart mapped level 1 to y 0 and now to the right edge, so a lone sample at 100% now drew its 2 pt dot centred on the 8 pt continuous corner. ChartFrame insets the plot by the radius less the dot's reach along the corner's diagonal, plus 1 pt of clear space: 5 pt for the 8 pt radius. Decided against copying iOS's bolt beside the battery: unverified for macOS, and it would change the item's width.
