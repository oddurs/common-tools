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
- One unit of work gets one worktree, one branch, and one pull request: `scripts/agent start <type>/<slug>`, then work in the printed path and finish with `scripts/agent ship "<type>(scope): subject" "<why>"`. It commits, checks, opens the pull request with auto-merge, keeps it rebased while CI runs, and cleans up after the merge. If it stops on a failed check or a conflict, fix the cause and run it again.
- Branch types: `feat fix chore docs perf refactor test`.
- Run `scripts/task check` until it is green before opening a pull request. Never use `--no-verify`.
- In the pull request description, state the problem, the approach, and where a reviewer should be sceptical.

## Commits

Conventional Commits: `type(scope): subject`. Write the subject in the imperative, at most 72 characters, with no trailing period. The body says why. Never add assistant or tool attribution: no co-author trailers, no "generated with" footers. The `commit-msg` hook rejects them.

## Code

- `src/lib/tools.ts` is the single source of names, repositories, and release asset names. Download links use `releases/latest/download/<asset>`; if an app renames its asset, change it here and in that app's `release.yml` together.
- Every claim on a page must be true of the app's code. Read the app's source before writing about a feature; don't describe unmerged work.
- Links go through `resolve()` with relative paths (`'stats/'`), and assets through `asset()`, so the `/common-tools` base path works.
- Demo scenes are pure functions of time in `src/lib/<tool>/demo.ts`. Draw entrances from the scene clock, never CSS animations, or the recorder's frames won't match. `src/lib/demos.test.ts` pins what each caption promises; update it with the scene.
- Scenes are built from `src/lib/mac/` (Screen, Window, Overlay, Stage) on the measured geometry in `geometry.ts`. Don't invent menu bar sizes or glyphs: add an SF Symbol to `scripts/render-symbols.swift` and re-run it.
- Every scene takes `dark`; check both. A camera shot must stay inside the screen (`clampCamera`); the tests check this.
- After changing a scene, re-record it: `pnpm dev`, then `pnpm record <tool>` (records light and dark), and look at both posters and a few frames before committing the video. Don't edit `src/` while recording: a hot reload kills the run.
- The dev server runs on port 5371 (`--strictPort`), so it never collides with other projects.
