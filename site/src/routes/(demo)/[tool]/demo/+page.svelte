<script lang="ts">
	import type { Component } from 'svelte';
	import Player from '#lib/film/Player.svelte';
	import { films } from '#lib/film/films.ts';
	import { app } from '#lib/tools.ts';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();

	// Each app's scene sits beside its film, in src/lib/<app>/Demo.svelte.
	const scenes = import.meta.glob<{ default: Component<{ time: number; dark?: boolean }> }>(
		'../../../../lib/*/Demo.svelte',
		{ eager: true }
	);
	const scene = $derived(scenes[`../../../../lib/${data.tool}/Demo.svelte`].default);
</script>

<Player {scene} film={films[data.tool]!} title={app(data.tool).name} />
