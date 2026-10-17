<script lang="ts">
	import BarScene from '#lib/bar/Demo.svelte';
	import Player from '#lib/film/Player.svelte';
	import { films } from '#lib/film/films.ts';
	import KeysScene from '#lib/keys/Demo.svelte';
	import StatsScene from '#lib/stats/Demo.svelte';
	import { tool } from '#lib/tools.ts';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();

	const scenes = { stats: StatsScene, keys: KeysScene, bar: BarScene };
</script>

<Player scene={scenes[data.tool]} film={films[data.tool]} title={tool(data.tool).name} />
