# Common Glyph

[![CI](https://github.com/oddurs/common-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/oddurs/common-tools/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Put your own images in the menu bar: a character, a tattoo design, a sticker, an emoji, or a word. As many as you like.

- **As many glyphs as you want.** Each is its own menu bar item with its own image and look. Add, duplicate, hide, and delete them in Settings.
- **Any image, or any text.** PNG, JPEG, HEIC, WebP, GIF, PDF, or SVG. Or type an emoji, a symbol, or a kaomoji such as ᓚᘏᗢ.
- **Looks like it belongs.** **Silhouette** and **Ink** tint the glyph to match the menu bar, light or dark, the way the system's own icons are. **Colour** keeps the image as it is.
- **An editor for each glyph.** Crop by dragging a box over the image, rotate, flip, clear a plain background, or lift the subject out of a photo with Vision. A light and a dark menu bar preview every change at real size.
- **Animated GIFs play.** Animations stop while the display sleeps, and don't play when Reduce Motion is on.
- **Drop it on the menu bar.** Drag an image from Finder onto a glyph to replace its image, or paste one from the glyph's menu.
- **Starts where you can see it.** A new glyph appears beside the clock, right of the divider a menu bar manager such as Common Bar uses, instead of off screen at the far left. If one still can't be seen, Settings says so.

Free forever and open source under the MIT licence. Private: no analytics, no crash reports, no account; nothing you do is ever reported. No network access, no permission prompts.

## Install

Requires macOS 14 or later.

1. Download [CommonGlyph.zip](https://oddurs.github.io/common-tools/glyph/) from the latest release, unzip it, and move **Common Glyph** to Applications.
2. Open it. The build is signed but not notarized, so the first time macOS will say it can't verify the developer. Go to **System Settings › Privacy & Security** and click **Open Anyway**. Alternatively, run:

   ```sh
   xattr -dr com.apple.quarantine "/Applications/Common Glyph.app"
   ```

3. Turn on **Open at login** in the Welcome window, or later in **Settings…** from a glyph's menu.

## Usage

The first glyph is a four-pointed star, ✦. Click any glyph for its menu: a card showing the glyph and how it's made, then **Edit Glyph…**, **Choose Image…**, **Paste Image**, **New Glyph**, **Hide Glyph**, **Settings…** (⌘,), and **Quit Common Glyph**. Opening Common Glyph again while it runs also opens Settings. Hold ⌘ and drag a glyph to move it along the menu bar.

**Settings** starts with every glyph previewed in a light and a dark menu bar, with a note if any of them can't be seen. **Glyphs** lists them: the switch on each row shows or hides it, clicking a row opens its editor, and right-clicking a row duplicates or deletes it. **Add Glyph** makes a new one. One glyph always stays in the menu bar, so its menu stays in reach. **General** holds **Open at login**, and **Common Tools** lists the other apps in the family.

A glyph's editor opens as a sheet: its own preview, its **Name** and **Show in menu bar**, then **Source** and **Look**, with **Delete Glyph…**, **Duplicate**, and **Done** at the bottom. **Source** picks what it's drawn from:

- **Image:** choose, paste, or drop a file. Until one arrives, the glyph keeps showing its text. Drag inside the crop box to move it, drag a corner to resize it, and double-click it to take in the whole image again. The buttons beside **Paste** rotate a quarter turn clockwise, flip horizontally, and reset to the whole image the right way up. Each glyph keeps its own copy of its image, so the original can be moved or deleted.
- **Emoji or text:** type in the field, open **Emoji & Symbols** (⌃⌘Space) with the face button, or pick a suggestion. Typing an emoji over plain text switches to **Colour**, and plain text over an emoji switches back to **Silhouette**.

A glyph's image and its text each keep their own edits, so switching between them loses nothing.

**Look** decides how the glyph is drawn:

- **Style:** **Colour** keeps the image's colours. **Silhouette** draws its shape in the menu bar's colour. **Ink** keeps only its dark lines, which suits line art, tattoo flash, and scans. Raise or lower **Threshold** to keep more or less, and turn on **Use the light parts** for light lines on a dark image.
- **Background** (images only): **Keep** the image as it is, **Remove solid colour** for clip art or a drawing on white, or **Lift subject** for a photo. **Remove solid colour** clears the colour most corners share, working inwards from the edges, so enclosed areas of that colour, such as the whites of a character's eyes, stay. **Tolerance** sets how far a colour can stray and still be cleared.
- **Size:** from half to the full height of the menu bar. The glyph is trimmed to its visible pixels first, so it fills that height however much margin the image had. Very wide images are capped at 180 points.
- **Animate** (animated images only): play the animation or show its first frame.

## Build from source

The Command Line Tools are enough; Xcode is not required.

```sh
scripts/task build glyph                          # build for this Mac → build/glyph/Common Glyph.app
mv "build/glyph/Common Glyph.app" /Applications/
```

## Development

Common Glyph lives in `apps/glyph/` of [oddurs/common-tools](https://github.com/oddurs/common-tools), the monorepo for every Common Tools app, and shares [CommonKit](../../packages/CommonKit) with them. From the repository root:

```sh
scripts/setup                       # once: wire the git hooks
scripts/dev-cert                    # optional, once: a stable signing identity, so permissions survive rebuilds
scripts/task run glyph              # build, quit the running copy, open the new one
scripts/task check glyph            # lint + test + build, what CI runs for this app
scripts/task test glyph --filter=X  # only the tests whose name matches
```

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for the workflow: `scripts/agent start`, `scripts/agent ship`, and `scripts/release glyph <version>`.

## Licence

MIT. See [LICENSE](../../LICENSE).
