<script lang="ts">
	// 1200 × 630, the size Open Graph and X show a link's large card at. Always light: a shared card
	// can't follow the reader's appearance.
	import { asset } from '$app/paths';
	import { pages } from '#lib/pages.ts';
	import { promise } from '#lib/promise.ts';
	import { showcase, tool as app } from '#lib/tools.ts';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
	const tool = $derived(data.tool);
	const still = $derived(
		tool && (`${tool.slug}/features/${pages[tool.slug]?.card ?? 1}.jpg` as Parameters<typeof asset>[0])
	);
</script>

<svelte:head>
	<meta name="robots" content="noindex" />
</svelte:head>

<div id="card" data-theme="light">
	{#if tool}
		<div class="text">
			<img class="icon" src={asset(tool.icon)} alt="" width="112" height="112" />
			<p class="name">{tool.name}</p>
			<h1>{tool.tagline}</h1>
			<p class="family">
				<img src={asset('icon.svg')} alt="" width="26" height="26" />Common Tools for the Mac
			</p>
		</div>
		<img class="still" src={asset(still!)} alt="" />
	{:else}
		<div class="home">
			<p class="icons">
				{#each showcase.map(app) as t (t.slug)}
					<img src={asset(t.icon)} alt="" width="104" height="104" />
				{/each}
			</p>
			<h1>Common Tools</h1>
			<p class="lede">Small, native utilities for the Mac.</p>
			<p class="promise">{promise.short}</p>
		</div>
	{/if}
</div>

<style>
	#card {
		position: relative;
		width: 1200px;
		height: 630px;
		overflow: hidden;
		background: var(--surface-base);
		color: var(--text-primary);
	}
	h1,
	p {
		margin: 0;
	}

	/* An app: its icon, name, and tagline on the left; a still from its film, whole, on the right. */
	.text {
		position: absolute;
		left: 72px;
		top: 0;
		bottom: 0;
		width: 420px;
		display: flex;
		flex-direction: column;
		justify-content: center;
	}
	.icon {
		margin-left: -6px;
		filter: drop-shadow(var(--shadow-icon));
	}
	.name {
		margin-top: var(--space-lg);
		font: var(--weight-semibold) 30px/1.2 var(--font-sans);
		letter-spacing: -0.019em;
	}
	.text h1 {
		margin-top: var(--space-xs);
		font: var(--weight-semibold) 48px/1.08 var(--font-display);
		letter-spacing: var(--type-display-tracking);
		text-wrap: balance;
	}
	.family {
		position: absolute;
		bottom: 56px;
		display: flex;
		align-items: center;
		gap: var(--space-xs);
		font: var(--weight-regular) 20px/1 var(--font-sans);
		color: var(--text-secondary);
	}
	.still {
		position: absolute;
		right: 56px;
		top: 50%;
		translate: 0 -50%;
		width: 616px;
		border-radius: var(--radius-lg);
		box-shadow: var(--shadow-media);
	}

	/* The home page: the family, then the name. */
	.home {
		height: 100%;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		text-align: center;
	}
	.icons {
		display: flex;
		gap: 12px;
	}
	.icons img {
		filter: drop-shadow(var(--shadow-icon));
	}
	.home h1 {
		margin-top: var(--space-xl);
		font: var(--weight-semibold) 92px/1.05 var(--font-display);
		letter-spacing: var(--type-hero-tracking);
	}
	.lede {
		margin-top: var(--space-sm);
		font: var(--weight-regular) 34px/1.25 var(--font-sans);
		letter-spacing: -0.021em;
		color: var(--text-secondary);
	}
	.promise {
		margin-top: var(--space-xl);
		font: var(--weight-semibold) 22px/1 var(--font-sans);
		letter-spacing: -0.019em;
	}
</style>
