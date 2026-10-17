# Security

## Supported versions

Only the latest release gets fixes.

## Reporting a vulnerability

Report it privately through [GitHub Security Advisories](https://github.com/oddurs/common-shot/security/advisories/new), not in a public issue.

You'll get an acknowledgement within a week. If the report is confirmed, a fix ships in a new release and the advisory is published with credit, unless you'd rather stay anonymous.

<!-- standard:begin surface -->
Common Shot runs unprivileged and asks for one permission, Screen Recording, which every screenshot tool needs. It makes no network connections. It reads the screen only when you press its shortcut or choose Take Screenshot, keeps the picture in memory until you pick an area, and then puts it on the clipboard. The shots it copied, up to the number set in Settings, are kept in `~/Library/Application Support/Common Shot/History` so the menu can offer them again; set the history to None to keep nothing. Reports about anything that could capture the screen without that shortcut are especially welcome.
<!-- standard:end surface -->
