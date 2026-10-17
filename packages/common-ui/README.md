# Common UI

Common UI is the design system for Common Tools: the apps' Settings windows and menus, and the website, read from one set of tokens. `tokens.json` is the source; `build.mjs` renders it for each surface; tests on both surfaces fail when an output is older than the source.

```
tokens.json                                         the source of truth
  └─ build.mjs
       ├─ packages/CommonKit/Sources/CommonUI/Tokens.swift   the apps: Tokens.Text.primary, Tokens.Space.md …
       └─ site/src/lib/common-ui/tokens.css                  the site: --text-primary, --space-md …
```

```sh
node packages/common-ui/build.mjs          # after editing tokens.json
node packages/common-ui/build.mjs --check  # what the tests do
```

## Layers

1. **Palette** (`palette`): the raw colours, named for what they are (`ink`, `snow`, `blue-deep`). Nothing uses these directly; they exist so a semantic token can say `"light": "ink"` and a future repaint is one edit here.
2. **Semantic tokens**: named for what they are for. `text.primary`, `surface.card`, `color.accent`, `space.md`, `radius.lg`, `motion.duration.fast`, `layout.content`. These are the only names a component may use. Every colour has a light and a dark value.
3. **Primitives**: the few reusable pieces built from tokens. In the `CommonUI` product of CommonKit (`import CommonUI`): `Card`, `IconBadge`, `LabeledRow`, `SettingsWindowHost`, `.settingsForm()`, `SettingsFootnote`, `OpenAtLoginToggle`, `OpenAtLoginFootnote`; in CommonKit, `CommonToolsSection`, which carries the family list and the promise every app makes. On the site: `.button`, `.link`, `.card`, `section.ruled`, `.callout`, `.badge`, and the `table` and `pre` styles in `site/src/app.css`.
4. **Pages and views** compose primitives. They may lay things out, but take every colour, size, and duration from a token.

## What is the system's and what is ours

The apps must look like macOS, so a token maps to a system colour wherever one exists and defines a value only where macOS has none:

| Token | macOS | Site |
| --- | --- | --- |
| `text.primary`, `text.secondary` | `labelColor`, `secondaryLabelColor` | `#1d1d1f` / `#f5f5f7`, `#6e6e73` / `#86868b` |
| `surface.base` | `windowBackgroundColor` | `#fbfbfd` / `#000` |
| `color.accent`, `color.focus` | `controlAccentColor`, `keyboardFocusIndicatorColor` (the user's choice) | `#0066cc` / `#2997ff` |
| `color.accent-fill` | `controlAccentColor` | `#0071e3` in both, so white text keeps 4.5:1 |
| `color.border`, `color.danger`, `color.success` | `separatorColor`, `systemRed`, `systemGreen` | ours |
| `surface.card`, `color.border-card` | ours: a 4.7% tint of the text colour, inside a 6% hairline, over the menu's own material | `#f2f2f5` / `#1c1c1e` |
| `surface.chrome` | not a colour: `NSVisualEffectView` | a translucent, blurred bar |
| type | the system text styles (`.body`, `.footnote`), so Dynamic Type and the user's settings apply | sizes, named after the text style each stands in for |
| elevation, layers | none: windows, menus, and popovers get the system's | `--shadow-*`, `--layer-*` |

The rule: in an app, never set a text size, never draw a shadow, never pick a blue. Use the text style, the system control, and the accent. The tokens exist for the gaps (cards in a menu, the Settings width) and for the site, which has no system to lean on and imitates one.

Scales: `space` runs 4, 8, 12, 16, 24, 32, 40, 56, 72; there is no step between 4 and 8, and that is the point. `radius` runs `xs` 4 (a key cap, a small raised piece), `sm` 8, `md` 12 (a card), `lg` 16, `full`.

## How each surface consumes the tokens

**Apps (`import CommonUI`).** `Tokens.swift` is generated: `Tokens.Text.secondary.color` (SwiftUI) or `.nsColor` (AppKit), `Tokens.Space.md`, `Tokens.Radius.md`, `Tokens.Layout.settingsWidth`. Motion has a path for each framework, and both honour Reduce Motion through one call: `Tokens.Motion.animation()` is a SwiftUI `Animation?`, nil while the user asks for reduced motion; `Tokens.Motion.duration()` is a `TimeInterval` for AppKit, zero then; `Tokens.Motion.animate(changes:completion:)` runs an `NSAnimationContext` group on the tokens' duration and easing. `Theme.swift` is written by hand and holds the types the generated file uses, and `Tokens.Layout.cardInset` (what a `Card` pads by) is defined beside `Card`. `TokensTests` checks the hash of `tokens.json` against the one `Tokens.swift` carries.

**Site.** `tokens.css` is generated and imported by `app.css`: `var(--text-secondary)`, `font: var(--type-body)`, `var(--space-md)`, `var(--radius-md)`, `transition: … var(--duration-fast) var(--easing-standard)`. Under `prefers-reduced-motion`, every duration becomes `0ms`, so an animation written on the tokens honours it without a second rule. `src/lib/common-ui/tokens.test.ts` checks that both outputs match the source, that every contrast pair in `tokens.json` meets WCAG AA in light and dark, that pages read only custom properties the tokens define, that no colour literal sits outside `tokens.css`, and that every `@media` breakpoint is `layout.breakpoint-narrow`.

## Adding a token

1. Add it to `tokens.json` under the group it belongs to, with an `about` line. A colour gets `light` and `dark` (a palette name or a `#rrggbb[aa]` literal), and `macos` when the system has a colour for it. A surface text can sit on goes into `contrast.pairs` with each text colour.
2. `node packages/common-ui/build.mjs`.
3. `scripts/task check kit site`. Commit the source and both outputs together.

Changing a token moves both surfaces at once; that is the point, so say so in the pull request. Adding a token is cheap; a token nobody uses is permanent, so add one when a second use appears, not before.

## Primitives, one example each

```swift
// A Settings window, the family's way. The form is as tall as its sections until that would run
// off the screen the window is on (its visible frame less the title bar), when it scrolls;
// `.settingsForm(maxHeight:)` caps it lower. The host keeps the window on the screen as it grows.
let settings = SettingsWindowHost(title: "Common Bar Settings")
settings.show { SettingsView() }

Form {
    Section("Shortcuts") { … }
    Section {
        OpenAtLoginToggle(problem: $loginProblem)
    } header: { Text("General") } footer: {
        // "Starts when you log in.", or what stands in the way: macOS waiting for the user to
        // allow the app under Login Items, or a refusal in the danger colour.
        OpenAtLoginFootnote(loginProblem)
    }
    CommonToolsSection()
}
.settingsForm()

// A footer: secondary by default, with an optional symbol, or in the danger colour.
SettingsFootnote("Kept on this Mac only.")
SettingsFootnote("Can’t be seen in the menu bar.", symbol: "eye.slash")
SettingsFootnote(problem, tone: .danger)

// A row with an icon, a title, a subtitle, and an action. The leading slot is 32 points unless
// `leadingSize` says otherwise; the title is a String, or a Text the row styles itself.
LabeledRow("Common Stats", subtitle: "System stats in the menu bar") {
    IconBadge(symbol: "cpu", tint: .blue, size: 32)
} trailing: {
    Button("Open") { open() }
}
LabeledRow("Take a screenshot") { ShortcutRecorder() }
LabeledRow(Text(name).foregroundStyle(.secondary), subtitle: summary, leadingSize: 20, leading: { icon })

// A card in a menu; its content is inset by Tokens.Layout.cardInset.
Card {
    Text("CPU").font(.headline)
}
.frame(width: Tokens.Layout.menuPanelWidth)

// AppKit motion, on the tokens and off under Reduce Motion.
Tokens.Motion.animate(Tokens.Motion.fast, changes: { panel.animator().alphaValue = 1 })
context.duration = Tokens.Motion.duration(Tokens.Motion.base)
```

```html
<a class="button" href="…">Download for Mac</a>
<a class="link" href="…">Read the docs ›</a>

<section class="ruled"><h2>What's new.</h2>…</section>

<a class="card" href="…">Common Keys</a>
<p class="callout">Nothing leaves your Mac.</p>
<b>Common Glyph <em class="badge">Soon</em></b>
```
