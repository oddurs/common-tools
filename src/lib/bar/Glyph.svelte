<script lang="ts">
	// Stand-ins for other apps' menu bar icons: plain template shapes, so no real app is implied.
	import type { Glyph } from './demo';

	let { glyph }: { glyph: Glyph } = $props();
</script>

<svg width="18" height="18" viewBox="0 0 18 18" aria-hidden="true">
	{#if glyph === 'drop'}
		<path d="M9 2 L15 8 L9 16 L3 8 Z" />
	{:else if glyph === 'lock'}
		<rect x="3.5" y="8" width="11" height="8" rx="2" /><path d="M6 8 V6 a3 3 0 0 1 6 0 V8" class="stroke" />
	{:else if glyph === 'video'}
		<rect x="1.5" y="5" width="11" height="8" rx="2" /><path d="M13 9 L17 6 V12 Z" />
	{:else if glyph === 'note'}
		<path d="M7 3 L15 1.5 V12.5" class="stroke" /><path d="M7 3 V14" class="stroke" /><circle
			cx="5"
			cy="14"
			r="2.5"
		/><circle cx="13" cy="12.5" r="2.5" />
	{:else if glyph === 'bubble'}
		<path
			d="M3 3 H15 a1.5 1.5 0 0 1 1.5 1.5 V11 a1.5 1.5 0 0 1 -1.5 1.5 H8 L4.5 15.5 V12.5 H3 a1.5 1.5 0 0 1 -1.5 -1.5 V4.5 A1.5 1.5 0 0 1 3 3 Z"
		/>
	{:else if glyph === 'cloud'}
		<path d="M5 14 a3.5 3.5 0 0 1 -0.3 -7 a5 5 0 0 1 9.4 1.2 a2.9 2.9 0 0 1 -0.1 5.8 Z" />
	{:else if glyph === 'box'}
		<path d="M9 1.5 L16 5 V13 L9 16.5 L2 13 V5 Z M2 5 L9 8.5 L16 5 M9 8.5 V16.5" class="stroke" />
	{:else if glyph === 'bolt'}
		<path d="M10.5 1 L3.5 10 H8.5 L7.5 17 L14.5 8 H9.5 Z" />
	{:else if glyph === 'eye'}
		<path d="M1 9 C4 3.5 14 3.5 17 9 C14 14.5 4 14.5 1 9 Z" class="stroke" /><circle cx="9" cy="9" r="2.6" />
	{:else if glyph === 'clip'}
		<path d="M12 5 V12 a3 3 0 0 1 -6 0 V4 a2 2 0 0 1 4 0 V11.5" class="stroke" />
	{:else if glyph === 'cup'}
		<path d="M3 5 H13 V11 a4 4 0 0 1 -4 4 H7 a4 4 0 0 1 -4 -4 Z" /><path
			d="M13 7 h1.5 a2 2 0 0 1 0 4 H13"
			class="stroke"
		/>
	{:else if glyph === 'gauge'}
		<path d="M2.5 13 a6.5 6.5 0 1 1 13 0" class="stroke" /><path d="M9 13 L12.5 7.5" class="stroke" />
	{:else if glyph === 'globe'}
		<circle cx="9" cy="9" r="7" class="stroke" /><path
			d="M2 9 H16 M9 2 C5 6 5 12 9 16 C13 12 13 6 9 2"
			class="stroke"
		/>
	{:else if glyph === 'timer'}
		<circle cx="9" cy="10" r="6.5" class="stroke" /><path d="M9 10 V6.5 M7 1.5 H11" class="stroke" />
	{/if}
</svg>

<style>
	svg {
		display: block;
		fill: #1d1d1f;
	}
	.stroke {
		fill: none;
		stroke: #1d1d1f;
		stroke-width: 1.7;
		stroke-linecap: round;
		stroke-linejoin: round;
	}
</style>
