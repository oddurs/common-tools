# Common Color

[![CI](https://github.com/oddurs/common-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/oddurs/common-tools/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Free forever and open source under the MIT licence. Private: no analytics, no crash reports, no account; nothing you do is ever reported, and nothing leaves your Mac. No permission prompts: it needs none.

Pick a colour from anywhere on screen and paste it as code: hex, CSS, SwiftUI or AppKit, converted correctly from the display's colour space. **[oddurs.github.io/common-tools/color](https://oddurs.github.io/common-tools/color/)**

**In development.** This is the app's start in the family: an eyedropper in the menu bar, the Welcome window, and Settings. Picking, the formats, recent picks and contrast are on the way, tracked as milestone `color-0.1` in [ROADMAP.md](../../ROADMAP.md).

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

Layout:

- `Sources/ColorKit`: colour spaces and conversions. No UI state, so it is tested on its own.
- `Sources/CommonColor`: the status item, menu, and Settings.
- `Tests/ColorKitTests`: conversions against CSS Color 4's matrices and ColorSync.

## Licence

MIT. See [LICENSE](../../LICENSE).
