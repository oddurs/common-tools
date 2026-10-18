# Common Keys

[![CI](https://github.com/oddurs/common-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/oddurs/common-tools/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A menu bar app that fixes words typed on the wrong keyboard layout, for every keyboard macOS has. **[oddurs.github.io/common-tools/keys](https://oddurs.github.io/common-tools/keys/)** · [Docs](https://oddurs.github.io/common-tools/keys/docs/)

![The menu in light and dark, and on the first day before anything is learned](docs/menu.png)

- Type `/etta ` on U.S. and it becomes `þetta `; `ghbdtn` becomes `привет`, `dkssud` becomes `안녕`.
- It learns which keys you mix up and which language you write in each app, and keeps you on the right one.
- ⌘Z right after a fix undoes it, and that word is left alone from then on.
- Double-tap right ⌥ converts the word before the cursor; ⌥⇧Space switches layout.
- Switching apps restores the layout you last used there, or the one you usually write in.
- It runs on **KeysKit**, an engine that reads keys on any keyboard. Other tools can use it through the `common-keys` command.

Free forever and open source under the MIT licence. Private: no analytics, no crash reports, no account; nothing you do is ever reported. No network access; what it learns stays in one file on your Mac.

## Install

Requires macOS 14.4 or later.

1. Download [CommonKeys.zip](https://oddurs.github.io/common-tools/keys/), unzip it, and move **Common Keys** to Applications.
2. Open it. The build is not notarized, so the first time macOS will say it can't verify the developer. Go to **System Settings › Privacy & Security** and click **Open Anyway**. Alternatively, run:

   ```sh
   xattr -dr com.apple.quarantine "/Applications/Common Keys.app"
   ```

3. Click **Open System Settings** in the Welcome window and allow Common Keys in **Privacy & Security › Accessibility**. If it is already on there, that switch belongs to an earlier copy; click **Reset and Ask Again**. It needs Accessibility to read key presses and type fixes back; it asks for nothing else.

Release builds are signed ad-hoc, so macOS treats each update as a new app. After updating, the switch in Accessibility may show on and still belong to the old copy; turning it off and on again keeps the old one. Choose **Reset and Ask Again…** from the menu, which removes that record and asks again.

### The `common-keys` command

Download [common-keys.zip](https://oddurs.github.io/common-tools/keys//download/common-keys.zip), unzip it, and put `common-keys` on your `PATH`:

```sh
unzip common-keys.zip
xattr -d com.apple.quarantine common-keys
mv common-keys /usr/local/bin/
```

## Usage

Common Keys lives in the menu bar as the flag of the current layout, with a lock beside it in an app you pinned to that layout, and dimmed while it isn't fixing: no Accessibility access, fixing paused, or an app paused without a pin. The menu shows the day's words and fixes, your languages, the keys you mix up most, and the enabled keyboards to switch between.

- **Fixing as you type** happens when a word ends. **Pause Fixing** in the menu stops it; the convert shortcut still works.
- **Convert last word**: double-tap right ⌥ by default; Settings offers double-tap ⇧ or ⌃ instead, or off.
- **Next layout**: ⌥⇧Space by default, changeable in Settings.
- **Per-app layouts**: from the menu or Settings, pin the front app to one layout, or pause Common Keys in it. Terminals and code editors start paused.
- **Forget Everything…** in Settings clears what it has learned.
- **Settings** opens from the menu with ⌘, or by opening the app again while it runs. It has
  Shortcuts, Exceptions (per-app layouts), Learning, and General (**Open at login**), and ends with
  the Common Tools family and the app's version.

Learned data lives in `~/Library/Application Support/Common Keys/`:

- `memory.json` holds learned words, mixed-up keys and each app's usual layout. It also holds the words
  you keep, as salted hashes of the keys (never the text), and your adjustments to the engine's weights.
- `stats.json` holds the menu's daily counts for the last month, never the words themselves.
- `Words/` caches the word lists the character models are built from, taken from this Mac's own
  spell-checking dictionaries.

Forget Everything in Settings clears the first two. The third is rebuilt from the system as needed.

## KeysKit

The engine is a library, `KeysKit`, in layers. Each layer knows nothing of the ones above it.

1. **Keys.** A key press is a key code and modifiers, not a character, because the same key means
   a different letter on every keyboard.
2. **Keyboards.** Anything that turns keys into text conforms to `Keyboard`, in one of three kinds:
   - *direct*: every ordinary layout. `KeyLayout` reads the layout's own table with the system
     translator, so all 251 layouts in macOS 26 work, across 35+ scripts, dead keys included, and
     it can run backwards from text to keys.
   - *composing*: an input method whose output is predictable. A `Composer` assembles the layout's
     characters: `HangulComposer` for Korean 2-Set, `VietnameseComposer` for Telex and VNI. These
     are fixed in both directions.
   - *converting*: an input method whose output the user picks, such as Japanese or Chinese. Their
     text is never read back. They are only a destination: the engine hands them the keys and they
     compose as usual. `Phonotactics` recognizes romaji and pinyin readings.

   `InputSources` maps every macOS input source to one of these.
3. **Evidence.** Each reading of the keys is weighed by `Scorer`, using:
   - the system spell checker, where a word counts only if the dictionary lists it exactly, since
     some dictionaries accept any string;
   - `Orthography`: rules no word breaks, such as a Hebrew final letter mid-word, a word starting
     with a combining mark, or two scripts in one word;
   - the language recognizer, between readings in the same script only;
   - a character model per language (`CharacterModel`): 4-grams of how its words are spelled, scored as
     how typical a reading is of the language. It grades what a dictionary can only accept or reject,
     and it covers names, slang and languages with no dictionary. Models are built on your Mac from
     the spell checker's own words, a few at a time after launch, and cached;
   - for languages macOS has a keyboard for but no dictionary, a shipped list of 8,000 common words
     (`WordLists`) from the Leipzig Corpora Collection. 27 languages: Albanian, Amharic, Armenian,
     Azerbaijani, Belarusian, Bengali, Croatian, Estonian, Georgian, Gujarati, Kannada, Kazakh, Kyrgyz,
     Latvian, Macedonian, Malayalam, Maltese, Marathi, Mongolian, Odia, Persian, Serbian, Sinhala,
     Slovak, Thai, Urdu and Welsh;
   - what the user taught (`Memory`): words corrected, keys mixed up, and words typed and kept three
     times or more, which count as "you write this here".
4. **Weights.** Each reading becomes a `FeatureVector`, and `Weights` turn the difference between two
   readings into a score. The weights are fitted, not chosen: `common-keys train` types dictionary words
   on their own keyboard (leave them alone) and on every other one (fix them back), and fits a
   logistic regression that counts a false fix 20 times worse than a missed one. The threshold sits
   above every training example that must stay unfixed. One word in five is held out of training by
   a fixed hash, and `common-keys eval --split heldOut --engine rules|model` compares the fitted weights
   with the hand-tuned ones on those words only. `Sources/KeysKit/TrainedWeights.swift` is the
   generated result, so a change to it shows up in review. A second set, `trainedPrefix`, judges the
   start of a word still being typed, with "some word starts this way" in place of "this is a word".
   `common-keys eval --prefixes` gates it: no start of a correctly typed word may ever be changed.

   On the Mac, every correction is also a lesson for the weights. A retype or the convert shortcut
   says "fix this", ⌘Z after a fix says "don't" (counted double), a fix left standing weakly says
   "right", and one word kept in twenty weakly says "leave words like this". Twenty lessons at a time
   adjust the user's copy of the weights by logistic regression, pulled back toward the shipped ones.
   Each weight stays within half its shipped size of where it shipped, and the threshold never moves:
   a user can sharpen the engine, not teach it to fix everything.
5. **Decisions.** `Detector` compares the readings and decides at the end of a word, mid-word,
   or when asked. It also says which language a word was meant in, which feeds per-app learning.

Above the engine, the app adds the event tap, injection and UI. Swapping text depends on the kinds
involved. Between ordinary layouts the fix goes out right behind the triggering key. When an input
method is involved, the old text is erased first and the layout switched, then the new text is typed
or the keys replayed, because an input method would read typed Unicode as key presses.

### Using it from other tools

    common-keys sources [--all]
    common-keys convert ghbdtn --from US --to Russian # привет
    common-keys convert 안녕하세요 --from 2SetKorean --to US   # dkssudgktpdy
    common-keys detect /etta --from US                # þetta  com.apple.keylayout.Icelandic
    common-keys eval --keyboards US,Russian --words 150 --split heldOut --engine rules|model [--prefixes]
    common-keys train --write Sources/KeysKit/TrainedWeights.swift

Add `--json` for output another program can parse. The `KeysKit` library product is the same engine
for Swift code.

### How well it works

`common-keys eval --split heldOut` takes dictionary words the weights and character models never saw,
types each on its own keyboard and on the wrong one, and counts the results. Words whose wrong-keyboard
reading is itself a real word there, like `an` typed on Greek as `αν`, count neither way: leaving
them alone is right. On macOS 26 with 150 held-out words per language, hand-tuned rules against the
fitted model:

| Keyboards | Correct words changed, rules → model | Wrong-keyboard words fixed, rules → model |
|---|---|---|
| U.S. + Icelandic, Russian, Korean 2-Set, Greek, Hebrew, Arabic, French or German | 0 → 0 | 100% → 100% |
| U.S. + Thai | 0 → 0 | Thai on U.S. 58% → 100% |
| U.S. + Georgian QWERTY | 2 → 0 | Georgian on U.S. 0% → 100% |
| U.S. + Armenian HM QWERTY | 4 → 0 | Armenian on U.S. 51% → 100% |
| U.S. + each of 24 more listed languages, from Albanian to Urdu | 0–7 → 0 | typed on U.S., 1–75% → 95–100% |

Georgian and Armenian QWERTY layouts follow Latin sounds, so Georgian typed on U.S. reads as
plausible Latin (`iyo` for `იყო`). Rules alone could not tell, and changed `ორ` to `or`. Judging a
word takes about 0.05–0.3 ms.

### Limits

- Languages with neither a system dictionary nor a shipped word list, like Khmer, Lao or Burmese, rely on
  spelling rules and what you teach. Auto-fixing is cautious there, and the convert shortcut and
  learning carry it.
- Thai and other scripts written without spaces end a "word" only at a space.
- Text typed in a converting input method is never fixed: it is the user's pick.
- Korean 3-Set, romaja and shape-based Chinese methods are destinations for the convert shortcut
  only.

## Build from source

The Command Line Tools are enough; Xcode is not required.

```sh
scripts/dev-cert                          # once: a stable signing identity, see below
scripts/task build keys                        # build for this Mac → build/keys/Common Keys.app and build/keys/common-keys
mv "build/keys/Common Keys.app" /Applications/
```

`scripts/dev-cert` puts a self-signed "Common Tools Development" certificate in your login keychain, and
builds are signed with it. macOS ties the Accessibility grant to that certificate, so you allow
Common Keys once and it survives rebuilds. Without it, builds are signed ad-hoc and each one needs
the grant again.

## Development

Common Keys lives in `apps/keys/` of [oddurs/common-tools](https://github.com/oddurs/common-tools), the monorepo for every Common Tools app, and shares [CommonKit](../../packages/CommonKit) with them. From the repository root:

```sh
scripts/setup                      # once: wire the git hooks
scripts/dev-cert                   # optional, once: a stable signing identity, so permissions survive rebuilds
scripts/task run keys              # build, quit the running copy, open the new one
scripts/task check keys            # lint + test + build, what CI runs for this app
scripts/task test keys --filter=X  # only the tests whose name matches
```

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for the workflow: `scripts/agent start`, `scripts/agent ship`, and `scripts/release keys <version>`.

`swift build && .build/debug/CommonKeys --snapshot out.png` renders the menu's cards in light and dark
without opening the menu; add `--status` for the menu bar item instead: fixing, locked, and dimmed. `swift scripts/make-icon.swift` redraws the app icon.

Layout:

- `Sources/KeysKit`: the engine. Keys, keyboards, evidence and decisions, with no UI state.
- `Sources/CommonKeys`: the app: event tap and injection, status item and menu, Settings.
- `Sources/KeysCLI`: the `common-keys` command.
- `Tests/KeysKitTests`: unit tests, plus system and accuracy tests against the layouts and
  dictionaries installed on the Mac.

## Licence

MIT. See [LICENSE](../../LICENSE).

The word lists in `Sources/KeysKit/WordLists` are derived from the [Leipzig Corpora
Collection](https://wortschatz.uni-leipzig.de) (CC BY 4.0). Their corpora are built from Wikipedia
text (CC BY-SA 4.0), except Estonian and Latvian, which are built from news text. Each file names its
corpus. `scripts/wordlists` regenerates them.
