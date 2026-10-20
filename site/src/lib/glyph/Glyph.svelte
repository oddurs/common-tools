<script lang="ts">
	// One glyph as Common Glyph draws it, `height` points tall at its trimmed shape's proportions.
	// Template styles (the star, the silhouette, the kaomoji) take the ink of whatever they sit on;
	// the picture, the lifted cat, and the emoji keep their own colours. The star and the kaomoji are
	// masks rendered by Common Glyph's own text path (Imaging.frames(ofText:), trimmed, Silhouette).
	import kaomoji from './kaomoji.png';
	import star from './star.png';
	import Mochi from './Mochi.svelte';
	import { glyphSize, type Source } from './demo';

	let { source, height = 20, fit }: { source: Source; height?: number; fit?: number } = $props();

	/** As a tile draws it, fitted inside a `fit`-point square; otherwise `height` tall. */
	const size = $derived.by(() => {
		const { width: w, height: h } = glyphSize[source];
		if (fit === undefined) return { width: (w / h) * height, height };
		const k = fit / Math.max(w, h);
		return { width: w * k, height: h * k };
	});
	const masks: Partial<Record<Source, string>> = { star, kaomoji };
	const mask = $derived(masks[source]);
</script>

{#if mask}
	<i
		class="mask"
		style:width="{size.width}px"
		style:height="{size.height}px"
		style:mask-image="url({mask})"
		style:-webkit-mask-image="url({mask})"
	></i>
{:else if source === 'flower'}
	<span
		class="emoji"
		style:width="{size.width}px"
		style:height="{size.height}px"
		style:font-size="{size.height * 1.06}px">🌸</span
	>
{:else}
	<Mochi mode={source as 'photo' | 'subject' | 'silhouette'} width={size.width} height={size.height} />
{/if}

<style>
	.mask {
		display: block;
		flex: none;
		background: currentColor;
		mask-size: 100% 100%;
		-webkit-mask-size: 100% 100%;
	}
	.emoji {
		display: flex;
		flex: none;
		align-items: center;
		justify-content: center;
		line-height: 1;
		text-shadow: none;
	}
</style>
