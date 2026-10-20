<script lang="ts">
	import DemoVideo from '#lib/DemoVideo.svelte';
	import GetStarted from '#lib/GetStarted.svelte';
	import Keys from '#lib/Keys.svelte';
	import Meta from '#lib/Meta.svelte';
	import MoreTools from '#lib/MoreTools.svelte';
	import ToolHero from '#lib/ToolHero.svelte';
	import WhatsNew from '#lib/WhatsNew.svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
	const tool = $derived(data.tool);
	const release = $derived(data.releases[tool.slug]);
</script>

<Meta
	title="{tool.name} — {tool.tagline.replace(/\.$/, '')}"
	description="{tool.name}: {tool.summary} Free and open source."
	path="{tool.slug}/"
	image="{tool.slug}/poster.jpg"
/>

<main>
	<ToolHero {tool} {release} docs={false} />
	<DemoVideo {tool} />

	<section class="features ruled">
		{#each tool.features ?? [] as [title, text] (title)}
			<div>
				<h2>{title}</h2>
				<p><Keys {text} /></p>
			</div>
		{/each}
	</section>

	{#if release}<WhatsNew {tool} {release} />{/if}
	<GetStarted {tool} />
	<MoreTools slug={tool.slug} />
</main>
