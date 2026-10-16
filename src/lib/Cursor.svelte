<script lang="ts">
	// The macOS arrow, with a ring that pulses on click.
	let { x, y, pulse = 0 }: { x: number; y: number; pulse?: number } = $props();
</script>

<div class="cursor" style:transform="translate({x}px, {y}px)">
	{#if pulse > 0}
		<span
			class="ring"
			style:opacity={pulse}
			style:transform="translate(-50%, -50%) scale({1.6 - pulse * 0.6})"
		></span>
	{/if}
	<svg width="22" height="30" viewBox="0 0 22 30" aria-hidden="true">
		<path
			d="M2 2 L2 24 L7.5 18.8 L11.3 27.5 L14.8 26 L11.1 17.6 L18.6 17.6 Z"
			fill="#000"
			stroke="#fff"
			stroke-width="1.6"
			stroke-linejoin="round"
		/>
	</svg>
</div>

<style>
	.cursor {
		position: absolute;
		left: -2px;
		top: -2px;
		z-index: 20;
		pointer-events: none;
		filter: drop-shadow(0 1px 1.5px rgba(0, 0, 0, 0.35));
	}
	svg {
		display: block;
	}
	.ring {
		position: absolute;
		left: 2px;
		top: 2px;
		width: 34px;
		height: 34px;
		border-radius: 50%;
		background: rgba(0, 113, 227, 0.28);
	}
</style>
