<script lang="ts">
	// The menu bar item as StatKit's BarRenderer draws it, at its sizes: a template image in the
	// menu bar's own ink, with captions and units at half strength and tracks at 11%. Each part sits
	// in the width the layout pass gives it (bar.ts), so the item never resizes as values change.
	import { captions, itemGap, partGap, partWidth, parts, type BarItem, type Metric } from './bar';
	import type { Readings } from './demo';
	import { percent, rate, storage } from './format';
	import Symbol from '../mac/Symbol.svelte';

	let { items, readings }: { items: BarItem[]; readings: Readings } = $props();

	/** BarRenderer's chart: 16 points tall in a 24-point menu bar, one point per sample. */
	const chart = { width: 30, height: 16 };
	/** The demo Mac's disk: 90 GB free; its battery: full and on power. */
	const free = 90e9;

	const last = (values: number[]) => values[values.length - 1];
	const tail = (values: number[]) => values.slice(-chart.width);

	function fraction(metric: Metric): number {
		if (metric === 'cpu') return last(readings.cpu);
		if (metric === 'gpu') return last(readings.gpu);
		if (metric === 'memory') return last(readings.memory);
		return metric === 'battery' ? 1 : 0.91;
	}
	/** The number and its unit, which BarRenderer sets in secondary ink. */
	function value(metric: Metric): [string, string] {
		if (metric === 'storage') return storage(free).split(' ') as [string, string];
		const text = percent(fraction(metric));
		return [text.slice(0, -1), '%'];
	}
	/** Outbound on top, matching the mirrored graph. */
	function pair(metric: Metric): [string, string][] {
		const r = readings;
		return metric === 'network'
			? [
					['↑', rate(last(r.up))],
					['↓', rate(last(r.down))]
				]
			: [
					['W', rate(last(r.write))],
					['R', rate(last(r.read))]
				];
	}

	/** One point-wide column per sample, right-aligned, as BarRenderer.area fills them. */
	function columns(values: number[], scale: number, top: number, height: number, down = false): string {
		const x0 = chart.width - values.length;
		return values
			.map((v, i) => {
				const h = (Math.min(Math.max(v / scale, 0), 1) * height).toFixed(2);
				return down
					? `M${x0 + i},${top}v${h}h1V${top}z`
					: `M${x0 + i},${top + height}v-${h}h1V${top + height}z`;
			})
			.join('');
	}
	function mirrored(metric: Metric) {
		const r = readings;
		const [inbound, outbound] = metric === 'network' ? [r.down, r.up] : [r.read, r.write];
		const floor = metric === 'disk' ? 1e6 : 64e3;
		const [down, up] = [tail(inbound), tail(outbound)];
		const peak = Math.max(...down, ...up, floor);
		const half = chart.height / 2;
		return { up: columns(up, peak, 0, half), down: columns(down, peak, half, half, true) };
	}
</script>

<div class="bar" style:gap="{itemGap}px">
	{#each items as item (item.metric)}
		<span class="cell" style:gap="{partGap}px">
			{#each parts(item) as part (part)}
				{@const width = partWidth(part, item.metric)}
				{#if part === 'caption'}
					<small class="caption" style:width="{width}px">{captions[item.metric]}</small>
				{:else if part === 'graph'}
					<svg width={chart.width} height={chart.height} viewBox="0 0 {chart.width} {chart.height}">
						<clipPath id="track-{item.metric}"
							><rect width={chart.width} height={chart.height} rx="3" /></clipPath
						>
						<rect width={chart.width} height={chart.height} rx="3" class="track" />
						<g clip-path="url(#track-{item.metric})">
							{#if item.metric === 'network' || item.metric === 'disk'}
								{@const m = mirrored(item.metric)}
								<!-- The midline says "two-way" even when the link is idle. -->
								<rect
									y={chart.height / 2 - 0.25}
									width={chart.width}
									height="0.5"
									class="midline"
								/>
								<path d={m.up} class="upper" />
								<path d={m.down} />
							{:else if item.metric === 'cpu'}
								<!-- Total load at half strength, the system's share of it at full. -->
								<path d={columns(tail(readings.cpu), 1, 0, chart.height)} class="secondary" />
								<path d={columns(tail(readings.system), 1, 0, chart.height)} />
							{:else}
								<path
									d={columns(
										tail(item.metric === 'gpu' ? readings.gpu : readings.memory),
										1,
										0,
										chart.height
									)}
									class="single"
								/>
							{/if}
						</g>
					</svg>
				{:else if part === 'gauge'}
					<span class="gauge"><i style:height="{fraction(item.metric) * 100}%"></i></span>
				{:else if item.metric === 'network' || item.metric === 'disk'}
					<span class="pair" style:width="{width}px">
						{#each pair(item.metric) as [glyph, amount] (glyph)}
							<span class="line"><b>{glyph}</b>{amount}</span>
						{/each}
					</span>
				{:else}
					{@const [number, unit] = value(item.metric)}
					<span class="stack" style:width="{width}px">
						<small>{captions[item.metric]}</small>
						<span class="value"
							>{#if item.metric === 'battery'}<span class="bolt"
									><Symbol name="bolt.fill" scale={0.5} /></span
								>{/if}{number}<b>{item.metric === 'storage' ? ` ${unit}` : unit}</b></span
						>
					</span>
				{/if}
			{/each}
		</span>
	{/each}
</div>

<style>
	.bar {
		display: flex;
		align-items: center;
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
	}
	svg {
		display: block;
		flex: none;
		fill: currentColor;
	}
	.track {
		opacity: 0.11;
	}
	.midline {
		opacity: 0.22;
	}
	.single {
		opacity: 0.85;
	}
	.secondary {
		opacity: 0.5;
	}
	.upper {
		opacity: 0.65;
	}
	.gauge {
		position: relative;
		flex: none;
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
		flex: none;
		display: flex;
		flex-direction: column;
		gap: 3.5px;
	}
	.stack {
		align-items: flex-end;
	}
	small,
	.value,
	.line {
		text-box: trim-both cap alphabetic;
	}
	small {
		font-size: 7.5px;
		font-weight: 600;
		letter-spacing: 0.4px;
		opacity: 0.5;
	}
	.caption {
		flex: none;
	}
	.value {
		display: flex;
		align-items: center;
		font-size: 10px;
		font-weight: 500;
	}
	.value b,
	.line b {
		font-weight: inherit;
		opacity: 0.5;
		white-space: pre;
	}
	.bolt {
		margin-right: 1px;
	}
	.pair {
		font-size: 9px;
		font-weight: 500;
	}
	.line {
		display: flex;
		justify-content: space-between;
	}
</style>
