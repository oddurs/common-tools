<script lang="ts">
	// Title, description, and the cards shown when a page is shared.
	import { site } from './tools';

	let {
		title,
		description,
		path,
		image
	}: { title: string; description: string; path: string; image: string } = $props();

	const url = $derived(new URL(path, site).href);
	const imageUrl = $derived(new URL(image, site).href);
</script>

<svelte:head>
	<title>{title}</title>
	<meta name="description" content={description} />
	<link rel="canonical" href={url} />
	<meta property="og:type" content="website" />
	<meta property="og:site_name" content="Common Tools" />
	<meta property="og:title" content={title} />
	<meta property="og:description" content={description} />
	<meta property="og:url" content={url} />
	<meta property="og:image" content={imageUrl} />
	<meta property="og:image:width" content="2560" />
	<meta property="og:image:height" content="1600" />
	<meta name="twitter:card" content="summary_large_image" />
</svelte:head>
