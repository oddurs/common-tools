<script lang="ts">
	import Film from '../film/Film.svelte';
	import StatusItem from '../mac/StatusItem.svelte';
	import Symbol from '../mac/Symbol.svelte';
	import { statusSlot } from '../mac/geometry';
	import type { SymbolName } from '../mac/symbols';
	import Bar from './Bar.svelte';
	import Menu from './Menu.svelte';
	import { frameAt, layouts, menu } from './demo';

	let { time, dark = false }: { time: number; dark?: boolean } = $props();

	const frame = $derived(frameAt(time));

	/** Other apps' menu bar extras, left of Common Stats. */
	const others: SymbolName[] = ['icloud.fill', 'music.note'];
</script>

<Film {frame} {dark} slug="stats" app="Finder" menus={['File', 'Edit', 'View', 'Go', 'Window', 'Help']}>
	{#snippet extras()}
		<div class="extras">
			{#each others as symbol (symbol)}
				<StatusItem width={statusSlot}><Symbol name={symbol} /></StatusItem>
			{/each}
			<StatusItem open={frame.menu > 0}>
				<Bar items={layouts[frame.layout]} readings={frame.readings} />
			</StatusItem>
		</div>
	{/snippet}

	{#snippet top()}
		{#if frame.menu > 0}
			<!-- An NSMenu under its status item: left edges aligned, just below the menu bar. -->
			<div
				class="dropdown"
				style:left="{menu.x}px"
				style:top="{menu.y}px"
				style:width="{menu.width}px"
				style:opacity={frame.menu}
			>
				<Menu readings={frame.readings} hover={frame.hover} />
			</div>
		{/if}
	{/snippet}
</Film>

<style>
	.extras {
		position: absolute;
		top: 0;
		right: 0;
		height: 100%;
		display: flex;
		align-items: center;
	}
	.dropdown {
		position: absolute;
		z-index: 30;
	}

	/* The menu (Menu.svelte) and its graphs (Chart.svelte), drawn in the macOS colours the scene uses. */
	.dropdown :global {
		/* A macOS 26 menu: Liquid Glass, 5 points above and below its items, panels edge to edge. */
		.menu {
			padding: 5px 0;
			border-radius: 16px;
			background: rgba(246, 246, 248, 0.8);
			backdrop-filter: blur(30px) saturate(1.8);
			box-shadow:
				inset 0 0.5px 0 rgba(255, 255, 255, 0.9),
				0 14px 44px rgba(0, 0, 0, 0.2),
				0 0 0 0.5px rgba(0, 0, 0, 0.12);
			font:
				13px/16px -apple-system,
				BlinkMacSystemFont,
				'SF Pro Text',
				sans-serif;
			font-variant-numeric: tabular-nums;
			letter-spacing: 0;
			text-shadow: none;
			color: var(--primary);
			--primary: rgba(0, 0, 0, 0.85);
			--secondary: rgba(0, 0, 0, 0.5);
			--tertiary: rgba(0, 0, 0, 0.26);
			--quaternary: rgba(0, 0, 0, 0.1);
			--card: rgba(0, 0, 0, 0.047);
			--hairline: rgba(0, 0, 0, 0.059);
			--material: rgba(255, 255, 255, 0.78);
			--strong: #007aff;
			--medium: rgba(0, 122, 255, 0.62);
			--soft: rgba(0, 122, 255, 0.36);
			--warning: #ff9500;
			--separator: rgba(0, 0, 0, 0.1);
		}

		.panel {
			padding: 4px 8px;
		}
		.box {
			display: flex;
			flex-direction: column;
			gap: 8px;
			padding: 12px;
			border-radius: 12px;
			background: var(--card);
			box-shadow: inset 0 0 0 0.5px var(--hairline);
		}
		header {
			display: flex;
			align-items: center;
			gap: 8px;
			height: 16px;
			white-space: nowrap;
		}
		header.tall {
			height: 19px;
		}
		.symbol {
			width: 18px;
			display: flex;
			justify-content: center;
			color: var(--secondary);
		}
		.name {
			font-weight: 700;
		}
		.big {
			margin-left: auto;
			font-size: 15px;
			line-height: 19px;
			font-weight: 600;
		}
		.big small {
			font-size: 11px;
			font-weight: 400;
			color: var(--secondary);
		}
		.source {
			font-size: 11px;
			color: var(--tertiary);
		}
		.rates {
			margin-left: auto;
			display: flex;
			gap: 8px;
			font-weight: 700;
		}
		.rates b {
			margin-right: 3px;
		}
		.strong {
			color: var(--strong);
		}
		.medium {
			color: var(--medium);
		}

		.facts {
			display: grid;
			justify-content: start;
			gap: 4px;
			font-size: 11px;
			line-height: 14px;
			white-space: nowrap;
		}
		.facts .label {
			display: flex;
			align-items: center;
			gap: 5px;
			color: var(--secondary);
		}
		.facts .value {
			padding-right: 12px;
		}
		.key {
			width: 6px;
			height: 6px;
			border-radius: 50%;
		}
		.key.strong {
			background: var(--strong);
		}
		.key.medium {
			background: var(--medium);
		}
		.key.soft {
			background: var(--soft);
		}

		.clusters {
			display: flex;
			gap: 8px;
		}
		.cluster {
			display: flex;
			flex-direction: column;
			gap: 4px;
		}
		.cores {
			display: flex;
			gap: 2px;
			height: 14px;
		}
		.cores span {
			position: relative;
			flex: 1;
			border-radius: 2px;
			background: var(--quaternary);
			overflow: hidden;
		}
		.cores i {
			position: absolute;
			left: 0;
			right: 0;
			bottom: 0;
			background: var(--strong);
		}
		.caption {
			margin: 0;
			font-size: 10px;
			line-height: 13px;
			white-space: nowrap;
		}
		.cluster .caption span {
			margin-right: 4px;
			color: var(--secondary);
		}

		.pressure {
			display: flex;
			align-items: center;
			gap: 8px;
		}
		.segments {
			flex: 1;
			height: 6px;
			display: flex;
			gap: 1.5px;
			border-radius: 3px;
			background: var(--quaternary);
			overflow: hidden;
		}
		.segments .strong {
			background: var(--strong);
		}
		.segments .medium {
			background: var(--medium);
		}
		.segments .soft {
			background: var(--soft);
		}
		/* Normal pressure stays neutral: the secondary label colour, its fill at 14%. */
		.pill {
			position: relative;
			display: flex;
			align-items: center;
			gap: 4px;
			padding: 3px 8px;
			border-radius: 999px;
			font-size: 10px;
			line-height: 13px;
			font-weight: 500;
			isolation: isolate;
		}
		.pill::before {
			content: '';
			position: absolute;
			inset: 0;
			z-index: -1;
			border-radius: inherit;
			background: var(--secondary);
			opacity: 0.14;
		}
		.pill i {
			width: 6px;
			height: 6px;
			border-radius: 50%;
			background: var(--secondary);
		}

		.tiles {
			display: flex;
			gap: 8px;
		}
		.tile {
			flex: 1;
			align-items: center;
		}
		header.small {
			align-self: stretch;
			height: 14px;
			gap: 4px;
			font-size: 11px;
		}
		header.small .symbol {
			width: 16px;
		}
		header.small .name {
			font-weight: 600;
		}
		svg {
			display: block;
			overflow: visible;
		}
		.track,
		.arc {
			fill: none;
			stroke-width: 5;
		}
		.track {
			stroke: var(--quaternary);
		}
		.arc {
			stroke: var(--strong);
			stroke-linecap: round;
		}
		.warn .arc {
			stroke: var(--warning);
		}
		text {
			font-size: 12px;
			font-weight: 600;
			text-anchor: middle;
			fill: var(--primary);
		}
		.tile .caption {
			color: var(--secondary);
		}

		hr {
			height: 1px;
			margin: 5px 14px;
			border: 0;
			background: var(--separator);
		}
		.item {
			height: 24px;
			margin: 0;
			padding: 0 14px;
			display: flex;
			align-items: center;
			white-space: nowrap;
		}
		.icon {
			width: 18px;
			margin-right: 6px;
			display: flex;
			justify-content: center;
		}
		kbd {
			margin-left: auto;
			font: inherit;
			color: var(--tertiary);
		}

		.chart {
			position: relative;
			border-radius: 8px;
			background: var(--card);
			overflow: hidden;
		}
		.grid {
			fill: var(--hairline);
			stroke: var(--hairline);
			stroke-width: 0;
		}
		.dashed {
			stroke-width: 0.5;
			stroke-dasharray: 2 3;
		}
		.band.strong,
		.dot.strong {
			fill: var(--strong);
		}
		.band.medium,
		.dot.medium {
			fill: var(--medium);
		}
		.band.soft,
		.dot.soft {
			fill: var(--soft);
		}
		stop.strong {
			stop-color: var(--strong);
		}
		stop.medium {
			stop-color: var(--medium);
		}
		stop.soft {
			stop-color: var(--soft);
		}
		.line {
			fill: none;
			stroke-width: 1.5;
			stroke-linecap: round;
			stroke-linejoin: round;
		}
		.line.strong {
			stroke: var(--strong);
		}
		.line.medium {
			stroke: var(--medium);
		}
		.rule {
			fill: var(--secondary);
		}
		.halo {
			fill: #fff;
		}
		.readback {
			position: absolute;
			top: 3px;
			display: flex;
			gap: 6px;
			padding: 2px 6px;
			border-radius: 999px;
			background: var(--material);
			backdrop-filter: blur(20px) saturate(1.6);
			box-shadow: inset 0 0 0 0.5px var(--hairline);
			font-size: 10px;
			line-height: 13px;
			font-weight: 500;
			white-space: pre;
			color: var(--primary);
		}
		.ago {
			color: var(--secondary);
		}
		.scale {
			position: absolute;
			left: 6px;
			top: 3px;
			font-size: 10px;
			line-height: 13px;
			font-weight: 500;
			color: var(--tertiary);
		}
	}
	:global(.dark) .dropdown :global {
		.menu {
			background: rgba(38, 38, 42, 0.78);
			box-shadow:
				inset 0 0.5px 0 rgba(255, 255, 255, 0.2),
				0 14px 44px rgba(0, 0, 0, 0.5),
				0 0 0 0.5px rgba(255, 255, 255, 0.12);
			--primary: rgba(255, 255, 255, 0.85);
			--secondary: rgba(255, 255, 255, 0.55);
			--tertiary: rgba(255, 255, 255, 0.25);
			--quaternary: rgba(255, 255, 255, 0.1);
			--card: rgba(255, 255, 255, 0.047);
			--hairline: rgba(255, 255, 255, 0.059);
			--material: rgba(64, 64, 68, 0.78);
			--strong: #0a84ff;
			--medium: rgba(10, 132, 255, 0.72);
			--soft: rgba(10, 132, 255, 0.5);
			--warning: #ff9f0a;
			--separator: rgba(255, 255, 255, 0.12);
		}
	}
</style>
