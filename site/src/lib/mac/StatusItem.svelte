<script lang="ts">
	// A menu bar extra as macOS 26 lays it out: its content centred in its slot, with the system's
	// padding either side, and the capsule the system draws behind it while its menu is open. A fixed
	// `width` is a slot (`statusSlot` for one symbol); without one the content sets the width.
	import type { Snippet } from 'svelte';
	import { statusPadding } from './geometry';

	let {
		open = false,
		width,
		label,
		children
	}: { open?: boolean; width?: number; label?: string; children: Snippet } = $props();
</script>

<span
	class="status-item"
	class:open
	style:width={width === undefined ? undefined : `${width}px`}
	style:padding="0 {width === undefined ? statusPadding : 0}px"
	aria-label={label}>{@render children()}</span
>

<style>
	.status-item {
		position: relative;
		flex: none;
		box-sizing: border-box;
		height: 100%;
		display: flex;
		align-items: center;
		justify-content: center;
	}
	/* The highlight: a capsule two points inside the menu bar, in the menu bar's own ink. */
	.status-item::before {
		content: '';
		position: absolute;
		inset: 2px 1px;
		border-radius: 999px;
		background: currentColor;
		opacity: 0;
	}
	.status-item.open::before {
		opacity: 0.12;
	}
	:global(.dark) .status-item.open::before {
		opacity: 0.2;
	}
</style>
