<script lang="ts">
	// MenuBarPreview: the glyphs at their real size in a light and a dark bar, beside Wi-Fi, the
	// battery and the clock, as the first section of Settings and of each editor.
	import Symbol from '../mac/Symbol.svelte';
	import Glyph from './Glyph.svelte';
	import type { Source } from './demo';

	let { glyphs }: { glyphs: Source[] } = $props();
</script>

<div class="f-section f-preview">
	{#each ['light', 'dark'] as scheme (scheme)}
		<div class="f-bar {scheme}">
			{#each glyphs as source, i (i)}<Glyph {source} />{/each}
			<Symbol name="wifi" />
			<Symbol name="battery.75percent" scale={1.25} />
			<span>Fri 9:41</span>
		</div>
	{/each}
</div>
