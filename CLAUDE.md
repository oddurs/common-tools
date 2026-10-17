# Working in this repository

Common Tools is a family of small, native macOS apps, built here as one repository: each app under `apps/<slug>/` (Swift, AppKit plus SwiftUI, no package dependencies), what they share in `packages/CommonKit/`, and the website in `site/`. `apps.json` names every app with what differs between them. Each app has its own `CLAUDE.md` with what is specific to it; this file is the contract for all of them.

## The seam

Do all automation through `scripts/task`. CI and the git hooks call nothing else.

```sh
scripts/task <verb> [area ...] [--changed] [--filter=<test>]
```

Verbs: `fmt`, `fmt:check`, `lint` (format, then a build with warnings as errors), `test`, `build` (a universal, signed `build/<app>/<Name>.app`), `package` (`dist/<app>/`, what a release publishes), `run` (build, quit the running copy, open the new one), `smoke` (launch the built app and fail if it quits within five seconds), `cover` (line coverage of a Swift area), `check` (lint + test + build). Areas: `site`, `kit`, or an app's slug; none means all, `--changed` means what differs from `origin/main`, and CommonKit changes count for every app. CI runs `check` and then `smoke` on the changed areas of a pull request and on everything for `main`.

## Tests

- Swift Testing only (`@Test`, `#expect`), no XCTest. An app's library target (`<Name>Kit`) holds the logic and carries the suite; the app target keeps only what needs AppKit.
- Every app has a `ContractTests.swift` with one test that runs `AppContract` from CommonTesting (`packages/CommonKit/Sources/CommonTesting/`): `apps.json`, `CommonTool.all` and `Info.plist` agree, and what the build copies into the bundle exists. Never write bundle or Info.plist tests by hand; a rule every app should keep goes in `AppContract`.
- Performance tests are regression gates, not benchmarks: `Benchmark.microseconds` from CommonTesting in a `@Suite(.serialized)`, budgets about ten times a quiet M-series measurement, so a busy CI runner can't fail them.
- A test finishes in well under a second unless it must ask the system (Keys' spell checker). Nothing reaches the network, and nothing depends on which apps or layouts this Mac has unless that is what the test is about.
- `scripts/task test <area> --filter=<Suite or test>` runs one. `scripts/task cover <area>` prints line coverage. `scripts/task smoke <app>` launches the built app for five seconds; CI runs it after `check`, and `check` itself never launches anything, so it is safe while the app is running.
- A bug fix arrives with the test that would have caught it, in the suite nearest the code.

## Workflow

- Never commit to `main`. It only moves forward when a pull request is merged; the `pre-push` hook and branch protection both enforce this.
- One unit of work gets one worktree, one branch, and one pull request: `scripts/agent start <type>/<slug>`, then work in the printed path and finish with `scripts/agent ship "<type>(scope): subject" "<why>" --body-file <pr.md>`, where the body states the problem, the approach, and where a reviewer should be sceptical. It commits, checks what changed, opens the pull request with auto-merge, keeps it rebased while CI runs, and cleans up after the merge. If it stops on a failed check or a conflict, fix the cause and run it again.
- Branch types: `feat fix chore docs perf refactor test`. The branch's first commit names the pull request and the squash commit on `main`. Scope commits and branches to one area where you can: `feat(bar): …`, `fix(site): …`, `refactor(kit): …`.
- Never use `--no-verify`.
- User-facing changes to an app go under `## [Unreleased]` in `apps/<slug>/CHANGELOG.md` in the same pull request. The site shows each release's section as "What's new".
- Release one app with `scripts/release <slug> <version>`; it tags `<slug>-v<version>` from the merged version bump. Never tag by hand. The Release workflow publishes the zip and disk image (`scripts/dmg`), notarizes when the secrets exist (`scripts/notarize`, `docs/signing.md`), and writes the Homebrew cask (`scripts/cask`, `docs/install.md`).
- Several agents work here at once, one per app, each in its own worktree. Stay inside your area unless the change is shared; a change to `packages/CommonKit` or `shared/` affects every app, so say so in the pull request.

## Commits

Conventional Commits: `type(scope): subject`. Write the subject in the imperative, at most 72 characters, with no trailing period. The body says why. Never add assistant or tool attribution: no co-author trailers, no "generated with" footers. The `commit-msg` hook rejects them.

## Code

- Every app keeps its bundle identifier, executable name, status-item autosave names, and preference keys forever, so existing installs keep their settings, positions, and permission grants. Only user-visible names change.
- Every reading an app shows comes from a public, unprivileged API. Nothing leaves the Mac: no network, no analytics, no account. The one exception is CommonKit's `UpdateCheck`: off until the user turns it on in Settings, then a plain GET of the public release list with nothing about the Mac in it (`docs/first-run.md`).
- First run is CommonKit's `Welcome` window, driven by data the app passes (`docs/first-run.md`); nothing app-specific goes into CommonKit.
- Settings follow one layout: the app's own sections first, then **General** starting with "Open at login", then `CommonToolsSection()` from CommonKit last. Labels are sentence case, section headers Title Case. CommonKit's `CommonUI` product has the pieces (`import CommonUI`): `SettingsWindowHost`, `.settingsForm()`, `OpenAtLoginToggle`, `SettingsFootnote`, `LabeledRow`, `Card`, `IconBadge`.
- Common UI: colours, spacing, radii, and motion come from `packages/common-ui/tokens.json`, rendered into `Tokens.swift` and the site's `tokens.css` by `node packages/common-ui/build.mjs`; tests fail when an output is stale. In an app, use the system text styles and controls, and a token only where macOS has nothing (see `packages/common-ui/README.md`).
- The family list (`CommonTool.all` in CommonKit) and the icons in `shared/CommonTools/` are what every app's Settings shows. Adding an app: `apps.json`, its `apps/<slug>/`, `CommonTool.all`, `scripts/make-icon <slug>`, and its page in `site/`.
- Icons are drawn by `scripts/make-icon <slug>`: the body in `shared/icon-lib.swift`, the app's glyph in `apps/<slug>/icon.swift`.
- `scripts/dev-cert` makes the shared "Common Tools Development" signing identity and resets the permission grants of the apps that need any (`PERMISSIONS` in `apps.json`). Builds sign with it when it's valid and ad-hoc otherwise.
