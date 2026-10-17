# Working in this repository

Common Battery is a native macOS menu bar battery indicator, a replacement for the system's, written in Swift (AppKit plus SwiftUI) with no package dependencies. It is part of the Common Tools family with Common Stats, Common Keys, Common Bar, Common Glyph, Common Command, and Common Shot.

## The seam

Do all automation through `scripts/task`. CI and the git hooks call nothing else.

```sh
scripts/task fmt       # format in place
scripts/task fmt:check # swift format lint --strict, format only
scripts/task lint      # fmt:check, then a debug build with warnings as errors
scripts/task test      # unit, accuracy, and performance tests
scripts/task build     # universal build/Common Battery.app
scripts/task check     # lint + test + build
```

## Workflow

- Never commit to `main`. It only moves forward when a pull request is merged; the `pre-push` hook and branch protection both enforce this.
- One unit of work gets one worktree, one branch, and one pull request: `scripts/agent start <type>/<slug>`, then work in the printed path and finish with `scripts/agent ship "<type>(scope): subject" "<why>" --body-file <pr.md>`, where the body states the problem, the approach, and where a reviewer should be sceptical.
- Branch types: `feat fix chore docs perf refactor test`.
- Run `scripts/task check` until it is green before opening a pull request. Never use `--no-verify`.

## Commits

Conventional Commits: `type(scope): subject`. Write the subject in the imperative, at most 72 characters, with no trailing period. The body says why. Never add assistant or tool attribution: no co-author trailers, no "generated with" footers. The `commit-msg` hook rejects them.

## Code

- `Sources/BatteryKit` holds every decision that can be made from plain values: decoding IOKit's dictionaries (`BatterySampler.reading`), formatting, the chart's history, when to notify (`AlertTracker`), and the menu bar renderer. A behaviour change goes here with a test first. `Sources/CommonBattery` is the app shell: status item, menu, notifications, and Settings.
- Accuracy comes first. Every reading comes from IOKit's power sources or the AppleSmartBattery registry entry, both public and unprivileged. A value that can't be read isn't shown; never show a made-up zero. Don't add private APIs, and don't show a figure that disagrees with System Settings without saying why (see "Not included" in the README).
- `TimeEstimator` replaces macOS's time to empty only after its scored error beats macOS's method, chooses its method once per stretch on battery, and moves what's shown by at most `drift` per minute. Keep all three properties. A change to the estimator or `DrainModel` must keep `beatsTheInstantEstimateOnSimulatedUse` passing on every seed without loosening its bounds; if a bound is wrong, derive the right one from the design and say why.
- Sampling is event driven: `IOPSNotificationCreateRunLoopSource` on a power-source change, a one-minute timer for the history, two seconds while the menu is open. Don't add polling.
- The menu bar image is a template image so macOS tints it, except while an alert colour (low, Low Power Mode) is showing. Widths come from the appearance and never from the reading. Dynamic colours in the alert ink must be system colours as they are (`secondaryLabelColor`), not `labelColor.withAlphaComponent`, which resolves once.
- `CommonTools.swift` is shared word for word across the Common Tools apps. Change it in all of them together.
- A bug fix comes with the test that would have caught it. Sampler changes need an accuracy test against a system tool where one exists (`pmset`, `ioreg`).
- Performance budgets are enforced in `PerformanceTests`. Don't loosen a budget to make a change pass.
- For visual review: `swift build && .build/debug/CommonBattery --snapshot out.png` and inspect `out.png` and `out-menu.png`. It renders offscreen, so no windows open.
- The app icon comes from `swift scripts/make-icon.swift`, which writes `Resources/AppIcon.icns`, `docs/icon.png`, and `Resources/CommonTools/battery.png`. Edit the script, not the images.
