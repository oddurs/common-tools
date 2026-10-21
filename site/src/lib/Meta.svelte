<script lang="ts">
	// Title, description, the card shown when a page is shared, and what the page is to a search
	// engine (lib/seo.ts).
	import { card } from './seo';
	import { site, type Tool } from './tools';

	let {
		title,
		description,
		path,
		tool,
		schema
	}: {
		title: string;
		description: string;
		path: string;
		/** Whose card to share: the app's, or the home page's when left out. */
		tool?: Tool;
		/** A schema.org description of the page, as JSON-LD. */
		schema?: object;
	} = $props();

	const url = $derived(new URL(path, site).href);
	const image = $derived(card(tool));
	// Escapes "<", so nothing in the JSON can close the script element it sits in.
	const jsonLd = $derived(schema && JSON.stringify(schema).replace(/</g, '\\u003c'));
</script>

<svelte:head>
	<title>{title}</title>
	<meta name="description" content={description} />
	<link rel="canonical" href={url} />
	<meta property="og:type" content="website" />
	<meta property="og:site_name" content="Common Tools" />
	<meta property="og:locale" content="en_US" />
	<meta property="og:title" content={title} />
	<meta property="og:description" content={description} />
	<meta property="og:url" content={url} />
	<meta property="og:image" content={new URL(image.image, site).href} />
	<meta property="og:image:width" content={String(image.width)} />
	<meta property="og:image:height" content={String(image.height)} />
	<meta property="og:image:alt" content={image.alt} />
	<meta name="twitter:card" content="summary_large_image" />
	{#if jsonLd}
		{@html `<script type="application/ld+json">${jsonLd}</script>`}
	{/if}
</svelte:head>
