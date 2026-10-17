# Working in this repository

Common Tools is a family of small, native macOS apps, built here as one repository: each app under `apps/<slug>/` (Swift, AppKit plus SwiftUI, no package dependencies), what they share in `packages/CommonKit/`, and the website in `site/`. `apps.json` names every app with what differs between them. Each app has its own `CLAUDE.md` with what is specific to it; this file is the contract for all of them.

## The seam

Do all automation through `scripts/task`. CI and the git hooks call nothing else.

```sh
scripts/task <verb> [area ...] [--changed] [--filter=<test>]
```

Verbs: `fmt`, `fmt:check`, `lint` (format, then a build with warnings as errors), `test`, `build` (a universal, signed `build/<app>/<Name>.app`), `package` (`dist/<app>/`, what a release publishes), `run` (build, quit the running copy, open the new one), `check` (lint + test + build). Areas: `site`, `kit`, or an app's slug; none means all, `--changed` means what differs from `origin/main`, and CommonKit changes count for every app. CI runs `check` on the changed areas of a pull request and on everything for `main`.

## Workflow

- Never commit to `main`. It only moves forward when a pull request is merged; the `pre-push` hook and branch protection both enforce this.
- One unit of work gets one worktree, one branch, and one pull request: `scripts/agent start <type>/<slug>`, then work in the printed path and finish with `scripts/agent ship "<type>(scope): subject" "<why>" --body-file <pr.md>`, where the body states the problem, the approach, and where a reviewer should be sceptical. It commits, checks what changed, opens the pull request with auto-merge, keeps it rebased while CI runs, and cleans up after the merge. If it stops on a failed check or a conflict, fix the cause and run it again.
- Branch types: `feat fix chore docs perf refactor test`. The branch's first commit names the pull request and the squash commit on `main`. Scope commits and branches to one area where you can: `feat(bar): …`, `fix(site): …`, `refactor(kit): …`.
- Never use `--no-verify`.
- User-facing changes to an app go under `## [Unreleased]` in `apps/<slug>/CHANGELOG.md` in the same pull request. The site shows each release's section as "What's new".
- Release one app with `scripts/release <slug> <version>`; it tags `<slug>-v<version>` from the merged version bump. Never tag by hand.
- Several agents work here at once, one per app, each in its own worktree. Stay inside your area unless the change is shared; a change to `packages/CommonKit` or `shared/` affects every app, so say so in the pull request.

## Commits

Conventional Commits: `type(scope): subject`. Write the subject in the imperative, at most 72 characters, with no trailing period. The body says why. Never add assistant or tool attribution: no co-author trailers, no "generated with" footers. The `commit-msg` hook rejects them.

## Code

- Every app keeps its bundle identifier, executable name, status-item autosave names, and preference keys forever, so existing installs keep their settings, positions, and permission grants. Only user-visible names change.
- Every reading an app shows comes from a public, unprivileged API. Nothing leaves the Mac: no network, no analytics, no account.
- Settings follow one layout: the app's own sections first, then **General** starting with "Open at login", then `CommonToolsSection()` from CommonKit last. Labels are sentence case, section headers Title Case.
- The family list (`CommonTool.all` in CommonKit) and the icons in `shared/CommonTools/` are what every app's Settings shows. Adding an app: `apps.json`, its `apps/<slug>/`, `CommonTool.all`, `scripts/make-icon <slug>`, and its page in `site/`.
- Icons are drawn by `scripts/make-icon <slug>`: the body in `shared/icon-lib.swift`, the app's glyph in `apps/<slug>/icon.swift`.
- `scripts/dev-cert` makes the shared "Common Tools Development" signing identity and resets the permission grants of the apps that need any (`PERMISSIONS` in `apps.json`). Builds sign with it when it's valid and ad-hoc otherwise.
