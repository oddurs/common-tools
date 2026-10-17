# First run and update checks

Two pieces of CommonKit every app can adopt. Neither is wired into any app yet; each app's owner adds the lines below in its own pull request.

## The Welcome window

One window, the same in every app: the app's icon, what it does in a line, the permission it needs with an **Open System Settings** button and a live check that turns green when the switch is flipped, an **Open at login** toggle, and the Common Tools family. Nothing in CommonKit knows which app it is; the app passes its data.

Three lines, in `applicationDidFinishLaunching`:

```swift
import CommonKit

Welcome.showIfFirstLaunch(WelcomeInfo(
    line: "Fixes words typed on the wrong keyboard layout, for every keyboard macOS has.",
    permission: .accessibility(reason: "to see what you type and fix it")))
```

- `name` defaults to the bundle's display name; pass it only if that's wrong.
- `permission` is `.accessibility(reason:)`, `.screenRecording(reason:)`, or left out. The reason finishes the sentence "*App* needs *Permission* access …". Only Common Keys and Common Shot need one.
- The window shows once per Mac (`CommonKit.welcomed` in UserDefaults) and never again. `Welcome.show(info)` shows it on demand, for a **Welcome…** menu item or a button in Settings.
- **Open System Settings** calls the system's own prompt (which puts the app in the pane's list) and opens the pane. The window polls every second while open, so "Granted" appears without a relaunch.
- **Open at login** uses CommonKit's `LoginItem` (`SMAppService.mainApp`), the same wrapper behind `OpenAtLoginToggle` in Settings, so the two switches never disagree.
- Common Bar has its own animated how-to; it can show Welcome first and its guide after, or skip Welcome. Its call.

To look at it without building an app:

```sh
cd packages/CommonKit/Demo
swift run welcome-demo                        # opens the window, as Common Keys would show it
swift run welcome-demo --screenshot out.png   # renders it to a file (the login toggle renders as a placeholder there)
```

## The update check

`UpdateCheck` asks GitHub for the app's latest release at most once a day, compares versions, and sets `available` when there's a newer one. It's **off until the user turns it on**, and the request is one unauthenticated GET of the public release list with a fixed `User-Agent: common-tools`: no identifier, no cookie, nothing about the Mac. No Sparkle, no download, no install; the app shows a line and a link.

```swift
import CommonKit

// Once, at launch. Checks when due, then hourly while the app runs, so it never waits more than a day.
let updates = UpdateCheck(tool: CommonTool.thisApp!)
updates.start()
```

In Settings › **General**, after Open at login:

```swift
Toggle("Check for updates daily", isOn: Binding(
    get: { updates.isEnabled },
    set: { updates.isEnabled = $0; Task { await updates.checkIfDue() } }))
if let update = updates.available {
    Link("Version \(update.version) is available", destination: update.download ?? update.page)
}
```

`UpdateCheck` is `@Observable`, so the view updates on its own. `lastError` holds why the last check failed (offline, rate-limited), for a footnote if wanted; the next launch tries again. `check()` runs one now, for a **Check Now** button.

Keep the rule in the root `CLAUDE.md` in mind: this is the one place an app touches the network, and only after the user asks.
