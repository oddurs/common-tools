# Contributing

Thanks for helping. This repository is the website only. Changes to an app belong in that app's repository: [common-stats](https://github.com/oddurs/common-stats), [common-keys](https://github.com/oddurs/common-keys), or [common-bar](https://github.com/oddurs/common-bar).

## Setup

```sh
scripts/setup          # wire the git hooks, once
pnpm install
scripts/agent doctor   # check tools and repository state
```

You need Node 24 and pnpm. Recording demo videos also needs Google Chrome and ffmpeg.

## Workflow

Every change goes through a pull request. `main` only moves forward when a pull request is merged; branch protection and the `pre-push` hook both enforce this.

Each change gets its own worktree, branch, and pull request:

```sh
scripts/agent start docs/keys-shortcuts   # creates ../.worktrees/common-tools/docs/keys-shortcuts
cd ../.worktrees/common-tools/docs/keys-shortcuts
# ... make the change ...
scripts/agent commit "docs(keys): list every convert shortcut"
scripts/agent pr                          # runs the full check, pushes, opens the PR
scripts/agent done                        # after merge: removes the worktree and branch
```

Branch names are `<type>/<slug>`, where type is one of `feat fix chore docs perf refactor test`.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): subject`. Write the subject in the imperative, keep it to 72 characters, and leave off the trailing period. The body explains why; the diff already shows what. The `commit-msg` hook checks this.

Don't add tool or assistant attribution lines (co-author trailers, "generated with" footers). The hook rejects them.

## Checks

```sh
scripts/task check   # format check, type check, tests, build: the same thing CI runs
```

A branch must pass this before it becomes a pull request. Anything the site says about an app must be true of that app's code. Say which source file backs a new claim in the pull request.

## Review

This is a solo-maintained project, so branch protection requires zero approvals and the maintainer merges their own pull requests once CI is green. The `required` status check and up-to-date branches are still enforced. Pull requests are squash-merged.
