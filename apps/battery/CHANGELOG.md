# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Menu bar battery in four styles (Icon, Icon and Percentage, Percentage in Icon, Percentage), with optional time remaining. A bolt while charging, a plug while on power and holding; red when low and yellow in Low Power Mode, or monochrome throughout.
- Menu with the level and status, a 12-hour charge chart, power source and adapter wattage, live watts, cycle count, full-charge capacity, and temperature, plus Battery Settings….
- Time remaining that learns how the Mac is used: a model trained on the Mac predicts the next hour's draw from recent draw, the time of day, and Low Power Mode, takes over from macOS's estimate only once it scores better, and counts down steadily.
- Notifications as the battery drains to a chosen level and as it charges to one.
- Settings with a live preview, a shortcut to hide the system's battery icon, open at login, and the Common Tools section.
- `--snapshot` renders every style and state, and the menu, for review.

[Unreleased]: https://github.com/oddurs/common-tools/commits/main/apps/battery
