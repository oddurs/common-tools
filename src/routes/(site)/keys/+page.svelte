<script lang="ts">
	import DemoVideo from '#lib/DemoVideo.svelte';
	import ToolHero from '#lib/ToolHero.svelte';
	import { tool } from '#lib/tools.ts';

	const keys = tool('keys');

	const accuracy = [
		['U.S. + Icelandic', '0 of 300', '97% (most words read the same on both)'],
		['U.S. + Russian', '0 of 300', '98% · 100%'],
		['U.S. + Korean 2-Set', '0 of 300', '100% · 100%'],
		['U.S. + Greek', '0 of 300', '99% · 97%'],
		['U.S. + Hebrew', '0 of 300', '93% · 97%'],
		['U.S. + Arabic', '0 of 300', '88% · 98%'],
		['U.S. + French', '0 of 300', '100% · 92%'],
		['U.S. + German', '0 of 300', '97% · 82%']
	];
</script>

<svelte:head>
	<title>Common Keys — fixes words typed on the wrong keyboard</title>
	<meta
		name="description"
		content="A native macOS menu bar app that fixes words typed on the wrong keyboard layout, for every keyboard macOS has. It learns how you type, and nothing leaves your Mac."
	/>
</svelte:head>

<main>
	<ToolHero tool={keys} />
	<DemoVideo tool={keys} />

	<section class="features ruled">
		<div>
			<h2>Every keyboard.</h2>
			<p>
				All 251 layouts in macOS, across 35 scripts, read with the system's own key tables. Korean and
				Vietnamese input compose both ways; Japanese and Chinese get the keys you meant.
			</p>
		</div>
		<div>
			<h2>Learns you.</h2>
			<p>
				Erase a word and type it again on another layout, and it remembers the word and the keys you mix up.
				Press <kbd>⌘Z</kbd> after a fix and it leaves that word alone from then on.
			</p>
		</div>
		<div>
			<h2>Knows your apps.</h2>
			<p>
				Switch apps and you get the layout you last used there, or the one you usually write in. A switch in
				one app never leaks into the next.
			</p>
		</div>
		<div>
			<h2>Careful.</h2>
			<p>
				It changes a word only when the evidence is clear: dictionaries, spelling rules no word breaks, and
				what you've taught it. Paths, links and passwords are left alone.
			</p>
		</div>
		<div>
			<h2>Private.</h2>
			<p>
				Every keystroke stays on your Mac. No network, no telemetry, no account. What it learns is one file
				you can read or delete.
			</p>
		</div>
		<div>
			<h2>Set and forget.</h2>
			<p>
				Nothing to configure. A flag in the menu bar, a menu that shows your day, and a settings page with two
				shortcuts on it. Judging a word takes about 0.13 ms.
			</p>
		</div>
	</section>

	<section class="ruled">
		<h2>Measured, not promised.</h2>
		<p class="muted">
			<code>worldkey eval</code> types 150 dictionary words per language on the right keyboard and on the wrong
			one, and counts what happens.
		</p>
		<table>
			<thead>
				<tr><th>Keyboards</th><th>Correct words changed</th><th>Wrong-keyboard words fixed</th></tr>
			</thead>
			<tbody>
				{#each accuracy as [keyboards, changed, fixed] (keyboards)}
					<tr><td>{keyboards}</td><td>{changed}</td><td>{fixed}</td></tr>
				{/each}
			</tbody>
		</table>
		<p class="muted">
			Most misses are short words that are real in both languages, like <em>an</em> and <em>αν</em>, where
			leaving them alone is right.
		</p>
	</section>

	<section class="engine ruled">
		<div>
			<h2>WorldKey inside.</h2>
			<p class="muted">
				The engine that reads keys on any keyboard is a Swift library and a command-line tool, so scripts and
				other input tools can use it too.
			</p>
		</div>
		<pre><code
				><span class="prompt">$</span> worldkey convert ghbdtn --from US --to Russian
привет
<span class="prompt">$</span> worldkey detect /etta --from US
þetta	com.apple.keylayout.Icelandic
<span class="prompt">$</span> worldkey convert 안녕하세요 --from 2SetKorean --to US
dkssudgktpdy</code
			></pre>
	</section>
</main>

<style>
	td:first-child {
		font-weight: 500;
	}
	.engine {
		display: grid;
		grid-template-columns: 1fr 1.4fr;
		gap: 40px;
		align-items: center;
	}
	.prompt {
		color: var(--secondary);
		user-select: none;
	}
	@media (max-width: 760px) {
		.engine {
			grid-template-columns: 1fr;
			gap: 28px;
		}
	}
</style>
