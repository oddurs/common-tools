<script lang="ts">
	// An app's page, the same for every app, as Apple lays out a product: the name and what it's for,
	// the film, a few features each with a still, then how to get it.
	import DemoVideo from '#lib/DemoVideo.svelte';
	import Feature from '#lib/Feature.svelte';
	import GetStarted from '#lib/GetStarted.svelte';
	import Meta from '#lib/Meta.svelte';
	import MoreTools from '#lib/MoreTools.svelte';
	import ToolHero from '#lib/ToolHero.svelte';
	import { pages } from '#lib/pages.ts';
	import { appSchema, description, title } from '#lib/seo.ts';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
	const tool = $derived(data.tool);
	const release = $derived(data.releases[tool.slug]);
	const features = $derived(pages[tool.slug]?.features ?? []);
</script>

<Meta
	title={title(tool)}
	description={description(tool)}
	path="{tool.slug}/"
	{tool}
	schema={appSchema(tool, release)}
/>

<main>
	<ToolHero {tool} {release} />
	<DemoVideo {tool} />

	{#each features as feature, index (feature.title)}
		<Feature slug={tool.slug} {feature} {index} />
	{/each}

	<GetStarted {tool} />
	<MoreTools slug={tool.slug} />
</main>
