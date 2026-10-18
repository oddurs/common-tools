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
	description="A tiny macOS menu bar app that keeps the icons you rarely use in one folder, off the crowded menu bar and clear of the notch. Click the folder to open any of them. Free and open source."
	path="bar/"
	image="bar/poster.jpg"
/>

<main>
	<ToolHero tool={bar} {release} />
	<DemoVideo tool={bar} />

	<section class="features ruled">
		<div>
			<h2>One folder.</h2>
			<p>
				Every icon left of the More folder stays off the menu bar. The ones you use stay right of it,
				with the system's own.
			</p>
		</div>
		<div>
			<h2>Every icon, by its app.</h2>
			<p>
				Click More for a list of the icons in it, each with its app's icon and name. Choose one and it
				opens right there.
			</p>
		</div>
		<div>
			<h2>Clear of the notch.</h2>
			<p>
				Hidden icons stay off-screen rather than piling up behind the camera housing or the app's
				menus, so nothing reshuffles while you work.
			</p>
		</div>
		<div>
			<h2>One permission, when you need it.</h2>
			<p>
				Tidying needs none. The first time you open More, Common Bar asks for Accessibility, to see
				which app each icon belongs to and open it. No network unless you turn on the update check.
			</p>
		</div>
	</section>

	<section class="steps ruled">
		<h2>How it works.</h2>
		<ol>
			<li><b>Tidy.</b> Open Common Bar. Icons left of the More folder move off the menu bar.</li>
			<li><b>Find.</b> Click More to see them, each with its app.</li>
			<li><b>Open.</b> Choose one. Its menu opens, and the icon goes back when you're done.</li>
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
