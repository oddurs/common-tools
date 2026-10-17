# The website

**[oddurs.github.io/common-tools](https://oddurs.github.io/common-tools/)**: a home page, a page and a docs page for each app, and the scripted demo videos. A [SvelteKit](https://svelte.dev/docs/kit) site, prerendered with `adapter-static` and deployed to GitHub Pages on every push to `main` and once a day.

- `src/lib/tools.ts`: the apps: names, taglines, where each lives in the monorepo, and release asset names.
- `src/lib/releases.ts`: at build time, each app's latest release (version, date, download size, asset URL) from the GitHub API, and its notes from that release's `CHANGELOG.md`. Releases are tagged `<slug>-v<version>` in this repository; apps released before the move fall back to their old repository's latest release. Without network access the pages still build, just without those details. Set `GITHUB_TOKEN` to raise the API rate limit; CI passes its own.
- `src/routes/(site)/`: the pages. `<tool>/` is the product page, `<tool>/docs/` the documentation.
- `src/lib/<tool>/`: each app's demo scene. A scene is a pure function of time (`demo.ts`) drawn by a Svelte component (`Demo.svelte`).
- `src/routes/(demo)/[tool]/demo/`: a scene on its own, for recording.

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

`direct` turns the script into a pure function of time that draws the camera, the pointer and its clicks, the keys held, the caption, and the closing card. A scene adds only what is its own (the app's menu bar item, its menus, its windows), reading the film's marks for timing. `Film.svelte` puts it all on a Mac screen as macOS 26 draws it: a 1728-point display with a 24-point menu bar (`src/lib/mac/`). Menu bar icons and the pointer are the system's own SF Symbols and arrow cursor.

```sh
pnpm film list                       # each film's length, poster, and marks
pnpm shot bar collapse poster 9000   # stills into shots/ at a mark, the poster, or a time; add --dark
pnpm record                          # every film, light and dark → static/<tool>/demo*.mp4 and poster*.jpg
pnpm record bar --dark               # one film, one appearance
pnpm glyphs                          # re-render static/symbols/ after adding a symbol to scripts/render-glyphs.swift
```

`shot` and `record` start their own dev server with file watching off, so editing while a recording runs is safe. They need Google Chrome; `record` also needs ffmpeg. The site shows the video matching the viewer's appearance. Open `http://localhost:5371/<tool>/demo/` (add `?dark`) to watch a film live while editing it.

## Development

From the repository root: `scripts/task check site` runs what CI runs (format check, type check, tests, build). Here: `pnpm dev` serves it on port 5371.
