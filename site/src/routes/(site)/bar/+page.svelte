<script lang="ts">
	import DemoVideo from '#lib/DemoVideo.svelte';
	import ToolHero from '#lib/ToolHero.svelte';
	import GetStarted from '#lib/GetStarted.svelte';
	import Meta from '#lib/Meta.svelte';
	import MoreTools from '#lib/MoreTools.svelte';
	import WhatsNew from '#lib/WhatsNew.svelte';
	import { tool } from '#lib/tools.ts';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();

	const bar = tool('bar');
	const release = $derived(data.releases.bar);
</script>

<Meta
	title="Common Bar — a tidy menu bar for macOS"
	description="A tiny macOS menu bar app that tucks away the icons you rarely use, behind a chevron. Click to show them, hold ⌘ to arrange. Free and open source."
	path="bar/"
	image="bar/poster.jpg"
/>

<main>
	<ToolHero tool={bar} {release} />
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
				Rest the pointer on empty menu bar space, pull down on the bar, or click its empty space, and
				the hidden icons appear. Push up to hide them again.
			</p>
		</div>
		<div>
			<h2>Hold ⌘ to arrange.</h2>
			<p>
				Hold <kbd>⌘</kbd> over the menu bar and every icon shows, with a thin line beside the chevron. Drag
				one past the line with the system's own ⌘-drag, and it's hidden.
			</p>
		</div>
		<div>
			<h2>Always hidden, if you like.</h2>
			<p>
				Turn on an always-hidden section for icons you almost never need. They stay out of every
				reveal until you
				<kbd>⌥</kbd>-click the chevron.
			</p>
		</div>
		<div>
			<h2>Notch-aware.</h2>
			<p>
				It starts beside the system icons, clear of the camera housing, and never pushes the chevron
				or your visible icons off-screen.
			</p>
		</div>
		<div>
			<h2>Nothing to grant.</h2>
			<p>
				No Accessibility or Screen Recording permission, no network, no account. A small Settings
				window picks how icons are revealed and how long they stay.
			</p>
		</div>
	</section>

	<section class="steps ruled">
		<h2>How it works.</h2>
		<ol>
			<li><b>Hide.</b> Hold <kbd>⌘</kbd> and drag an icon past the line beside the chevron.</li>
			<li>
				<b>Show.</b> Click the chevron, hover over empty menu bar space, or scroll down on the bar.
			</li>
			<li><b>Done.</b> They hide again by themselves once you've moved on.</li>
		</ol>
	</section>

	{#if release}<WhatsNew tool={bar} {release} />{/if}
	<GetStarted tool={bar} />
	<MoreTools slug={bar.slug} />
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
		color: var(--text-secondary);
	}
	li::before {
		content: counter(step);
		display: grid;
		place-items: center;
		width: 28px;
		height: 28px;
		margin-bottom: 10px;
		border-radius: 50%;
		background: var(--surface-card);
		color: var(--text-primary);
		font-weight: 600;
	}
	li b {
		color: var(--text-primary);
		font-weight: 600;
	}
	@media (max-width: 760px) {
		ol {
			grid-template-columns: 1fr;
			gap: 20px;
		}
	}
</style>
