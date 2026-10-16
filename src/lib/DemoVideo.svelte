<script lang="ts">
	import { asset } from '$app/paths';
	import type { Tool } from './tools';

	let { tool }: { tool: Tool } = $props();

	const light = $derived(asset(`${tool.slug}/demo.mp4`));
	const dark = $derived(asset(`${tool.slug}/demo-dark.mp4`));
	// The posters are CSS backgrounds rather than the poster attribute, so the media query in the
	// stylesheet picks the one that matches the appearance before any script runs.
	const posters = $derived(
		`--poster: url(${asset(`${tool.slug}/poster.jpg`)}); --poster-dark: url(${asset(`${tool.slug}/poster-dark.jpg`)})`
	);
</script>

<figure style={posters}>
	<video autoplay muted loop playsinline width="1280" height="800" aria-label={tool.demo}>
		<source src={dark} type="video/mp4" media="(prefers-color-scheme: dark)" />
		<source src={light} type="video/mp4" />
	</video>
</figure>

<style>
	figure {
		margin: 56px auto 0;
		border-radius: 18px;
		overflow: hidden;
		box-shadow: 0 20px 60px rgba(0, 0, 0, 0.18);
		aspect-ratio: 16 / 10;
		background: var(--video) var(--poster) center / cover no-repeat;
	}
	@media (prefers-color-scheme: dark) {
		figure {
			background-image: var(--poster-dark);
			box-shadow:
				0 20px 60px rgba(0, 0, 0, 0.5),
				0 0 0 1px rgba(255, 255, 255, 0.08);
		}
	}
	video {
		display: block;
		width: 100%;
		height: 100%;
	}
	@media (max-width: 760px) {
		figure {
			margin-top: 40px;
			border-radius: 12px;
		}
	}
</style>
