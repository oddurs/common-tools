# Working in this repository

The Common Tools website: a prerendered SvelteKit site for three macOS menu bar apps (Common Stats, Common Keys, Common Bar), deployed to GitHub Pages. The apps live in their own repositories; this repository never builds them.

## The seam

Do all automation through `scripts/task`. CI and the git hooks call nothing else.

```sh
scripts/task fmt        # prettier, in place
scripts/task fmt:check  # prettier --check
scripts/task lint       # fmt:check + svelte-check --fail-on-warnings
scripts/task test       # vitest
scripts/task build      # static site → build/
scripts/task check      # lint + test + build
```

## Workflow

- Never commit to `main`. It only moves forward when a pull request is merged; the `pre-push` hook and branch protection both enforce this.
- One unit of work gets one worktree, one branch, and one pull request: `scripts/agent start <type>/<slug>`, then work in the printed path and finish with `scripts/agent ship "<type>(scope): subject" "<why>" --body-file <pr.md>`, where the body states the problem, the approach, and where a reviewer should be sceptical. It commits, checks, opens the pull request with auto-merge, keeps it rebased while CI runs, and cleans up after the merge. If it stops on a failed check or a conflict, fix the cause and run it again.
- Branch types: `feat fix chore docs perf refactor test`.
- Run `scripts/task check` until it is green before opening a pull request. Never use `--no-verify`.
- In the pull request description, state the problem, the approach, and where a reviewer should be sceptical.

## Commits

Conventional Commits: `type(scope): subject`. Write the subject in the imperative, at most 72 characters, with no trailing period. The body says why. Never add assistant or tool attribution: no co-author trailers, no "generated with" footers. The `commit-msg` hook rejects them.

## The app standard

- `standard/` is the source of truth for every Common Tools app repository's shared files, scripts, and GitHub settings (the apps are listed in `standard/apps.json`). Change a shared file here, then `node scripts/standard.js apply <app> <worktree>` in each app and ship it there. Never edit a managed file in one app alone; `check` will report it as drift.
- Text between `standard:begin`/`standard:end` markers belongs to the app; keep shared wording outside them.

## Code

- `src/lib/tools.ts` is the single source of names, repositories, and release asset names. Download links use `releases/latest/download/<asset>`; if an app renames its asset, change it here and in that app's `release.yml` together.
- Each app's CHANGELOG section for its latest release appears on its page as "What's new", so those notes are user-facing copy.
- Every claim on a page must be true of the app's code. Read the app's source before writing about a feature; don't describe unmerged work.
- Links go through `resolve()` with relative paths (`'stats/'`), and assets through `asset()`, so the `/common-tools` base path works.
- Demo videos are films made with `src/lib/film/`. Write timing as a `direct((d) => …)` script (camera, point, click, hold/release, caption, mark, poster, end); never hand-roll timelines in a scene. Scene state reads `film.marks`. Draw entrances from the frame's time, never CSS animations, or recorded frames won't match. `src/lib/demos.test.ts` pins what each caption promises; update it with the script.
- Scenes are drawn with `Film.svelte` on `src/lib/mac/` (Screen, Window, Symbol) and the geometry in `geometry.ts`. Don't invent menu bar sizes or glyphs: add an SF Symbol to `scripts/render-glyphs.swift` and run `pnpm glyphs`.
- Every film takes `dark`; check both with `pnpm shot <tool> <moment> [--dark]`. Camera shots must stay inside the screen (`clampCamera`); the tests check this.
- After changing a film, `pnpm record <tool>` (light and dark) and look at both posters before committing the videos.
- The dev server runs on port 5371 (`--strictPort`), so it never collides with other projects.
