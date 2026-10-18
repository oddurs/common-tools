# Security

## Supported versions

Only each app's latest release gets fixes.

## Reporting a vulnerability

Report it privately through [GitHub Security Advisories](https://github.com/oddurs/common-tools/security/advisories/new), not in a public issue, and say which app it concerns.

You'll get an acknowledgement within a week. If the report is confirmed, a fix ships in a new release of that app and the advisory is published with credit, unless you'd rather stay anonymous.

## What each app touches

None of the apps makes network connections. The website is static.

- **Common Stats:** Common Stats runs unprivileged and makes no network connections, so the most likely issues are in how it parses kernel and IOKit data. Reports about those are welcome too.
- **Common Keys:** Common Keys needs Accessibility access because it reads key presses through an event tap and types fixes back. It makes no network connections. What it learns stays in `~/Library/Application Support/Common Keys/` on your Mac. Reports about anything that could leak typed text, or let another process drive the event tap, are the most valuable.
- **Common Bar:** Common Bar runs unprivileged, asks for no permissions, and makes no network connections. It watches mouse and scroll events globally to notice the pointer in the menu bar, and reads the window list to find empty menu bar space. Reports about either are welcome.
- **Common Battery:** Common Battery runs unprivileged and makes no network connections, so the most likely issues are in how it parses IOKit power-source data. Reports about those are welcome too.
- **Common Command:** Common Command runs unprivileged and asks for no permissions. It makes no network connections of its own; web searches and links open in your browser. It reads the folders apps live in, the System Settings extension bundles, and file names from the Spotlight index of your home folder. It keeps a history of what you opened, and the queries you opened it with, in `~/Library/Application Support/Common Command/usage.json`. Reports about how queries reach Spotlight or how the calculator parses input are especially welcome.
- **Common Glyph:** Common Glyph runs unprivileged, asks for no permissions, and makes no network connections. It reads only the images you choose, paste, or drop, and keeps a copy of the current one in its Application Support folder. Reports about how it decodes images are especially welcome.
- **Common Shot:** Common Shot runs unprivileged and asks for one permission, Screen Recording, which every screenshot tool needs. It makes no network connections. It reads the screen only when you press its shortcut or choose Take Screenshot, keeps the picture in memory until you pick an area, and then puts it on the clipboard. The shots it copied, up to the number set in Settings, are kept in `~/Library/Application Support/Common Shot/History` so the menu can offer them again; set the history to None to keep nothing. Reports about anything that could capture the screen without that shortcut are especially welcome.
- **Common Color:** Common Color runs unprivileged, asks for no permissions, and makes no network connections.
