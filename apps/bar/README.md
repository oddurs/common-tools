# Common Bar

[![CI](https://github.com/oddurs/common-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/oddurs/common-tools/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Keep the menu bar tidy: the icons you rarely use wait in folders. **[oddurs.github.io/common-tools/bar](https://oddurs.github.io/common-tools/bar/)**

- **Folders.** Every icon left of your folders stays off-screen until you open it from one. Hidden icons never pile up under the notch or behind the app's menus, so nothing reshuffles. More holds whatever no other folder does; add your own in Settings.
- **Each icon by its app.** Click a folder for a list of its icons, each with its app's icon and name: other apps first, then Common Tools, then macOS's own, with a line between them.
- **Opened right there.** Choose one, and its menu opens where the folder's was: the icon itself, moved in beside the folder, or a copy of its menu.
- **A small Settings window.** Your folders and their icons, folder names, Accessibility, Open at login, and an optional update check.

Free forever and open source under the MIT licence. Private: no analytics, no crash reports, no account; nothing you do is ever reported. No network access unless you turn on the update check.

**Permissions.** None to tidy the menu bar. The first time you open a folder, Common Bar asks for Accessibility, to see which app each icon belongs to and open it; until then the folder says so, and how many icons wait in your folders.

## Install

Requires macOS 14 or later.

1. Download [CommonBar.zip](https://oddurs.github.io/common-tools/bar/) from the latest release, unzip it, and move **Common Bar** to Applications.
2. Open it. The build is signed but not notarized, so the first time macOS will say it can't verify the developer. Go to **System Settings › Privacy & Security** and click **Open Anyway**. Alternatively, run:

   ```sh
   xattr -dr com.apple.quarantine "/Applications/Common Bar.app"
   ```

3. Right-click the More folder, choose **Settings…**, and turn on **Open at login**.

## Usage

- **Tidy:** open Common Bar. Every icon left of your folders moves off-screen and stays there. Icons right of the divider, and the system's own, stay in the menu bar.
- **Reach a hidden icon:** click its folder and choose it. Its menu opens where the folder's was, one of three ways, depending on how far down the folder the icon is:
  - **Near the divider:** Common Bar brings the icon on screen, ⌘-drags it in beside the folder (the pointer hidden for a moment and put back where it was), and opens it. Once its menu or panel closes, the icon is dragged back to its place.
  - **Further along:** a drag can't start there, behind the app's menus, so Common Bar reads the icon's menu through Accessibility without showing it and opens a copy from the folder, headed by the icon's name. The item you choose is pressed in the real menu.
  - **Shows a panel or popover, not a menu** (Wi‑Fi, Battery): it opens wherever it comes on screen, which on a crowded notched display is under the notch or behind the app's menus.

  With **Open icons beside their folder** off, every icon opens wherever it comes on screen.
- **Organise:** in Settings › Folders, add folders, rename them, pick a symbol, move them left or right, and delete them; under **Icons in Folders**, pick each icon's folder. An icon is remembered by its app and its label, or its place among that app's icons, so it stays in its folder across launches.
- **What stays in the menu bar:** the icons right of the divider, and the system's own. Each is where this version found it: icons you had showing stay, icons you had hidden are in More. macOS's own ⌘-drag still moves the icons in the menu bar among themselves.
- **Menu:** right-click (or Control-click) a folder for **Settings…** and **Quit Common Bar**.

**Settings** opens from that menu (⌘,) or by opening Common Bar again while it runs:

- **Folders:** each folder's symbol and name, buttons to move it left or right or delete it (not More), **Add Folder**, and **Show folder names in the menu bar** (on to start with).
- **Icons in Folders:** every icon left of your folders, with the folder it's in.
- **Opening Icons:** **Open icons beside their folder** (on to start with), and whether Accessibility is allowed, with a button to System Settings when it isn't.
- **General:** **Open at login**, and the update check.
- **Common Tools:** the other Common Tools apps, with a button to open or get each one, and the installed version of Common Bar.

Without Accessibility, a folder can't tell which app an icon belongs to: on macOS 26 every menu bar icon's window belongs to Control Center, whichever app made it. Accessibility names each one's app, and opens it.

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
