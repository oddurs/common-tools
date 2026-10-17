# The website

The Common Tools website: a prerendered SvelteKit site, deployed to GitHub Pages. Its area is `site`: `scripts/task check site` from the repository root, or `pnpm` commands here. The workflow and commit rules are in the root CLAUDE.md; this file holds what is specific to the site.

## Code

- `src/app.css` holds the base styles and the primitives (`.button`, `.card`, `section.ruled`, `.callout`, `.badge`, tables) on the design tokens in `src/lib/common-ui/tokens.css`, which is generated from `packages/common-ui/tokens.json` (`pnpm tokens` after editing it). A page's `<style>` takes its colours, sizes, and durations from `var(--…)`; `src/lib/common-ui/tokens.test.ts` rejects a colour literal or an unknown property. Media queries use `760px`, the `layout.breakpoint-narrow` token.
- `src/lib/tools.ts` is the site's list of apps: names, taglines, where each lives in the monorepo, the release asset name, and the old repository for apps released before the move. `src/lib/tools.test.ts` checks it against `apps.json` and CommonKit's family list, so the "Get…" button in every app's Settings always has a page to open.
- `src/lib/releases.ts` reads each app's latest release (`<slug>-v*` here, else the old repository) at build time, and its CHANGELOG section becomes "What's new" on the app's page. Download buttons use the release's asset URL.
- Every claim on a page must be true of the app's code. Read the app's source in `apps/<slug>/` before writing about a feature; don't describe unmerged work.
- Links go through `resolve()` with relative paths (`'stats/'`), and assets through `asset()`, so the `/common-tools` base path works.
- Demo videos are films made with `src/lib/film/`. Write timing as a `direct((d) => …)` script (camera, point, click, hold/release, caption, mark, poster, end); never hand-roll timelines in a scene. Scene state reads `film.marks`. Draw entrances from the frame's time, never CSS animations, or recorded frames won't match. `src/lib/demos.test.ts` pins what each caption promises; update it with the script.
- Scenes are drawn with `Film.svelte` on `src/lib/mac/` (Screen, Window, Symbol) and the geometry in `geometry.ts`. Don't invent menu bar sizes or glyphs: add an SF Symbol to `scripts/render-glyphs.swift` and run `pnpm glyphs`.
- Every film takes `dark`; check both with `pnpm shot <tool> <moment> [--dark]`. Camera shots must stay inside the screen (`clampCamera`); the tests check this.
- After changing a film, `pnpm record <tool>` (light and dark) and look at both posters before committing the videos.
- The dev server runs on port 5371 (`--strictPort`), so it never collides with other projects.
