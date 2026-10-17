# First run and update checks

Two pieces of CommonKit every app adopts; the lines below are all an app adds.

## The Welcome window

One window, the same in every app: the app's icon, what it does in a line, the permission it needs with a live check that turns green when the switch is flipped, an **Open at login** toggle, and the Common Tools family. Nothing in CommonKit knows which app it is; the app passes its data.

Three lines, in `applicationDidFinishLaunching`:

```swift
import CommonKit

Welcome.showIfNeeded(WelcomeInfo(
    line: "Fixes words typed on the wrong keyboard layout, for every keyboard macOS has.",
    permission: .accessibility(reason: "to see what you type and fix it")))
```

- `name` defaults to the bundle's display name; pass it only if that's wrong.
- `permission` is `.accessibility(reason:)`, `.screenRecording(reason:)`, or left out. The reason finishes the sentence "*App* needs *Permission* access …". Only Common Keys and Common Shot need one.
- **One welcome for the family.** The first family app to run on a Mac shows the whole window and records it in the shared defaults suite `io.github.oddurs.commontools` (key `welcomed`; the apps aren't sandboxed, so it's one file every app reads). A later app shows Welcome only when it needs a permission that isn't granted, and then only that permission (`WelcomeKind.decide`). An app that set its own `CommonKit.welcomed` before the suite existed counts as welcomed.
- **One window at a time.** Before it decides, an app takes `~/Library/Application Support/Common Tools/welcome.lock`, an exclusive `flock` on a file holding the owner's pid, and waits a second at a time while another app's Welcome is open. The kernel frees the lock when its owner exits, however it exits.
- **Nothing else opens on first launch.** No app opens its own Settings or raises a system prompt at launch. Anything that would, such as Common Battery asking to post notifications, goes in `showIfNeeded`'s `then`, which runs once Welcome closes, or at once when there's nothing to show.
- `Welcome.show(info)` shows the full window on demand, for a **Welcome…** menu item or a button in Settings.
- **The permission row** has **Open System Settings** (the system's own prompt, which puts the app in the pane's list, and the pane), **Reset and Ask Again** (`Permission.resetAndRequest()`: `tccutil reset <service> <this bundle id>`, then the prompt), and for Screen Recording **Quit and Reopen** (`Relaunch.now()`), with the sentence "If *App* is already on in System Settings, that switch belongs to an earlier copy." macOS keeps a grant for the signature it was given to, so a switch left by a copy signed differently shows on, doesn't apply, and stays wrong when flipped; only removing the record fixes it. Screen Recording also applies only after the app reopens. The window polls every second while open, so an Accessibility grant shows "Granted" without a relaunch.
- **Open at login** uses CommonKit's `LoginItem` (`SMAppService.mainApp`), the same wrapper behind `OpenAtLoginToggle` in Settings, so the two switches never disagree.
- The window is a hosting controller in a plain titled window, as `SettingsWindowHost` builds Settings, so its controls answer clicks and accessibility like any other window.
- Common Bar has its own animated how-to in the menu bar, beside Welcome.

To look at it without building an app:

```sh
cd packages/CommonKit/Demo
swift run welcome-demo                        # opens the window, as Common Keys would show it
swift run welcome-demo --screenshot out.png   # renders it to a file (the login toggle renders as a placeholder there)
swift run welcome-demo --screenshot out.png --permission   # the permission-only window a later app shows
```

## The update check

`UpdateCheck` asks GitHub for the app's latest release at most once a day, compares versions, and sets `available` when there's a newer one. It's **off until the user turns it on**, and the request is one unauthenticated GET of the public release list with a fixed `User-Agent: common-tools`: no identifier, no cookie, nothing about the Mac. No Sparkle, no download, no install; the app shows a line and a link.

```swift
import CommonKit

// Once, at launch. Checks when due, then hourly while the app runs, so it never waits more than a day.
let updates = UpdateCheck(tool: CommonTool.thisApp!)
updates.start()
```

In Settings › **General**, the row after `OpenAtLoginToggle` and the line after `OpenAtLoginFootnote`:

```swift
UpdateCheckToggle(updates: updates)     // "Check for updates daily"
UpdateCheckFootnote(updates: updates)   // "Version x.y.z is available" as a link, or why the last check failed
```

Both views are CommonKit's, so every app's row reads the same. The toggle keeps its state in `@State` and writes `isEnabled` from there: `isEnabled` is a preference, not an observed property, so a `Binding` straight to it would draw a switch that never moves. `available` and `lastError` are observed, so the footnote updates on its own; a failed check (offline, rate-limited) is tried again at the next launch. `check()` runs one now, for a **Check Now** button.

Keep the rule in the root `CLAUDE.md` in mind: this is the one place an app touches the network, and only after the user asks.
