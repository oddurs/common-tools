# Common Bar

[![CI](https://github.com/oddurs/common-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/oddurs/common-tools/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Keep the menu bar tidy: the icons you rarely use wait in a folder. **[oddurs.github.io/common-tools/bar](https://oddurs.github.io/common-tools/bar/)**

- **One folder, More.** Every icon left of it stays off-screen until you open it from More. Hidden icons never pile up under the notch or behind the app's menus, so nothing reshuffles.
- **Each icon by its app.** Click More for a list of the icons in it, each with its app's icon and name.
- **Opened from there.** Choose one, and Common Bar brings it on screen just long enough to open its menu, then puts it back.
- **A small Settings window.** Accessibility, Open at login, and an optional update check.

Free forever and open source under the MIT licence. Private: no analytics, no crash reports, no account; nothing you do is ever reported. No network access unless you turn on the update check.

**Permissions.** None to tidy the menu bar. The first time you open More, Common Bar asks for Accessibility, to see which app each icon belongs to and open it; until then More says so, and how many icons are in it.

## Install

Requires macOS 14 or later.

1. Download [CommonBar.zip](https://oddurs.github.io/common-tools/bar/) from the latest release, unzip it, and move **Common Bar** to Applications.
2. Open it. The build is signed but not notarized, so the first time macOS will say it can't verify the developer. Go to **System Settings › Privacy & Security** and click **Open Anyway**. Alternatively, run:

   ```sh
   xattr -dr com.apple.quarantine "/Applications/Common Bar.app"
   ```

3. Right-click the More folder, choose **Settings…**, and turn on **Open at login**.

## Usage

- **Tidy:** open Common Bar. Every icon left of the More folder moves off-screen and stays there. Icons right of it, and the system's own, stay in the menu bar.
- **Reach a hidden icon:** click More and choose it. The icon comes on screen, its menu or panel opens, and once that closes the icon goes back. The icon nearest More opens right beside it; one further along opens where it lands, under the notch or behind the app's menus, with the icons between it and More kept out of sight.
- **What stays in the menu bar:** the icons right of More, and the system's own. Each is where this version found it: icons you had showing stay, icons you had hidden are in More. macOS's own ⌘-drag still moves the icons in the menu bar among themselves.
- **Menu:** right-click (or Control-click) More for **Settings…** and **Quit Common Bar**.

**Settings** opens from that menu (⌘,) or by opening Common Bar again while it runs:

- **Folders:** whether Accessibility is allowed, with a button to System Settings when it isn't.
- **General:** **Open at login**, and the update check.
- **Common Tools:** the other Common Tools apps, with a button to open or get each one, and the installed version of Common Bar.

Without Accessibility, More can't tell which app an icon belongs to: on macOS 26 every menu bar icon's window belongs to Control Center, whichever app made it. Accessibility names each one's app, and opens it.

More in the [documentation](https://oddurs.github.io/common-tools/bar/docs/).

## Build from source

The Command Line Tools are enough; Xcode is not required.

```sh
scripts/task build bar                          # universal build → build/bar/Common Bar.app
mv "build/bar/Common Bar.app" /Applications/
```

## Development

Common Bar lives in `apps/bar/` of [oddurs/common-tools](https://github.com/oddurs/common-tools), the monorepo for every Common Tools app, and shares [CommonKit](../../packages/CommonKit) with them. From the repository root:

```sh
scripts/setup                     # once: wire the git hooks
scripts/dev-cert                  # optional, once: a stable signing identity, so permissions survive rebuilds
scripts/task run bar              # build, quit the running copy, open the new one
scripts/task check bar            # lint + test + build, what CI runs for this app
scripts/task test bar --filter=X  # only the tests whose name matches
```

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for the workflow: `scripts/agent start`, `scripts/agent ship`, and `scripts/release bar <version>`.

The app was called Reasonal before 0.1.0. The executable, bundle identifier, and preference keys keep that name so an existing install keeps its item positions and settings.

## Licence

MIT. See [LICENSE](../../LICENSE).
