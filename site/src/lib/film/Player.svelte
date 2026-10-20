<script lang="ts">
	import { asset } from '$app/paths';
	import { onMount, type Component } from 'svelte';
	import type { Film } from './director';

	let {
		scene: Scene,
		film,
		title
	}: {
		scene: Component<{ time: number; dark?: boolean }>;
		film: Film;
		title: string;
	} = $props();

	// Plays live, or holds still for `pnpm film`, which steps it with window.__seek.
	// ?dark draws the scene in dark mode. ?clean leaves out the overlay (caption, keys held, closing
	// card), for the stills on the apps' pages.
	let time = $state(0);
	let dark = $state(false);
	let clean = $state(false);

	onMount(() => {
		const params = new URLSearchParams(location.search);
		dark = params.has('dark');
		clean = params.has('clean');
		if (params.has('record')) {
			Object.assign(window, {
				__seek: (t: number) => (time = t),
				__duration: film.duration,
				__poster: film.poster,
				__marks: film.marks
			});
			return;
		}
		let frame = 0;
		const start = performance.now();
		const tick = (now: number) => {
			time = now - start;
			frame = requestAnimationFrame(tick);
		};
		frame = requestAnimationFrame(tick);
		return () => cancelAnimationFrame(frame);
	});
</script>

<svelte:head>
	<title>{title} demo</title>
	<meta name="robots" content="noindex" />
	<link rel="icon" href={asset('icon.svg')} />
</svelte:head>

<div class="center"><div id="stage" class:clean><Scene {time} {dark} /></div></div>

<style>
	:global(body) {
		background: #111;
	}
	.center {
		min-height: 100vh;
		display: grid;
		place-items: center;
	}
	#stage {
		width: 1280px;
		height: 800px;
	}
	/* The overlay draws nothing in a still. */
	#stage.clean :global(.overlay) {
		display: none;
	}
</style>
