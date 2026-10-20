<script lang="ts">
	// Common Stats' menu as apps/stats/Sources/CommonStats/Dropdown.swift builds it: a Card per
	// metric in menu bar order, then a row of ring tiles, then the standard items StatusItemController
	// adds. Colours are the default palette (the accent colour) in its three shades; symbols are plain
	// and secondary; only a warning takes its own colour. Sizes are macOS text styles in points:
	// headline 13 bold, title3 15, subheadline 11, footnote and caption2 10, callout 12. Its styles
	// live in Demo.svelte with the scene's other macOS colours.
	import Symbol from '../mac/Symbol.svelte';
	import type { SymbolName } from '../mac/symbols';
	import Chart, { type Series } from './Chart.svelte';
	import { clusters, memoryTotal, type Readings } from './demo';
	import { memory, percent, rate, storage, uptime } from './format';

	let { readings: r, hover }: { readings: Readings; hover: number | null } = $props();

	const last = (values: number[]) => values[values.length - 1];
	const cpu = $derived(last(r.cpu));
	const system = $derived(last(r.system));
	const used = $derived(last(r.memory) * memoryTotal);
	const peak = (floor: number, ...values: number[][]) => Math.max(floor, ...values.flat());

	const cpuSeries: Series[] = $derived([
		{ name: 'CPU', values: r.cpu, ink: 'strong', emphasis: true },
		{ name: 'System', values: r.system, ink: 'soft', emphasis: false }
	]);

	/** CoreClusters: bars keep one width across groups, 8 apart between groups and 2 within. */
	const inner = 320 - 2 * (8 + 12);
	const coreCount = clusters.efficiency + clusters.performance;
	const bar = (inner - 8 - 2 * (coreCount - 2)) / coreCount;
	const groups = $derived([
		{ kind: 'Efficiency', cores: r.cores.slice(0, clusters.efficiency) },
		{ kind: 'Performance', cores: r.cores.slice(clusters.efficiency) }
	]);
	const mean = (values: number[]) => values.reduce((a, b) => a + b, 0) / values.length;

	/** The demo Mac: 9 percent of a 1 TB disk free, and a battery that has finished charging. */
	const disk = { capacity: 994.66e9, free: 90e9 };

	type Fact = { label: string; value: string; key?: 'strong' | 'medium' | 'soft' };
	type Tile = {
		name: string;
		symbol: SymbolName;
		fraction: number;
		center: string;
		caption: string;
		warn?: boolean;
	};
	const tiles: Tile[] = $derived([
		{
			name: 'GPU',
			symbol: 'square.stack.3d.up',
			fraction: last(r.gpu),
			center: percent(last(r.gpu)),
			caption: 'Utilization'
		},
		{
			name: 'Storage',
			symbol: 'internaldrive',
			fraction: 1 - disk.free / disk.capacity,
			center: percent(1 - disk.free / disk.capacity),
			caption: `${storage(disk.free)} free`,
			// Ninety percent full or more: the warning colour, as MetricTile.ringInk picks it.
			warn: true
		},
		{ name: 'Battery', symbol: 'battery.75percent', fraction: 1, center: '100%', caption: 'Charged' }
	]);
	const ring = 2 * Math.PI * 24;
</script>

{#snippet facts(list: Fact[], columns: number)}
	<div class="facts" style:grid-template-columns="repeat({columns}, auto auto)">
		{#each list as fact (fact.label)}
			<span class="label"
				>{#if fact.key}<i class="key {fact.key}"></i>{/if}{fact.label}</span
			>
			<span class="value">{fact.value}</span>
		{/each}
	</div>
{/snippet}

{#snippet heading(symbol: SymbolName, name: string)}
	<span class="symbol"><Symbol name={symbol} /></span><b class="name">{name}</b>
{/snippet}

<div class="menu">
	<div class="panel">
		<section class="box">
			<header class="tall">
				{@render heading('cpu', 'CPU')}
				<span class="big">{percent(cpu)}</span>
			</header>
			<Chart id="cpu" width={inner} up={cpuSeries} peak={1} format={percent} {hover} />
			{@render facts(
				[
					{ label: 'User', value: percent(cpu - system), key: 'strong' },
					{ label: 'System', value: percent(system), key: 'soft' },
					{ label: 'Idle', value: percent(1 - cpu) }
				],
				3
			)}
			<div class="clusters">
				{#each groups as group (group.kind)}
					<div
						class="cluster"
						style:width="{bar * group.cores.length + 2 * (group.cores.length - 1)}px"
					>
						<div class="cores">
							{#each group.cores as load, i (i)}
								<span><i style:height="{Math.min(Math.max(load, 0), 1) * 14}px"></i></span>
							{/each}
						</div>
						<p class="caption"><span>{group.kind}</span>{percent(mean(group.cores))}</p>
					</div>
				{/each}
			</div>
			{@render facts(
				[
					{ label: 'Load', value: r.load.map((l) => l.toFixed(2)).join(' ') },
					{ label: 'Uptime', value: uptime(6 * 86_400 + 4 * 3600 + 17 * 60) }
				],
				2
			)}
		</section>
	</div>

	<div class="panel">
		<section class="box">
			<header class="tall">
				{@render heading('memorychip', 'Memory')}
				<span class="big">{memory(used)} <small>of {memory(memoryTotal)}</small></span>
			</header>
			<div class="pressure">
				<div class="segments">
					{#each [r.memoryParts.app, r.memoryParts.wired, r.memoryParts.compressed] as part, i (i)}
						<i
							class={['strong', 'medium', 'soft'][i]}
							style:width="calc({(part / memoryTotal) * 100}% - 1.5px)"
						></i>
					{/each}
				</div>
				<span class="pill"><i></i>Normal</span>
			</div>
			<Chart
				id="memory"
				width={inner}
				height={30}
				up={[{ name: 'Used', values: r.memory, ink: 'strong', emphasis: true }]}
				peak={1}
				format={percent}
			/>
			{@render facts(
				[
					{ label: 'App', value: memory(r.memoryParts.app), key: 'strong' },
					{ label: 'Wired', value: memory(r.memoryParts.wired), key: 'medium' },
					{ label: 'Compressed', value: memory(r.memoryParts.compressed), key: 'soft' },
					{ label: 'Cached', value: memory(r.memoryParts.cached) },
					{ label: 'Swap', value: memory(r.memoryParts.swap) }
				],
				2
			)}
		</section>
	</div>

	{#each [{ name: 'Network', symbol: 'network', glyphs: ['↓', '↑'], series: [r.down, r.up], names: ['Download', 'Upload'], floor: 64e3 }, { name: 'Disk', symbol: 'arrow.up.arrow.down', glyphs: ['R', 'W'], series: [r.read, r.write], names: ['Read', 'Write'], floor: 1e6 }] as const as card (card.name)}
		<div class="panel">
			<section class="box">
				<header>
					{@render heading(card.symbol, card.name)}
					{#if card.name === 'Network'}<span class="source">en0</span>{/if}
					<span class="rates">
						<span><b class="strong">{card.glyphs[0]}</b>{rate(last(card.series[0]))}</span>
						<span><b class="medium">{card.glyphs[1]}</b>{rate(last(card.series[1]))}</span>
					</span>
				</header>
				<Chart
					id={card.name}
					width={inner}
					up={[{ name: card.names[1], values: [...card.series[1]], ink: 'medium', emphasis: true }]}
					down={[
						{ name: card.names[0], values: [...card.series[0]], ink: 'strong', emphasis: true }
					]}
					peak={peak(card.floor, card.series[0], card.series[1])}
					format={rate}
				/>
			</section>
		</div>
	{/each}

	<div class="panel tiles">
		{#each tiles as tile (tile.name)}
			<section class="box tile">
				<header class="small">
					<span class="symbol"><Symbol name={tile.symbol} /></span><b class="name">{tile.name}</b>
				</header>
				<svg width="48" height="48" viewBox="0 0 48 48" class:warn={tile.warn}>
					<circle cx="24" cy="24" r="24" class="track" />
					<circle
						cx="24"
						cy="24"
						r="24"
						class="arc"
						stroke-dasharray="{ring * tile.fraction} {ring}"
						transform="rotate(-90 24 24)"
					/>
					<text x="24" y="24" dominant-baseline="central">{tile.center}</text>
				</svg>
				<p class="caption">{tile.caption}</p>
			</section>
		{/each}
	</div>

	<hr />
	<p class="item">
		<span class="icon"><Symbol name="gauge.with.dots.needle.67percent" /></span>Open Activity Monitor
	</p>
	<p class="item"><span class="icon"><Symbol name="gear" /></span>Settings…<kbd>⌘,</kbd></p>
	<p class="item"><span class="icon"><Symbol name="Quit_app" /></span>Quit Common Stats<kbd>⌘Q</kbd></p>
</div>
