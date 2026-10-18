# Common Color

[![CI](https://github.com/oddurs/common-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/oddurs/common-tools/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Free forever and open source under the MIT licence. Private: no analytics, no crash reports, no account; nothing you do is ever reported, and nothing leaves your Mac. No permission prompts: it needs none.

Pick a colour from anywhere on screen and paste it as code. Press ⌃⇧⌘C, click any pixel, and the colour is on the clipboard in the format you write: hex, CSS, SwiftUI or AppKit, converted correctly from the display's colour space. **[oddurs.github.io/common-tools/color](https://oddurs.github.io/common-tools/color/)**

![The menu in light and dark](docs/menu.png)

- **The system's own loupe.** Picking uses macOS's colour sampler, the magnifier the system colour panel uses, so Common Color reads the one pixel you click and never sees your screen. That is why it needs no Screen Recording permission.
- **Every format, one click each.** Hex, `rgb()`, `hsl()`, `oklch()`, `color(display-p3 …)`, SwiftUI `Color(…)` and AppKit `NSColor(…)`. A pick is copied in the one you choose in Settings; the menu has the rest.
- **Converted correctly.** sRGB and Display P3 with the sRGB transfer curve both share, matrices derived from the published primaries, and OKLab and OKLCH by Björn Ottosson's matrices. Details under [Colour science](#colour-science).
- **Never silently clipped.** A colour sRGB can't hold, such as a vivid green on a P3 display, is marked. The sRGB formats give the nearest colour sRGB can show, mapped the way CSS Color 4 specifies so the hue stays put; the others are exact.
- **The last 12 picks.** Swatches in the menu, kept across launches. Click one to make it current and copy it again; **Clear** forgets them.
- **Contrast between the last two.** The WCAG 2 ratio, and whether it passes AA and AAA for normal and large text.

## Install

Requires macOS 14 or later.

1. Download **CommonColor.zip** from the [releases](https://github.com/oddurs/common-tools/releases?q=color-v), unzip it, and move **Common Color** to Applications.
2. Open it. The build is signed but not notarized, so the first time macOS will say it can't verify the developer. Go to **System Settings › Privacy & Security** and click **Open Anyway**. Alternatively, run:

   ```sh
   xattr -dr com.apple.quarantine "/Applications/Common Color.app"
   ```

3. Turn on **Open at login** in the Welcome window, or later in **Settings…**.

## Usage

Press **⌃⇧⌘C**, or choose **Pick Color** from the eyedropper in the menu bar. The loupe follows the pointer; click to pick, or press Escape to cancel and leave the clipboard as it was.

The menu shows the current colour with a swatch, then a row for each format: click a row to copy it. A check marks the format a pick copies; a warning triangle marks a format that can't hold the colour exactly. Under it, **Recent** holds the last 12 picks; under that, **Contrast** compares the newest pick (as text) with the one before (as background). **Settings…** (⌘,) and **Quit** (⌘Q) are at the bottom.

Settings has three sections. **Picking**: the shortcut (click it and press a new one; Delete restores ⌃⇧⌘C) and **Copy as**, the format a pick copies. **General**: **Open at login** and the optional update check. **Common Tools**: the other apps in the family.

### Colour science

`ColorKit` holds every colour as linear-light sRGB without bounds, so a colour outside sRGB keeps its exact value as components below 0 or above 1. Each format is derived from that.

| Step | How |
| --- | --- |
| From the screen | `NSColorSampler` returns the pixel in the display's colour space. ColorSync converts it to extended sRGB, which clips nothing, to find where it lies; inside Display P3, which covers every Apple display, the value is ColorSync's Display P3 components. |
| sRGB and Display P3 | The sRGB transfer curve (IEC 61966-2-1), which Display P3 shares, extended to negative values by symmetry. Matrices derived from each space's published primaries and the D65 white (0.3127, 0.3290); they equal CSS Color 4's to the last place. |
| OKLab, OKLCH | Björn Ottosson's matrices for linear sRGB. A grey's hue is written `none`, as CSS does. |
| Out of gamut | A colour more than one 8-bit step outside a space is flagged for the formats in that space. Their text is the nearest colour by CSS Color 4's gamut mapping: reduce OKLCH chroma at constant lightness and hue until clipping moves it less than a just-noticeable difference. |
| Contrast | WCAG 2: (L1 + 0.05) / (L2 + 0.05) with L the relative luminance (Y of XYZ). Compared unrounded; shown truncated to two places, so 4.478 reads 4.47:1 and fails AA for normal text. |

`SwiftUI` and `AppKit` name their colour space: a colour sRGB holds is written in sRGB, where its numbers match the hex, and anything wider in Display P3.

The tests check these against reference values: CSS Color 4's OKLCH figures for the sRGB primaries, Ottosson's published table, ColorSync's conversions between sRGB and Display P3 on a grid of colours, and published WCAG ratios such as #777 on white (4.48) and #767676 on white (4.54).

## Build from source

The Command Line Tools are enough; Xcode is not required.

```sh
scripts/task build color  # universal build → build/color/Common Color.app
```

## Development

Common Color lives in `apps/color/` of [oddurs/common-tools](https://github.com/oddurs/common-tools), the monorepo for every Common Tools app, and shares [CommonKit](../../packages/CommonKit) with them. From the repository root:

```sh
scripts/setup                       # once: wire the git hooks
scripts/task run color              # build, quit the running copy, open the new one
scripts/task check color            # lint + test + build, what CI runs for this app
scripts/task test color --filter=X  # only the tests whose name matches
```

`swift build && .build/debug/CommonColor --snapshot out.png` renders the menu's panel in light and dark, in three states (a full history, a colour outside sRGB, no picks yet), to `out.png`. The image above was made this way.

Layout:

- `Sources/ColorKit`: colour spaces, OKLab, gamut mapping, the formats, contrast, and the history. No UI state, so it is tested on its own.
- `Sources/CommonColor`: the status item, menu, picking, and Settings.
- `Tests/ColorKitTests`: conversions, formats, contrast, history, and reading a colour from AppKit.

## Licence

MIT. See [LICENSE](../../LICENSE).
