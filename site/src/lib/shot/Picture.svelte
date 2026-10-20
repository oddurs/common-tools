<script lang="ts">
	// The shot itself: the part of the frozen screen that was picked, drawn at any size. The pick lies
	// inside the code pane, so it is the pane, clipped and scaled.
	import Code from './Code.svelte';
	import { pane } from './scene';
	import type { Rect } from './size';

	let { rect, width, height }: { rect: Rect; width: number; height: number } = $props();

	const k = $derived(width / rect.width);
</script>

<div class="picture" style:width="{width}px" style:height="{height}px">
	<div
		class="inner"
		style:transform="scale({k}, {height / rect.height}) translate({pane.x - rect.x}px, {pane.y -
			rect.y}px)"
	>
		<Code />
	</div>
</div>

<style>
	.picture {
		position: relative;
		overflow: hidden;
	}
	.inner {
		position: absolute;
		left: 0;
		top: 0;
		transform-origin: 0 0;
	}
</style>
