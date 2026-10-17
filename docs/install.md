# How the apps are installed

The family's promise, which the Welcome window states in the same words. Completely free, forever: no trial, no subscription, no paid tier. Open source under MIT: every line is on GitHub. Private: no analytics, no crash reports, no account. Nothing you do is ever reported. The only network request is the update check, off until you turn it on, which asks GitHub for the latest version and sends nothing about you.

Every release of an app publishes, under the tag `<slug>-v<version>`:

| File | Made by | For |
| --- | --- | --- |
| `<Asset>.zip` | `scripts/task package`, with `ditto` | the Download button, the install script, and the Homebrew cask |
| `<Asset>.dmg` | `scripts/dmg`, called by `package` | people who download by hand: the app and an Applications link in one Finder window |
| `<tool>.zip` | `package`, for apps with command-line tools (`TOOLS` in `apps.json`) | the CLI download |
| `*.sha256` | `package` | checking a download: `shasum -a 256 -c CommonBar.zip.sha256` |

Three ways in, all on the site's Get started and the docs' Install sections:

1. **Download** the zip (or the disk image, once a release has one), move the app to Applications, open it, and click **Open Anyway** in Privacy & Security. The site shows the disk image only when the latest release has one, and the Homebrew line only when the tap has the app's cask; `site/src/lib/releases.ts` checks both at build time, so the pages never claim what doesn't exist.
2. **Homebrew**: `brew install --cask oddurs/common-tools/common-bar`. The tap is [oddurs/homebrew-common-tools](https://github.com/oddurs/homebrew-common-tools); its casks remove the quarantine flag after install, so there's no Open Anyway step, and `brew upgrade` keeps the app current. The fully qualified name trusts just that cask, which is what Homebrew 6+ asks for.
3. **One line**: `curl -fsSL https://oddurs.github.io/common-tools/install.sh | sh -s -- stats bar`. The script is `site/static/install.sh`. It resolves each app's latest release the way the site does (the monorepo's newest `<slug>-v*` tag, else the old repository's latest release), downloads the zip and its checksum, verifies, clears quarantine, quits a running copy, replaces the one in Applications, and opens it. No arguments lists the apps; `all` installs every released one. `COMMON_TOOLS_DIR` installs elsewhere.

## The cask

`scripts/cask <app> <version> [--push] [<download base>]` renders an app's cask from `apps.json` and the family list, with the checksum read from the release's `.sha256`, and with `--push` commits it to the tap. The Release workflow runs it after publishing, so a cask follows every release.

That step needs a token that can write to the tap, which only the owner can make:

1. <https://github.com/settings/personal-access-tokens/new>: a fine-grained token, repository access **Only select repositories › oddurs/homebrew-common-tools**, permissions **Contents: Read and write**. Expiry as long as allowed; note the date.
2. `gh secret set TAP_TOKEN --repo oddurs/common-tools` and paste it.

Without the secret the workflow prints a warning and the release still goes out; run `scripts/cask bar 0.5.0 --push` by hand to catch the tap up.

## Adding an app's first release

Nothing extra: the Release workflow publishes the zip and disk image and writes the cask; the site picks up the release, the disk image, and the cask on its next build; and `install.sh` resolves the tag. Only the table at the top of `site/static/install.sh` needs the new app's row, and `site/src/lib/tools.test.ts` fails until it has it.
