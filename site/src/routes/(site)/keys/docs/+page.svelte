<script lang="ts">
	import Docs from '#lib/Docs.svelte';
	import Install from '#lib/Install.svelte';
	import { page } from '$app/state';
	import { releasesOf, tool } from '#lib/tools.ts';
	import { asset } from '$app/paths';

	const keys = tool('keys');
	const cli = $derived(
		page.data.releases?.keys
			? page.data.releases.keys.download.replace(/CommonKeys\.zip$/, 'common-keys.zip')
			: releasesOf(keys)
	);
	const sections: [string, string][] = [
		['install', 'Install'],
		['fixing', 'How fixing works'],
		['shortcuts', 'Shortcuts'],
		['apps', 'Per-app layouts'],
		['learning', 'What it learns'],
		['menu', 'The menu'],
		['settings', 'Settings'],
		['limits', 'Limits'],
		['cli', 'The common-keys command'],
		['source', 'Build from source']
	];
</script>

<Docs tool={keys} {sections}>
	<h2 id="install">Install</h2>
	<Install tool={keys} />
	<p class="callout">
		Missed the prompt? Choose <b>Allow Accessibility Access…</b> from the menu; it opens the right pane.
		If Common Keys is already on there, that switch belongs to an earlier copy: choose
		<b>Reset and Ask Again…</b>.
	</p>

	<h2 id="fixing">How fixing works</h2>
	<p>
		Type a word on the wrong layout and press space. Common Keys reads the keys you pressed on each
		keyboard you have, picks the reading that's a real word, replaces it, and switches to that layout:
	</p>
	<ul>
		<li><code>/etta</code> on U.S. becomes <b>þetta</b> and switches to Icelandic.</li>
		<li><code>ghbdtn</code> becomes <b>привет</b>, <code>dkssud</code> becomes <b>안녕</b>.</li>
	</ul>
	<p>
		A small bubble shows the fix, what was there before, and <kbd>⌘Z</kbd>. Press <kbd>⌘Z</kbd> right after
		a fix to undo it; that word is left alone from then on.
	</p>
	<p>
		It changes a word only when the evidence is clear: the system spell checker, spelling rules no word
		breaks (a Hebrew final letter mid-word, two scripts in one word), the language recognizer, and what
		you've taught it. Paths, links, and password fields are left alone.
	</p>

	<h2 id="shortcuts">Shortcuts</h2>
	<table>
		<thead><tr><th>Shortcut</th><th>Does</th></tr></thead>
		<tbody>
			<tr
				><td>Double-tap right <kbd>⌥</kbd></td><td
					>Convert the word before the cursor to your other layout, or undo a fix made a moment ago.</td
				></tr
			>
			<tr><td><kbd>⌥⇧Space</kbd></td><td>Switch to the next layout.</td></tr>
			<tr><td><kbd>⌘Z</kbd> after a fix</td><td>Undo it, and never fix that word again.</td></tr>
		</tbody>
	</table>
	<p>
		Change both in <b>Settings › Shortcuts</b>. Convert can be a double tap of <kbd>⇧</kbd>, right
		<kbd>⌥</kbd>, or
		<kbd>⌃</kbd>, or off.
	</p>

	<h2 id="apps">Per-app layouts</h2>
	<p>
		Switch apps and you get the layout you last used there, or the one you usually write in. A switch in
		one app never leaks into the next.
	</p>
	<p>
		To pin an app to one layout or pause Common Keys in it, use <b>In &lt;App&gt;</b> in the menu, or
		<b>Settings › Exceptions</b>. Terminals and code editors start paused.
	</p>

	<h2 id="learning">What it learns</h2>
	<p>
		Erase a word and type the same keys again on another layout, or use the convert shortcut, and it
		remembers the word and the keys you mixed up. It also learns which language you write in each app.
	</p>
	<p>
		Everything stays on your Mac, in <code>~/Library/Application Support/Common Keys/memory.json</code>.
		<b>Settings › Learning › Forget Everything…</b> clears it. No network, no telemetry, no account.
	</p>

	<h2 id="menu">The menu</h2>
	<p>
		The menu bar shows the current layout's flag. In an app pinned to that layout a lock sits beside it.
		The flag is dimmed while Common Keys isn't fixing: without Accessibility access, after
		<b>Pause Fixing</b>, or in an app paused without a pin. Its menu opens with cards for today's fixes,
		the languages you wrote in each app, the week, what it has learned, and the keys you mix up most.
		Below them are your layouts (with the preferred one marked), <b>Next Layout</b>, the front app's
		settings,
		<b>Pause Fixing</b>, <b>Settings…</b>, and <b>Quit</b>.
	</p>

	<img
		src={asset('keys/menu.png')}
		alt="The menu's cards in light, dark, and on a first day: today's fixes by hour, languages by app, the week, words learned, and the keys you mix up most."
		width="2112"
		height="856"
	/>

	<h2 id="settings">Settings</h2>
	<p>Choose <b>Settings…</b> from the menu, or open Common Keys again while it's running. In order:</p>
	<ul>
		<li><b>Shortcuts</b>: the next-layout shortcut, and how to convert the last word.</li>
		<li><b>Exceptions</b>: apps pinned to one layout or paused. Only installed apps are listed.</li>
		<li><b>Learning</b>: what it has learned so far, and <b>Forget Everything…</b>.</li>
		<li><b>General</b>: <b>Open at login</b>.</li>
		<li><b>Common Tools</b>: the other Common Tools apps, and the version you're running.</li>
	</ul>

	<h2 id="limits">Limits</h2>
	<ul>
		<li>
			Languages without a system dictionary, like Thai, Khmer, or Georgian, rely on spelling rules and
			what you teach. Auto-fixing is cautious there.
		</li>
		<li>Thai and other scripts written without spaces end a "word" only at a space.</li>
		<li>
			Text typed in a converting input method (Japanese, Chinese) is never fixed: what you picked is
			yours.
		</li>
		<li>
			Korean 3-Set, romaja, and shape-based Chinese methods are destinations for the convert shortcut
			only.
		</li>
	</ul>

	<h2 id="cli">The common-keys command</h2>
	<p>
		The engine is a Swift library, <code>KeysKit</code>, and a command-line tool. Download
		<a href={cli}><code>common-keys.zip</code></a> from the same release, or build it from source.
	</p>
	<pre><code
			>common-keys sources [--all]
common-keys convert ghbdtn --from US --to Russian    # привет
common-keys convert 안녕하세요 --from 2SetKorean --to US  # dkssudgktpdy
common-keys detect /etta --from US                   # þetta  com.apple.keylayout.Icelandic
common-keys eval --keyboards US,Russian --words 150</code
		></pre>
	<p>Add <code>--json</code> for output another program can parse.</p>

	<h2 id="source">Build from source</h2>
	<pre><code
			>git clone https://github.com/oddurs/common-tools
cd common-tools
scripts/dev-cert keys        # once: a stable signing identity, so Accessibility survives rebuilds
scripts/task build keys      # → build/keys/Common Keys.app and build/keys/common-keys</code
		></pre>
</Docs>
