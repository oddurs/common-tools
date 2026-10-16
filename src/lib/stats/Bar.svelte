<script lang="ts">
	// The menu bar item as the app draws it: one template colour, small caps captions, tiny graphs.
	import { graph, percent, rate } from './format';
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
	function value(item: BarItem): string {
		const r = readings;
		switch (item.metric) {
			case 'cpu':
				return percent(r.cpu);
			case 'gpu':
				return percent(r.gpu);
			case 'memory':
				return percent(r.memory * 100);
			case 'storage':
				return '64 GB';
			case 'battery':
				return '⚡︎99%';
			default:
				return '';
		}
	}
	const rates = (item: BarItem): [string, string, string, string] =>
		item.metric === 'network'
			? ['↑', rate(readings.up), '↓', rate(readings.down)]
			: ['W', rate(readings.write), 'R', rate(readings.read)];
</script>

<div class="bar">
	{#each items as item (item.metric)}
		<span class="item">
			{#if item.style === 'graph' || item.style === 'graphValue'}
				{@const h = history(item)}
				<svg class="graph" width="34" height="16" viewBox="0 0 34 16">
					<rect width="34" height="16" rx="3" class="well" />
					<path d={graph(h.values.slice(-34), 34, 16, h.max, true)} class="fill" />
				</svg>
			{/if}
			{#if item.style === 'gauge' || item.style === 'gaugeValue'}
				<span class="gauge"><i style:height="{level(item) * 100}%"></i></span>
			{/if}
			{#if item.style !== 'graph' && item.style !== 'gauge'}
				{#if item.metric === 'network' || item.metric === 'disk'}
					{@const [a, av, b, bv] = rates(item)}
					<span class="rates"><span><b>{a}</b> {av}</span><span><b>{b}</b> {bv}</span></span>
				{:else}
					<span class="value"><small>{captions[item.metric]}</small>{value(item)}</span>
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
		height: 22px;
		color: #1d1d1f;
		font:
			600 10.5px/1 -apple-system,
			BlinkMacSystemFont,
			sans-serif;
		font-variant-numeric: tabular-nums;
		letter-spacing: 0;
		white-space: nowrap;
	}
	.item {
		display: flex;
		align-items: center;
		gap: 4px;
	}
	.graph .well {
		fill: rgba(0, 0, 0, 0.12);
	}
	.graph .fill {
		fill: #1d1d1f;
	}
	.gauge {
		position: relative;
		width: 5px;
		height: 16px;
		border-radius: 3px;
		background: rgba(0, 0, 0, 0.16);
		overflow: hidden;
	}
	.gauge i {
		position: absolute;
		left: 0;
		right: 0;
		bottom: 0;
		background: #1d1d1f;
	}
	.value {
		display: flex;
		flex-direction: column;
		align-items: flex-end;
		font-size: 12px;
		line-height: 1;
	}
	.value small {
		font-size: 7.5px;
		font-weight: 600;
		opacity: 0.6;
		margin-bottom: 1px;
	}
	.rates {
		display: flex;
		flex-direction: column;
		align-items: flex-end;
		font-size: 9px;
		line-height: 1.05;
	}
	.rates b {
		opacity: 0.6;
	}
</style>
