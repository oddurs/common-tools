<script lang="ts">
	// The menu bar item as StatKit's BarRenderer draws it, at its sizes: a template image in the
	// menu bar's own ink, with captions and units at half strength and tracks at 11%. Cells are
	// 11 points apart and their parts 3; values sit in a fixed width so the item never resizes.
	import { percent, rate } from './format';
	import type { BarItem, Readings } from './demo';

	let { items, readings }: { items: BarItem[]; readings: Readings } = $props();

	const captions = {
		cpu: 'CPU',
		gpu: 'GPU',
		memory: 'MEM',
		network: 'NET',
		disk: 'DISK',
		storage: 'FREE',
		battery: 'BAT'
	};
	/** BarRenderer's chart: 30 points wide at regular density, 16 tall in a 24-point menu bar. */
	const chart = { width: 30, height: 16 };

	function level(item: BarItem): number {
		const r = readings;
		return {
			cpu: r.cpu / 100,
			gpu: r.gpu / 100,
			memory: r.memory,
			network: 0,
			disk: 0,
			storage: 0.87,
			battery: 0.99
		}[item.metric];
	}
	function history(item: BarItem): { values: number[]; max: number } {
		const r = readings;
		if (item.metric === 'network') return { values: r.netHistory, max: 6 };
		if (item.metric === 'disk') return { values: r.diskHistory, max: 150 };
		if (item.metric === 'gpu') return { values: r.cpuHistory.map((v) => v * 0.4), max: 100 };
		return { values: r.cpuHistory, max: 100 };
	}
	/** The number and its unit, which BarRenderer sets in secondary ink. */
	function value(item: BarItem): [string, string] {
		const r = readings;
		switch (item.metric) {
			case 'cpu':
				return [percent(r.cpu).slice(0, -1), '%'];
			case 'gpu':
				return [percent(r.gpu).slice(0, -1), '%'];
			case 'memory':
				return [percent(r.memory * 100).slice(0, -1), '%'];
			case 'storage':
				return ['64', ' GB'];
			case 'battery':
				return ['⚡︎99', '%'];
			default:
				return ['', ''];
		}
	}
	const rates = (item: BarItem): [string, string][] =>
		item.metric === 'network'
			? [
					['↑', rate(readings.up)],
					['↓', rate(readings.down)]
				]
			: [
					['W', rate(readings.write)],
					['R', rate(readings.read)]
				];
	/** One point-wide column per sample, newest at the right, as BarRenderer.area fills them. */
	function columns(values: number[], max: number): string {
		const { width, height } = chart;
		return values
			.slice(-width)
			.map((v, i) => {
				const h = (Math.min(Math.max(v / max, 0), 1) * height).toFixed(2);
				return `M${i},${height}v-${h}h1V${height}z`;
			})
			.join('');
	}
</script>

<div class="bar">
	{#each items as item (item.metric)}
		<span class="cell">
			{#if item.style === 'graph' || item.style === 'graphValue'}
				{@const h = history(item)}
				<svg width={chart.width} height={chart.height} viewBox="0 0 {chart.width} {chart.height}">
					<rect width={chart.width} height={chart.height} rx="3" class="track" />
					{#if item.metric === 'cpu'}
						<!-- Total load at half strength, the system's share of it at full. -->
						<path d={columns(h.values, h.max)} class="secondary" />
						<path
							d={columns(
								h.values.map((v) => v * 0.64),
								h.max
							)}
						/>
					{:else}
						<path d={columns(h.values, h.max)} class="mark" />
					{/if}
				</svg>
			{/if}
			{#if item.style === 'gauge' || item.style === 'gaugeValue'}
				<span class="gauge"><i style:height="{level(item) * 100}%"></i></span>
			{/if}
			{#if item.style !== 'graph' && item.style !== 'gauge'}
				{#if item.metric === 'network' || item.metric === 'disk'}
					<span class="pair">
						{#each rates(item) as [glyph, amount] (glyph)}
							<span class="line"><b>{glyph}</b>{amount}</span>
						{/each}
					</span>
				{:else}
					{@const [number, unit] = value(item)}
					<span class="stack">
						<small>{captions[item.metric]}</small>
						<span class="value">{number}<b>{unit}</b></span>
					</span>
				{/if}
			{/if}
		</span>
	{/each}
</div>

<style>
	.bar {
		display: flex;
		align-items: center;
		gap: 11px;
		height: 24px;
		font-family: -apple-system, BlinkMacSystemFont, sans-serif;
		font-variant-numeric: tabular-nums;
		letter-spacing: 0;
		white-space: nowrap;
		text-shadow: none;
	}
	.cell {
		display: flex;
		align-items: center;
		gap: 3px;
	}
	svg {
		display: block;
		fill: currentColor;
	}
	.track {
		opacity: 0.11;
	}
	.mark {
		opacity: 0.85;
	}
	.secondary {
		opacity: 0.5;
	}
	.gauge {
		position: relative;
		width: 4px;
		height: 16px;
		border-radius: 2px;
		overflow: hidden;
	}
	.gauge::before {
		content: '';
		position: absolute;
		inset: 0;
		background: currentColor;
		opacity: 0.11;
	}
	.gauge i {
		position: absolute;
		left: 0;
		right: 0;
		bottom: 0;
		background: currentColor;
	}
	/* Caption over value, trimmed to cap height and 3.5 points apart, as twoLineBaselines sets them. */
	.stack,
	.pair {
		display: flex;
		flex-direction: column;
		gap: 3.5px;
	}
	.stack {
		align-items: flex-end;
		min-width: 27px;
	}
	.stack small,
	.value,
	.line {
		text-box: trim-both cap alphabetic;
	}
	.stack small {
		font-size: 7.5px;
		font-weight: 600;
		letter-spacing: 0.4px;
		opacity: 0.5;
	}
	.value {
		font-size: 10px;
		font-weight: 500;
	}
	.value b,
	.line b {
		font-weight: inherit;
		opacity: 0.5;
	}
	.pair {
		width: 47px;
		font-size: 9px;
		font-weight: 500;
	}
	.line {
		display: flex;
		justify-content: space-between;
	}
</style>
