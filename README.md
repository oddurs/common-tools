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
- `src/lib/<tool>/`: each app's demo scene. A scene is a pure function of time (`demo.ts`) drawn by a Svelte component (`Demo.svelte`).
- `src/routes/(demo)/<tool>/demo/`: the scene on its own, for recording.

## Demo videos

Each scene is set on a real Mac screen: a 16-inch MacBook Pro's 1728-point display, its 33-point menu bar and notch measured on macOS 26 (`src/lib/mac/geometry.ts`). The menu bar glyphs and the pointer are the system's own SF Symbols and arrow cursor, rendered once by `swift scripts/render-symbols.swift` into `static/symbols/`. A camera pans and zooms across the screen, and every scene draws in light and dark.

`static/<tool>/demo.mp4`, `demo-dark.mp4`, `poster.jpg`, and `poster-dark.jpg` are recorded from the scenes frame by frame, so every run gives the same video. The site shows the one that matches the viewer's appearance. You need Google Chrome and ffmpeg.

```sh
pnpm dev                 # http://localhost:5371
pnpm record stats        # or keys, bar → both appearances
```

Open `http://localhost:5371/<tool>/demo/` to watch a scene live while editing it, and add `?dark` for dark mode.

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
