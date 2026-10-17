# Common Tools

[![CI](https://github.com/oddurs/common-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/oddurs/common-tools/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

The website for three small, native macOS menu bar apps. **[oddurs.github.io/common-tools](https://oddurs.github.io/common-tools/)**

| App                                                    | Does                                                                  | Download                                                                                           |
| ------------------------------------------------------ | --------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| [Common Stats](https://github.com/oddurs/common-stats) | CPU, GPU, memory, network, disk, storage, and battery in the menu bar | [CommonStats.zip](https://github.com/oddurs/common-stats/releases/latest/download/CommonStats.zip) |
| [Common Keys](https://github.com/oddurs/common-keys)   | Fixes words typed on the wrong keyboard layout                        | [CommonKeys.zip](https://github.com/oddurs/common-keys/releases/latest/download/CommonKeys.zip)    |
| [Common Bar](https://github.com/oddurs/common-bar)     | Hides menu bar icons behind one line                                  | [CommonBar.zip](https://github.com/oddurs/common-bar/releases/latest/download/CommonBar.zip)       |

Each app lives in its own repository and publishes its releases there. This repository holds only the site: a home page, a page and a docs page for each app, and the scripted demo videos.

## How it's built

A [SvelteKit](https://svelte.dev/docs/kit) site, prerendered with `adapter-static` and deployed to GitHub Pages on every push to `main`.

- `src/lib/tools.ts`: the three apps: names, repositories, and release asset names. Download buttons point at `releases/latest/download/<asset>`, so they always get the newest build without a site change.
- `src/routes/(site)/`: the pages. `<tool>/` is the product page, `<tool>/docs/` the documentation.
- `src/lib/releases.ts`: at build time, each app's latest release (version, date, download size) from the GitHub API, and its notes from that release's `CHANGELOG.md`. The site rebuilds daily, so a new release appears without a change here. Without network access the pages still build, just without those details. Set `GITHUB_TOKEN` to raise the API rate limit; CI passes its own.
- `src/lib/<tool>/`: each app's demo scene. A scene is a pure function of time (`demo.ts`) drawn by a Svelte component (`Demo.svelte`).
- `src/routes/(demo)/<tool>/demo/`: the scene on its own, for recording.

## Demo videos

The videos are made by a small film engine in `src/lib/film/`. A film is a script of beats on a clock:

```ts
export const film = direct((d) => {
	d.camera(wide);
	d.at(700).camera(closeUp).caption('System stats, right in the menu bar.');
	d.at(2700).point({ x: 1270, y: 250 });
	d.at(4000).point(item);
	d.at(4200).click().mark('open').caption('Click for live graphs of everything.');
	d.at(8200).poster();
	d.at(19_600).end(2200);
});
```

`direct` turns the script into a pure function of time that draws the camera, the pointer and its clicks, the keys held, the caption, and the closing card. A scene (`src/lib/<tool>/demo.ts` and `Demo.svelte`) adds only what is its own (the app's menu bar item, its menus, its windows), reading the film's marks for timing. `Film.svelte` puts it all on a Mac screen as macOS 26 draws it: a 1728-point display with a 24-point menu bar (`src/lib/mac/`). Menu bar icons and the pointer are the system's own SF Symbols and arrow cursor.

```sh
pnpm film list                       # each film's length, poster, and marks
pnpm shot bar collapse poster 9000   # stills into shots/ at a mark, the poster, or a time; add --dark
pnpm record                          # every film, light and dark → static/<tool>/demo*.mp4 and poster*.jpg
pnpm record bar --dark               # one film, one appearance
pnpm glyphs                          # re-render static/symbols/ after adding a symbol to scripts/render-glyphs.swift
```

`shot` and `record` start their own dev server with file watching off, so editing while a recording runs is safe. They need Google Chrome; `record` also needs ffmpeg. The site shows the video matching the viewer's appearance. Open `http://localhost:5371/<tool>/demo/` (add `?dark`) to watch a film live while editing it.

## The app standard

The three apps share one setup, kept here in `standard/` and checked daily by the Standard workflow:

- `standard/app/` holds the repository files every app has: dotfiles, git hooks, CI, release and Dependabot workflows, `scripts/agent`, `task`, `setup`, `dev-cert`, and `release`, the licence and community files, CLAUDE.md, CONTRIBUTING, SECURITY, the PR template, the icon renderer, and the Common Tools Settings section with its icons. Text between `standard:begin <name>` and `standard:end <name>` markers is each app's own; everything else must match.
- `standard/apps.json` holds what differs: names, bundle identifiers, the deployment target, extra command-line tools, topics.
- Each app's README, CHANGELOG, Package.swift, Info.plist, and issue forms are its own, checked for the structure the site and release tooling rely on.

```sh
node scripts/standard.js check                       # drift in each app's main branch (reads ../<app>)
node scripts/standard.js apply bar <worktree>        # write the standard into a worktree of an app
node scripts/standard.js settings check              # GitHub settings: merges, protection, security, topics
node scripts/standard.js settings apply bar          # set them
```

To change something every app has: edit `standard/`, then apply it to each app in a worktree and ship it there.

## Development

```sh
scripts/setup            # once: wire the git hooks
pnpm install
scripts/agent doctor     # check tools and repository state
```

| Command                                  | Does                                                                     |
| ---------------------------------------- | ------------------------------------------------------------------------ |
| `scripts/task check`                     | format check, type check, tests, build: exactly what CI runs             |
| `scripts/agent start <type>/<slug>`      | new worktree and branch from `origin/main`                               |
| `scripts/agent commit "<type>: subject"` | Conventional Commit, checked by the hook                                 |
| `scripts/agent ship "<type>: subject"`   | commit, check, open the PR with auto-merge, wait for the merge, clean up |
| `scripts/agent pr`                       | check, push, open the PR with auto-merge, without waiting                |
| `scripts/agent sync`                     | rebase onto `origin/main`                                                |
| `scripts/agent done`                     | after a merge: remove the worktree and branch, update the main checkout  |
| `scripts/agent list`                     | worktrees, branches, and pull request state                              |

See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow.

## Licence

MIT. See [LICENSE](LICENSE).
