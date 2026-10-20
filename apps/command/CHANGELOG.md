# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-10-20

### Added

- A Welcome window on first launch: what Common Command does, Open at login, and the Common Tools family.
- An optional update check in Settings › General, off by default. When on, it asks GitHub for the latest release once a day and sends nothing about you or your Mac; a newer version shows as a link under the toggle.
- A launcher panel opened with a global shortcut (⌥Space by default, recordable in Settings). It doesn't activate the app, so the app you were in stays frontmost.
- Search across apps, System Settings panes, Common Command's own commands, files and folders from the Spotlight index, and the web.
- Fuzzy matching on word starts and runs of letters, with case and accent folding and bold matched letters.
- Learning: the result chosen for a query comes first next time, and frequently opened items rise, decaying with a one-week half-life.
- A calculator with percent, powers, factorial, functions, constants, and region-aware decimal separators. Return copies the result.
- Link detection for web addresses, `localhost`, and IPv4 addresses.
- Keyboard control: arrows, ⌃P/⌃N, Tab, Return, ⌘Return to show in Finder, and ⌘1–⌘9 with hints while ⌘ is held.
- Settings: shortcut, theme, size, translucency, visible results, sources, search engine, menu bar item, and open at login.
- Liquid Glass on macOS 26 and the popover material on earlier versions, or a solid background.
- System Settings topics and keywords from System Settings' own search terms, so "dark mode", "low power", or "firewall" find the right pane, shown with the pane's icon.
- A result chosen for a query also leans shorter and longer starts of that query its way, so you can type less next time.
- Unit conversions such as "10 km to mi", "70 f in c", or "5 GB in MB", offline, with Return to copy.
- Moving the pointer over a result selects it, and apps, files, and folders can be dragged out of the panel.
- A macOS 26 look: a glass capsule for the field and a glass card for results, grouped into Top Hit, Applications, System Settings, Files, and Search the Web. A short fade on opening, none with Reduce Motion.
- "No Results" when nothing matches and web search is off.
- Scopes, as in Spotlight on macOS 26: ⌘1 Apps, ⌘2 Files, ⌘3 Actions, also as buttons in the field. With nothing typed, a scope lists every app and pane, recent files, or all actions.
- Actions: run shortcuts from the Shortcuts app, and quit or hide running apps.
- A live preview of the panel at the top of Settings.
- A warning in Settings and the menu bar menu when the shortcut is also Spotlight's or Alfred's, saying where to change theirs. macOS accepts both without an error, so the clash was silent.
- VoiceOver reads the selected result as it changes.
- An action menu on ⌘K or a right-click, with Show in Finder, Quick Look, Copy Path, and Hide or Quit for running apps. ⌘Y opens Quick Look and ⌘⇧C copies directly.

### Changed

- Faster and lighter: app and System Settings icons are drawn in the background once, rather than on screen the first time each appears; the panel is set up right after launch, so the first open doesn't wait for it; moving through results no longer asks the system about every running app for each row; and the running apps are read off the main thread when the panel opens.
- The menu bar icon first appears beside the system's icons, where it can be seen, instead of at the far left, where Common Bar, the notch or an app's menus would hide it.
- Settings is laid out like the other Common Tools apps’ and sized to the screen it opens on, instead of a fixed 720 pt window. Under **Open at login** the General section now says “Starts when you log in.”, or what stands in the way, and the Common Tools section carries the family promise: free and open source, forever; nothing leaves your Mac.
- Settings follows the layout shared by every Common Tools app: the same window, footnotes, and Open at login switch, with Open at login first under General. In the panel, a calculation, a link, or a web search gets an icon like the other rows instead of a bare symbol.
- ⌘1–⌘9 choose a scope instead of opening the nth result, to match Spotlight.

- Rows say less: no "Application" label, a pane's name instead of "System Settings ›", and file paths keep their start and end when shortened.
- System Settings topics match only where each typed word starts a word of the topic, and keywords only from the fourth letter, so a short query finds apps instead of a dozen loosely related settings.

### Fixed

- Typing a main folder's name finds that folder first: "applications" gives /Applications, not ~/Applications or a copy in a backup, and the same goes for Utilities, your home folder, Desktop, Documents, Downloads, Pictures, Movies, Music, Library, iCloud Drive and Public. Spotlight never returned several of them. An app keeps its name ("Music" still opens Music), and a folder you choose for a query still comes first next time. Among other folders with the same name, shallower ones rank higher.
- Welcome answers clicks: it is now a plain titled window, built like Settings. It shows once for the whole Common Tools family, from whichever app opens first, and never on top of another app's; a later app shows it only for a permission it is missing.
- Settings no longer opens by itself on first launch.
- A file Spotlight listed twice showed as two rows.

[Unreleased]: https://github.com/oddurs/common-tools/commits/main/apps/command
[0.1.0]: https://github.com/oddurs/common-tools/releases/tag/command-v0.1.0
