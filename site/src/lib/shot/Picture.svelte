<script lang="ts">
	// The shot itself: the part of the frozen screen that was picked, drawn at any size and never
	// stretched: fitted and centred, as the preview's image view and the history's tiles fit it. The
	// pick lies inside the code pane, so it is the pane, clipped and scaled.
	import Code from './Code.svelte';
	import { pane } from './scene';
	import type { Rect } from './size';

	let { rect, width, height, dark }: { rect: Rect; width: number; height: number; dark: boolean } =
		$props();

	const k = $derived(Math.min(width / rect.width, height / rect.height));
	const dx = $derived((width - rect.width * k) / 2);
	const dy = $derived((height - rect.height * k) / 2);
</script>

<div class="picture" style:width="{width}px" style:height="{height}px">
	<div
		class="inner"
		style:transform="translate({dx}px, {dy}px) scale({k}) translate({pane.x - rect.x}px, {pane.y -
			rect.y}px)"
	>
		<Code {dark} />
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
