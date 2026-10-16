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
			<h2>One chevron.</h2>
			<p>
				Everything left of the chevron is tucked out of sight. Click it to bring them back; they tuck
				themselves away again after a few seconds.
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
				Hold <kbd>⌘</kbd> over the menu bar and every icon shows. Drag one past the chevron with the system's own
				⌘-drag, and it's hidden.
			</p>
		</div>
		<div>
			<h2>Always hidden, if you like.</h2>
			<p>
				Turn on an always-hidden section for icons you almost never need. They stay out of every reveal until
				you
				<kbd>⌥</kbd>-click the chevron.
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
			<li><b>Hide.</b> Hold <kbd>⌘</kbd> and drag an icon past the chevron.</li>
			<li><b>Show.</b> Click the chevron, hover over empty menu bar space, or scroll down on the bar.</li>
			<li><b>Done.</b> They hide again by themselves once you've moved on.</li>
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
