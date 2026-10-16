<script lang="ts">
	import DemoVideo from '#lib/DemoVideo.svelte';
	import ToolHero from '#lib/ToolHero.svelte';
	import { tool } from '#lib/tools.ts';

	const bar = tool('bar');
</script>

<svelte:head>
	<title>Common Bar — hide menu bar icons behind one line</title>
	<meta
		name="description"
		content="A tiny macOS menu bar app that hides the icons you rarely use behind an invisible divider. Click to show them, hold ⌘ to rearrange. Free and open source."
	/>
</svelte:head>

<main>
	<ToolHero tool={bar} />
	<DemoVideo tool={bar} />

	<section class="features ruled">
		<div>
			<h2>One line.</h2>
			<p>
				Everything left of the divider is tucked out of sight. Click the chevron to bring it back; it tucks
				itself away again after a few seconds.
			</p>
		</div>
		<div>
			<h2>Reach without aiming.</h2>
			<p>
				Rest the pointer on empty menu bar space, pull down on the bar, or click its empty space, and the
				hidden icons appear. Push up to hide them again.
			</p>
		</div>
		<div>
			<h2>Hold ⌘ to arrange.</h2>
			<p>
				Hold <kbd>⌘</kbd> over the menu bar and the divider appears. Drag icons across it with the system's own
				⌘-drag. Let go and they're hidden.
			</p>
		</div>
		<div>
			<h2>Always hidden.</h2>
			<p>
				A second, dotted divider keeps the icons you almost never need out of every reveal. <kbd>⌥</kbd>-click
				the chevron to see those too.
			</p>
		</div>
		<div>
			<h2>Notch-aware.</h2>
			<p>
				It starts beside the system icons, clear of the camera housing, and never pushes the chevron or your
				visible icons off-screen.
			</p>
		</div>
		<div>
			<h2>Nothing to grant.</h2>
			<p>
				No Accessibility or Screen Recording permission, no network, no account. A small Settings window picks
				how icons are revealed and how long they stay.
			</p>
		</div>
	</section>

	<section class="steps ruled">
		<h2>How it works.</h2>
		<ol>
			<li><b>Hide.</b> Hold <kbd>⌘</kbd> and drag icons to the left of the line.</li>
			<li><b>Show.</b> Click the chevron, hover over empty menu bar space, or scroll down on the bar.</li>
			<li>
				<b>Rearrange.</b> Hold <kbd>⌘</kbd> over the menu bar at any time to see the line and move things across
				it.
			</li>
		</ol>
	</section>
</main>

<style>
	ol {
		margin: 16px 0 0;
		padding: 0;
		list-style: none;
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 40px;
		counter-reset: step;
	}
	li {
		counter-increment: step;
		font-size: 15px;
		color: var(--secondary);
	}
	li::before {
		content: counter(step);
		display: grid;
		place-items: center;
		width: 28px;
		height: 28px;
		margin-bottom: 10px;
		border-radius: 50%;
		background: var(--panel);
		color: var(--text);
		font-weight: 600;
	}
	li b {
		color: var(--text);
		font-weight: 600;
	}
	@media (max-width: 760px) {
		ol {
			grid-template-columns: 1fr;
			gap: 20px;
		}
	}
</style>
