# Contributing

Thanks for helping. Every Common Tools app stays small on purpose, so open an issue before starting anything large, and say which app it's about.

## Setup

```sh
scripts/setup          # wire the git hooks, once
scripts/dev-cert       # optional, once: a stable signing identity, so permissions survive rebuilds
scripts/agent doctor   # check tools and repository state
```

You need macOS 14 or later and Swift 6 or later for the apps (the Command Line Tools are enough; Xcode is not required), and Node 24 with pnpm for the site.

## Layout

| Path | Holds |
| --- | --- |
| `apps/<slug>/` | one app: `Package.swift`, `Sources`, `Tests`, `Resources`, `docs`, `README.md`, `CHANGELOG.md`, `CLAUDE.md`, `icon.swift` |
| `packages/CommonKit/` | what the apps share: the family list and the Common Tools section of Settings |
| `shared/` | the family icons every app bundles, and the icon body |
| `site/` | the website, a SvelteKit site deployed to GitHub Pages |
| `apps.json` | every app's name, bundle identifier, deployment target, extra tools, and permissions |

## Workflow

Every change goes through a pull request, and pull requests merge themselves. `main` only moves forward when a pull request is merged; branch protection and the `pre-push` hook both enforce this.

Each change gets its own worktree, branch, and pull request:

```sh
scripts/agent start fix/bar-stay-revealed   # creates ../.worktrees/common-tools/fix/bar-stay-revealed
cd ../.worktrees/common-tools/fix/bar-stay-revealed
# ... make the change ...
scripts/task run bar                         # build it and open it
scripts/agent ship "fix(bar): stay revealed after a ⌘-drag" "Why it changed." --body-file pr.md
```

`ship` commits, runs the check on what changed, opens the pull request with auto-merge, and waits. The pull request squash-merges itself once the `required` check passes. While it waits, `ship` rebases onto `main` whenever `main` moves and checks again. If a check fails or the rebase conflicts, it stops and says so: fix it, then run `scripts/agent ship` again. `commit`, `pr`, and `done` still work one step at a time.

The pull request takes its title from the branch's first commit, and that title becomes the squash commit on `main`, so make the first commit the one that names the change. The body states the problem, the approach, and where a reviewer should be sceptical.

Branch names are `<type>/<slug>`, where type is one of `feat fix chore docs perf refactor test`. Name the app in the slug and in the commit scope.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): subject`. Write the subject in the imperative, keep it to 72 characters, and leave off the trailing period. The body explains why; the diff already shows what. The `commit-msg` hook checks this.

Don't add tool or assistant attribution lines (co-author trailers, "generated with" footers). The hook rejects them.

## Checks

```sh
scripts/task check --changed        # what CI runs for your change
scripts/task check bar              # one app: lint + test + build
scripts/task test bar --filter=X    # just the tests whose name matches
```

A branch must pass this before it becomes a pull request. A bug fix comes with the test that would have caught it. Each app's `CLAUDE.md` says what else its changes need: accuracy arguments, `worldkey eval` numbers, snapshots.

## Releases

```sh
scripts/release bar 0.4.0
```

Add user-facing changes under `## [Unreleased]` in the app's `CHANGELOG.md` as you make them. `scripts/release` moves them under the new version with today's date, bumps the version in the app's `Info.plist`, merges that through a pull request, tags the merge `bar-v0.4.0`, and waits until the download is live. The release notes are that CHANGELOG section. Don't tag by hand.

## Review

This is a solo-maintained project, so branch protection requires zero approvals, and pull requests merge themselves once the `required` check is green. Branches don't have to be up to date with `main` to merge; `ship` keeps them current instead.
