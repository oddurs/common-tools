# Common Tools

[![CI](https://github.com/oddurs/common-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/oddurs/common-tools/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Small, native utilities for the Mac. Each does one thing and gets out of the way. **[oddurs.github.io/common-tools](https://oddurs.github.io/common-tools/)**

| App | Does | |
| --- | --- | --- |
| [Common Stats](apps/stats) | CPU, GPU, memory, network, disk, storage, and battery in the menu bar | [download](https://oddurs.github.io/common-tools/stats/) |
| [Common Keys](apps/keys) | Fixes words typed on the wrong keyboard layout | [download](https://oddurs.github.io/common-tools/keys/) |
| [Common Bar](apps/bar) | Tucks away the menu bar icons you rarely use | [download](https://oddurs.github.io/common-tools/bar/) |
| [Common Glyph](apps/glyph) | Your own images in the menu bar | in development |
| [Common Command](apps/command) | A small, fast launcher | in development |
| [Common Shot](apps/shot) | Screenshots straight to the clipboard | in development |
| [Common Battery](apps/battery) | The battery in the menu bar, done properly | in development |

**Free forever.** No trial, no subscription, no paid tier. **Open source** under the MIT licence: every line is here to read, build, and change. **Private:** no network access, no analytics, no crash reports, no account. Nothing you do is ever reported, and nothing leaves your Mac.

## Install

Download from an app's page, or from a terminal:

```sh
brew install --cask oddurs/common-tools/common-bar                               # Homebrew, from the oddurs/homebrew-common-tools tap
curl -fsSL https://oddurs.github.io/common-tools/install.sh | sh -s -- stats bar   # or one line; no names lists the apps
```

Both check the download against its published checksum and leave no "can't verify the developer" step. The builds are signed but not yet notarized; [docs/signing.md](docs/signing.md) is the path to a Developer ID, and [docs/install.md](docs/install.md) is how the pieces fit.

## This repository

Every app lives here, with its history, as a separate app bundle and a separate release:

- `apps/<slug>/`: one app, a Swift package of its own, with its `README.md`, `CHANGELOG.md`, and docs.
- `packages/CommonKit/`: what the apps share: the family list, the Common Tools section at the end of every app's Settings, and, as the `CommonUI` product, the Settings, card, and row primitives.
- `packages/common-ui/`: Common UI, the design system: the tokens both the apps and the site are drawn from, and the generator that renders them into CommonKit's `CommonUI` product and the site's CSS.
- `shared/`: the family icons every app bundles, and the shared icon body.
- `site/`: the website, which reads each app's latest release and CHANGELOG at build time.
- `apps.json`: what differs between apps: names, bundle identifiers, deployment target, extra command-line tools, permissions.

Releases are tagged `<slug>-v<version>` (for example `bar-v0.4.0`) and published with a stable asset name; the site links the latest one for each app.

## Development

```sh
scripts/setup             # once: wire the git hooks
scripts/dev-cert          # optional, once: a stable signing identity, so permissions survive rebuilds
scripts/agent doctor      # check tools and repository state
scripts/task run bar      # build Common Bar, quit the running copy, open the new one
scripts/task check bar    # lint + test + build one app, what CI runs for it
scripts/task check        # everything: the site, CommonKit, every app
```

| Command | Does |
| --- | --- |
| `scripts/task <verb> [area ...] [--changed]` | `fmt`, `fmt:check`, `lint`, `test`, `build`, `package`, `run`, `smoke`, `cover`, `check` for `site`, `kit`, or an app |
| `scripts/agent start <type>/<slug>` | new worktree and branch from `origin/main` |
| `scripts/agent ship "<type>(scope): subject"` | commit, check what changed, open the PR with auto-merge, wait for the merge, clean up |
| `scripts/agent pr` | check, push, open the PR with auto-merge, without waiting |
| `scripts/agent sync` | rebase onto `origin/main` |
| `scripts/agent done` | after a merge: remove the worktree and branch, update the main checkout |
| `scripts/agent list` | worktrees, branches, and pull request state |
| `scripts/release <app> <version>` | a release: dated notes, version bump, tag, published download, checked |
| `scripts/cask <app> <version> [--push]` | the app's Homebrew cask for that release; `--push` commits it to the tap |
| `scripts/dmg <Name.app> <out.dmg>` | the drag-to-Applications disk image `package` publishes beside the zip |
| `scripts/notarize <path ...>` | Developer ID signing and notarization when the secrets exist; a no-op otherwise |
| `scripts/make-icon <app>` | render an app's icon from `shared/icon-lib.swift` and its `icon.swift` |

See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow and [docs/testing.md](docs/testing.md) for what the tests cover and how to run one.

## Licence

MIT. See [LICENSE](LICENSE).
