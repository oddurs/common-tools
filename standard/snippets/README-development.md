## Development

```sh
scripts/setup           # once: wire the git hooks
scripts/dev-cert        # optional, once: a stable signing identity, so permissions survive rebuilds
scripts/agent doctor    # check tools and repository state
```

| Command | Does |
| --- | --- |
| `scripts/task run` | build, quit the running copy, open the new one |
| `scripts/task check` | lint + test + build, exactly what CI runs |
| `scripts/task test <name>` | only the tests whose name matches |
| `scripts/agent start <type>/<slug>` | new worktree and branch from `origin/main` |
| `scripts/agent ship "<type>: subject"` | commit, check, open the PR with auto-merge, wait for the merge, clean up |
| `scripts/agent pr` | check, push, open the PR with auto-merge, without waiting |
| `scripts/agent sync` | rebase onto `origin/main` |
| `scripts/agent done` | after a merge: remove the worktree and branch, update the main checkout |
| `scripts/agent list` | worktrees, branches, and pull request state |
| `scripts/release <version>` | a release: dated notes, version bump, tag, published download, checked |

See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow.
