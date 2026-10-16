<script lang="ts">
	// The system arrow, rendered from NSCursor.arrow, placed by its hot spot.
	import { asset } from '$app/paths';
	import { cursor } from './mac/symbols';

	let { x, y, pulse = 0 }: { x: number; y: number; pulse?: number } = $props();
</script>

<div class="cursor" style:transform="translate({x - cursor.x}px, {y - cursor.y}px)">
	{#if pulse > 0}
		<span
			class="ring"
			style:left="{cursor.x}px"
			style:top="{cursor.y}px"
			style:opacity={pulse * 0.9}
			style:transform="translate(-50%, -50%) scale({1.5 - pulse * 0.5})"
		></span>
	{/if}
	<img src={asset('symbols/cursor.png')} alt="" width={cursor.width} height={cursor.height} />
</div>

<style>
	.cursor {
		position: absolute;
		left: 0;
		top: 0;
		z-index: 50;
		pointer-events: none;
	}
	img {
		display: block;
		position: relative;
	}
	.ring {
		position: absolute;
		width: 30px;
		height: 30px;
		border-radius: 50%;
		background: rgba(10, 132, 255, 0.3);
	}
</style>
