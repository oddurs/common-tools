# Testing

Seven apps, one shared package and a website, checked by one seam: `scripts/task`. Each layer catches one kind of mistake and costs about what it is worth.

| Layer | Runs | Catches | Cost |
| --- | --- | --- | --- |
| Unit tests (`Tests/<Name>KitTests`) | `scripts/task test <app>`, every `check` | Logic: layout, parsing, ranking, geometry, detection | Under a second per app, except Keys |
| Contract test (`ContractTests.swift`) | every `check` | `apps.json`, `CommonTool.all` and `Info.plist` disagreeing; a missing icon, source target or changelog section | Milliseconds |
| Performance gates (`PerformanceTests.swift`) | every `check` | An accidental quadratic loop, a per-draw text measurement, a leak per tick | A few seconds |
| Site tests (`site/src/**/*.test.ts`) | `scripts/task test site` | Tools, releases and demo scripts drifting from the apps | Seconds |
| Build (`scripts/task build`) | every `check` | A universal, signed bundle with every family icon; every app page on the site | A minute per app |
| Smoke (`scripts/task smoke <app>`) | CI, after `check` | The built app quitting within five seconds of launch | Five seconds |
| Coverage (`scripts/task cover <area>`) | by hand | Code no test reaches | A test run |

`scripts/task check` is lint, tests and build; CI runs it for each area a pull request touches, then `smoke` for each app. A change to `packages/CommonKit` or `shared/` runs every app.

## Running

```sh
scripts/task test bar                        # one app's suite
scripts/task test bar --filter=RevealTests   # one suite, or one test by name
scripts/task test kit                        # CommonKit, including the contract for every app
scripts/task cover command                   # line coverage, per file
scripts/task smoke stats                     # build if needed, launch, wait five seconds
scripts/task check --changed                 # what the hooks and CI will run for this branch
```

## Shared helpers: CommonTesting

`packages/CommonKit/Sources/CommonTesting/` is a library every app's test targets link. It imports nothing from Swift Testing, so it builds wherever the package does.

- `AppContract(slug:)` reads `apps.json`, `CommonTool.all` and the app's `Resources/Info.plist` and returns every way they disagree, plus anything the build copies that is missing. Each app runs it as one test. A rule every app should keep goes here, not in seven files.
- `Benchmark.microseconds(iterations:batches:_:)` is the mean of the fastest of a few batches, so other work on the machine can only slow a measurement down, never fail a gate on its own. Set budgets about ten times what a quiet M-series Mac measures.

## Writing tests

- Swift Testing only: `@Suite`, `@Test`, `#expect`, `#require`. Parameterize with `@Test(arguments:)` rather than looping.
- Test the library target. If a behaviour can only be tested through the app target, move the logic.
- Deterministic: no dates, no random without a seed, no network, nothing that depends on which apps or layouts this Mac has unless that is what the test is about (Keys' `SystemTests` are, and say so).
- A bug fix arrives with the test that would have caught it.
- A flaky test is a bug in the test. Fix the cause or delete it; never retry or widen a budget to make it pass.

## Keys

Common Keys asks the real spell checker and the installed keyboard layouts, which builds character models on first use. Its suite is the slow one in the family, and a change to CommonKit runs it along with every other app. Keep new Keys tests on the fake lexicon in `Support.swift` unless they are about the system.
