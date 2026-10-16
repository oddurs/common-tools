<script lang="ts">
	// An SF Symbol, drawn in the current text colour like a template image.
	import { asset } from '$app/paths';
	import { symbolSize, type SymbolName } from './symbols';

	let { name, scale = 1 }: { name: SymbolName; scale?: number } = $props();

	const size = $derived(symbolSize(name));
	const url = $derived(`url(${asset(`symbols/${name}.png` as Parameters<typeof asset>[0])})`);
</script>

<i
	class="symbol"
	style:width="{size.width * scale}px"
	style:height="{size.height * scale}px"
	style:mask-image={url}
	style:-webkit-mask-image={url}
></i>

<style>
	.symbol {
		display: block;
		flex: none;
		background: currentColor;
		mask-size: 100% 100%;
		-webkit-mask-size: 100% 100%;
	}
</style>
