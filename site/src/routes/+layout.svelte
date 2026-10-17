<script lang="ts">
	import '../app.css';
	import type { LayoutProps } from './$types';

	let { children }: LayoutProps = $props();
</script>

<svelte:head>
	<meta name="color-scheme" content="light dark" />
	<!-- Matches --bg, so Safari's toolbar blends into the page. -->
	<meta name="theme-color" content="#fbfbfd" media="(prefers-color-scheme: light)" />
	<meta name="theme-color" content="#000000" media="(prefers-color-scheme: dark)" />
</svelte:head>

{@render children()}
