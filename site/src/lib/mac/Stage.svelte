<script lang="ts">
	// The 1280 × 800 frame the recorder captures: the screen seen through the camera, plus the overlay.
	import type { Snippet } from 'svelte';

	let { dark, opacity, children }: { dark: boolean; opacity: number; children: Snippet } = $props();
</script>

<div class="stage" class:dark style:opacity>
	{@render children()}
</div>

<style>
	.stage {
		position: relative;
		width: 1280px;
		height: 800px;
		overflow: hidden;
		background: #000;
	}
</style>
