<script lang="ts">
	import { onMount, type Component } from 'svelte';

	let {
		scene: Scene,
		duration,
		poster,
		title
	}: {
		scene: Component<{ time: number; dark?: boolean }>;
		duration: number;
		poster: number;
		title: string;
	} = $props();

	// Plays live, or holds still for the recorder, which steps it with window.__seek.
	// ?dark draws the scene in dark mode.
	let time = $state(0);
	let dark = $state(false);

	onMount(() => {
		const params = new URLSearchParams(location.search);
		dark = params.has('dark');
		if (params.has('record')) {
			Object.assign(window, {
				__seek: (t: number) => (time = t),
				__duration: duration,
				__poster: poster
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
</svelte:head>

<div class="center"><div id="stage"><Scene {time} {dark} /></div></div>

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
</style>
