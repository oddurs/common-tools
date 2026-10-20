# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-10-20

### Added

- A Welcome window on first launch: what Common Battery does, Open at login, and the Common Tools family.
- An optional update check in Settings › General, off by default. When on, it asks GitHub for the latest release once a day and sends nothing about you or your Mac; a newer version shows as a link under the toggle.
- Menu bar battery built from the parts you choose, in the order you choose: the battery icon, the percentage (beside the icon or inside it), and the time remaining. A bolt while charging, a plug while on power and holding; red when low and yellow in Low Power Mode, or monochrome throughout.
- Menu with the level and status, a 12-hour charge chart, power source and adapter wattage, live watts, cycle count, full-charge capacity, and temperature, plus Battery Settings….
- Time remaining that learns how the Mac is used: a model trained on the Mac predicts the next hour's draw from recent draw, the time of day, and Low Power Mode, takes over from macOS's estimate only once it scores better, and counts down steadily.
- Notifications as the battery drains to a chosen level and as it charges to one.
- Settings with a live preview, a shortcut to hide the system's battery icon, open at login, and the Common Tools section.
- `--snapshot` renders every style and state, and the menu, for review.

### Changed

- The four menu bar styles and the time toggle became parts you arrange in Settings, so the item can show just the time remaining, or any mix in any order. An install keeps what its old style and time setting showed.
- The menu bar icon first appears beside the system's icons, where it can be seen, instead of at the far left, where Common Bar, the notch or an app's menus would hide it.
- Settings never grows taller than the screen it opens on; a long one scrolls. Under **Open at login** the General section now says “Starts when you log in.”, or what stands in the way, and the Common Tools section carries the family promise: free and open source, forever; nothing leaves your Mac.
- Settings follows the Common Tools family layout: the same window, grouped sections, and footnotes as the other apps, and the menu's panel shares their card style.

[Unreleased]: https://github.com/oddurs/common-tools/commits/main/apps/battery
[0.1.0]: https://github.com/oddurs/common-tools/releases/tag/battery-v0.1.0

### Fixed

- What the menu bar item shows sits in its middle. A percentage on its own, or one under 100%, sat against one side of the space kept for "100%", and an unused time slot left a gap.
- Welcome answers clicks: it is now a plain titled window, built like Settings. It shows once for the whole Common Tools family, from whichever app opens first, and never on top of another app's; a later app shows it only for a permission it is missing.
- Settings no longer opens by itself on first launch, and the request to post notifications waits until Welcome closes.
