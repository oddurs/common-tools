<script lang="ts">
	// A tool's demo video, in the viewer's appearance. It plays only while on screen, never on its own
	// when the viewer asks for reduced motion, and has a pause button: moving content that lasts more
	// than five seconds needs one.
	import { asset } from '$app/paths';
	import { onMount } from 'svelte';
	import { films } from './film/films';
	import type { Tool } from './tools';

	let { tool, compact = false }: { tool: Tool; compact?: boolean } = $props();

	let video: HTMLVideoElement;
	let playing = $state(false);
	/** Set when the viewer pauses, so scrolling back into view doesn't override them. */
	let held = $state(false);

	const light = $derived(asset(`${tool.slug}/demo.mp4`));
	const dark = $derived(asset(`${tool.slug}/demo-dark.mp4`));
	// The poster is a picture behind the video rather than the poster attribute, so its media query
	// picks the appearance before any script runs. (A url() in a CSS variable would resolve against
	// the stylesheet's folder, not the page, and break under the base path.)
	const poster = $derived(asset(`${tool.slug}/poster.jpg`));
	const posterDark = $derived(asset(`${tool.slug}/poster-dark.jpg`));

	onMount(() => {
		held = matchMedia('(prefers-reduced-motion: reduce)').matches;
		// Open on the poster's moment, where something is happening, rather than the fade-in.
		const start = () => (video.currentTime = films[tool.slug].poster / 1000);
		if (video.readyState >= 1) start();
		else video.addEventListener('loadedmetadata', start, { once: true });
		const observer = new IntersectionObserver(
			([entry]) => {
				if (entry.isIntersecting && !held) video.play().catch(() => {});
				else video.pause();
			},
			{ threshold: 0.4 }
		);
		observer.observe(video);
		return () => observer.disconnect();
	});

	function toggle() {
		if (video.paused) {
			held = false;
			video.play().catch(() => {});
		} else {
			held = true;
			video.pause();
		}
	}
</script>

<figure class:compact>
	<picture>
		<source srcset={posterDark} media="(prefers-color-scheme: dark)" />
		<img src={poster} alt="" width="1280" height="800" loading={compact ? 'lazy' : 'eager'} />
	</picture>
	<video
		bind:this={video}
		muted
		loop
		playsinline
		preload={compact ? 'none' : 'metadata'}
		width="1280"
		height="800"
		aria-label={tool.demo}
		onplay={() => (playing = true)}
		onpause={() => (playing = false)}
	>
		<source src={dark} type="video/mp4" media="(prefers-color-scheme: dark)" />
		<source src={light} type="video/mp4" />
	</video>
	<button type="button" onclick={toggle} aria-label={playing ? 'Pause the demo' : 'Play the demo'}>
		{#if playing}
			<svg viewBox="0 0 16 16" aria-hidden="true"
				><rect x="3.5" y="2.5" width="3" height="11" rx="1" /><rect
					x="9.5"
					y="2.5"
					width="3"
					height="11"
					rx="1"
				/></svg
			>
		{:else}
			<svg viewBox="0 0 16 16" aria-hidden="true"
				><path
					d="M4.5 2.8v10.4a.6.6 0 0 0 .9.5l8.3-5.2a.6.6 0 0 0 0-1L5.4 2.3a.6.6 0 0 0-.9.5z"
				/></svg
			>
		{/if}
	</button>
</figure>

<style>
	figure {
		position: relative;
		margin: var(--space-xxxl) auto 0;
		border-radius: var(--radius-lg);
		overflow: hidden;
		box-shadow: var(--shadow-media);
		aspect-ratio: 16 / 10;
		background: var(--surface-media);
	}
	figure.compact {
		margin: 0;
		border-radius: var(--radius-md);
		box-shadow: var(--shadow-media-compact);
	}
	picture img,
	video {
		position: absolute;
		inset: 0;
		display: block;
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	button {
		position: absolute;
		right: var(--space-sm);
		bottom: var(--space-sm);
		width: 36px;
		height: 36px;
		display: grid;
		place-items: center;
		border: 0;
		border-radius: var(--radius-full);
		background: var(--surface-overlay);
		backdrop-filter: blur(12px);
		color: var(--text-inverse);
		cursor: pointer;
		opacity: 0.85;
		transition: opacity var(--duration-fast) var(--easing-standard);
	}
	button:hover,
	button:focus-visible {
		opacity: 1;
	}
	svg {
		width: 14px;
		height: 14px;
		fill: currentColor;
	}
	.compact button {
		width: 30px;
		height: 30px;
		right: var(--space-xs);
		bottom: var(--space-xs);
	}
	@media (max-width: 760px) {
		figure:not(.compact) {
			margin-top: var(--space-xxl);
			border-radius: var(--radius-md);
		}
	}
</style>
