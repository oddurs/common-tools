<script lang="ts">
	// A macOS 26 document window: rounded corners, traffic lights, a unified title bar.
	import type { Snippet } from 'svelte';

	let {
		title,
		x,
		y,
		width,
		height,
		front = true,
		children
	}: {
		title: string;
		x: number;
		y: number;
		width: number;
		height: number;
		front?: boolean;
		children?: Snippet;
	} = $props();
</script>

<section
	class="window"
	class:front
	style:left="{x}px"
	style:top="{y}px"
	style:width="{width}px"
	style:height="{height}px"
>
	<header>
		<span class="lights"><i></i><i></i><i></i></span>
		<span class="title">{title}</span>
	</header>
	<div class="body">{@render children?.()}</div>
</section>

<style>
	.window {
		position: absolute;
		border-radius: 22px;
		overflow: hidden;
		background: var(--window, #fff);
		box-shadow:
			0 30px 80px rgba(0, 0, 0, 0.28),
			0 0 0 0.5px rgba(0, 0, 0, 0.22);
		color: var(--window-text, #1d1d1f);
		--window: #fff;
		--window-text: #1d1d1f;
		--title: #3c3c43;
		--rule: rgba(0, 0, 0, 0.08);
	}
	:global(.dark) .window {
		--window: #1e1e20;
		--window-text: #f2f2f7;
		--title: #d1d1d6;
		--rule: rgba(255, 255, 255, 0.08);
		box-shadow:
			0 30px 80px rgba(0, 0, 0, 0.6),
			0 0 0 0.5px rgba(255, 255, 255, 0.16);
	}
	.window:not(.front) {
		filter: saturate(0.85);
	}
	header {
		height: 52px;
		display: flex;
		align-items: center;
		padding: 0 20px;
		border-bottom: 1px solid var(--rule);
	}
	.lights {
		display: flex;
		gap: 9px;
	}
	.lights i {
		width: 13px;
		height: 13px;
		border-radius: 50%;
		background: #ff5f57;
		box-shadow: inset 0 0 0 0.5px rgba(0, 0, 0, 0.12);
	}
	.lights i:nth-child(2) {
		background: #febc2e;
	}
	.lights i:nth-child(3) {
		background: #28c840;
	}
	.window:not(.front) .lights i {
		background: rgba(128, 128, 128, 0.35);
	}
	.title {
		flex: 1;
		margin-right: 57px;
		text-align: center;
		font-size: 13px;
		font-weight: 600;
		color: var(--title);
	}
	.window:not(.front) .title {
		opacity: 0.55;
	}
	.body {
		position: relative;
	}
</style>
