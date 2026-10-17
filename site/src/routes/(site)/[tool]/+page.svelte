<script lang="ts">
	import { asset } from '$app/paths';
	import Meta from '#lib/Meta.svelte';
	import MoreTools from '#lib/MoreTools.svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
	const app = $derived(data.app);
</script>

<Meta
	title="{app.name} — {app.tagline.replace(/\.$/, '')}"
	description="{app.name}: {app.summary} In development."
	path="{app.slug}/"
	image="stats/poster.jpg"
/>

<main>
	<header>
		<img src={asset(app.icon)} alt="" width="112" height="112" />
		<span class="soon">In development</span>
		<h1>{app.name}</h1>
		<p class="lede">{app.tagline}</p>
		<p class="summary">{app.summary}</p>
		<p class="fine">
			Not released yet. It's free and open source, like every Common Tools app. <a href={app.repo}
				>Follow it on GitHub ›</a
			>
		</p>
	</header>
	<MoreTools slug={app.slug} />
</main>

<style>
	header {
		text-align: center;
	}
	img {
		display: block;
		margin: 0 auto;
	}
	.soon {
		display: inline-block;
		margin-top: 18px;
		padding: 4px 12px;
		border-radius: 999px;
		background: var(--surface-card);
		color: var(--text-secondary);
		font-size: 13px;
		font-weight: 600;
	}
	.summary {
		max-width: 560px;
		margin: 18px auto 0;
		color: var(--text-secondary);
	}
</style>
