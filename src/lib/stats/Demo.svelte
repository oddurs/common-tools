<script lang="ts">
	import Cursor from '../Cursor.svelte';
	import Overlay from '../mac/Overlay.svelte';
	import Screen from '../mac/Screen.svelte';
	import Stage from '../mac/Stage.svelte';
	import Symbol from '../mac/Symbol.svelte';
	import { statusSlot } from '../mac/geometry';
	import type { SymbolName } from '../mac/symbols';
	import { tool } from '../tools';
	import Bar from './Bar.svelte';
	import { frameAt, historyLength, layouts, stage } from './demo';
	import { graph, percent, rate } from './format';

	let { time, dark = false }: { time: number; dark?: boolean } = $props();

	const frame = $derived(frameAt(time));
	const r = $derived(frame.readings);
	const g = stage.graph;
	const hoverX = $derived(frame.hover === null ? 0 : g.width * (1 - frame.hover / (historyLength - 1)));
	const hoverValue = $derived(frame.hover === null ? 0 : r.cpuHistory[historyLength - 1 - frame.hover]);
	// Ring gauges: circumference of r = 24.
	const ring = 2 * Math.PI * 24;

	/** Other apps' menu bar extras, left of Common Stats. */
	const others: SymbolName[] = ['icloud.fill', 'music.note'];

	type Tile = { name: string; symbol: SymbolName; tint: string; level: number; label: string; note: string };
	const tiles: Tile[] = $derived([
		{
			name: 'GPU',
			symbol: 'square.stack.3d.up',
			tint: '#bf5af2',
			level: r.gpu / 100,
			label: percent(r.gpu),
			note: 'Utilization'
		},
		{
			name: 'Storage',
			symbol: 'internaldrive',
			tint: '#8e8e93',
			level: 0.87,
			label: '87%',
			note: '64 GB free'
		},
		{
			name: 'Battery',
			symbol: 'battery.75percent',
			tint: '#30d158',
			level: 0.99,
			label: '99%',
			note: '0:09 to full'
		}
	]);
</script>

<Stage {dark} opacity={frame.opacity}>
	<Screen {dark} camera={frame.camera} app="Finder" menus={['File', 'Edit', 'View', 'Go', 'Window', 'Help']}>
		{#snippet extras()}
			<div class="extras" style:right="{1728 - stage.itemRight}px">
				{#each others as symbol (symbol)}
					<span class="other" style:width="{statusSlot}px"><Symbol name={symbol} /></span>
				{/each}
				<span class="item" class:open={frame.menu > 0.5}>
					<Bar items={layouts[frame.layout]} readings={r} />
				</span>
			</div>
		{/snippet}

		{#snippet top()}
			{#if frame.menu > 0}
				<div
					class="menu"
					style:left="{stage.menu.x}px"
					style:top="{stage.menu.y}px"
					style:width="{stage.menu.width}px"
					style:opacity={frame.menu}
					style:transform="translateY({(1 - frame.menu) * -4}px)"
				>
					<section class="card">
						<header>
							<span class="tile" style:background="#0a84ff"><Symbol name="cpu" /></span><b>CPU</b><span
								class="big">{percent(r.cpu)}</span
							>
						</header>
						<svg class="chart" width={g.width} height={g.height} viewBox="0 0 {g.width} {g.height}">
							<path d={graph(r.cpuHistory, g.width, g.height, 100, true)} class="area" />
							<path d={graph(r.cpuHistory, g.width, g.height, 100)} class="line" />
							{#if frame.hover !== null}
								<line x1={hoverX} x2={hoverX} y1="0" y2={g.height} class="rule" />
								<circle cx={hoverX} cy={g.height - (hoverValue / 100) * g.height} r="4" class="dot" />
							{/if}
						</svg>
						{#if frame.hover !== null}
							<span class="tip" style:left="{Math.min(Math.max(hoverX - 70, 0), g.width - 150)}px"
								><b>{(frame.hover * 0.5).toFixed(0)}s ago</b> CPU {percent(hoverValue)}</span
							>
						{/if}
						<p class="legend">
							<span><i class="u"></i>User <b>{percent(r.user)}</b></span>
							<span><i class="s"></i>System <b>{percent(r.system)}</b></span>
							<span>Idle <b>{percent(100 - r.cpu)}</b></span>
						</p>
						<div class="cores">
							{#each r.cores as load, i (i)}
								<span class:gap={i === 4}><i style:height="{Math.max(0.12, load) * 100}%"></i></span>
							{/each}
						</div>
						<p class="legend small">
							<span>Efficiency <b>{percent(r.cpu * 0.9)}</b></span>
							<span>Performance <b>{percent(r.cpu * 1.05)}</b></span>
						</p>
					</section>

					<section class="card">
						<header>
							<span class="tile" style:background="#ff375f"><Symbol name="memorychip" /></span><b>Memory</b
							><span class="big">{(r.memory * 24).toFixed(0)} GB <small>of 24 GB</small></span>
						</header>
						<div class="membar">
							<i style:width="{r.memory * 45}%"></i><i class="w" style:width="{r.memory * 18}%"></i><i
								class="c"
								style:width="{r.memory * 37}%"
							></i>
						</div>
						<p class="legend">
							<span><i class="u"></i>App <b>{(r.memory * 24 * 0.45).toFixed(1)} GB</b></span>
							<span><i class="s"></i>Wired <b>{(r.memory * 24 * 0.18).toFixed(1)} GB</b></span>
							<span>Pressure <b class="ok">Normal</b></span>
						</p>
					</section>

					<section class="card">
						<header>
							<span class="tile" style:background="#5ac8fa"><Symbol name="network" /></span><b>Network</b><em
								>en0</em
							><span class="rates"><span>↓ {rate(r.down)}</span><span>↑ {rate(r.up)}</span></span>
						</header>
						<svg class="chart" width={g.width} height="30" viewBox="0 0 {g.width} 30">
							<path d={graph(r.netHistory, g.width, 30, 6, true)} class="area" />
							<path d={graph(r.netHistory, g.width, 30, 6)} class="line" />
						</svg>
					</section>

					<section class="card">
						<header>
							<span class="tile" style:background="#ff9f0a"><Symbol name="arrow.up.arrow.down" /></span><b
								>Disk</b
							><span class="rates"><span>R {rate(r.read)}</span><span>W {rate(r.write)}</span></span>
						</header>
						<svg class="chart" width={g.width} height="30" viewBox="0 0 {g.width} 30">
							<path d={graph(r.diskHistory, g.width, 30, 150, true)} class="area" />
							<path d={graph(r.diskHistory, g.width, 30, 150)} class="line" />
						</svg>
					</section>

					<div class="tiles">
						{#each tiles as t (t.name)}
							<section class="card ringcard">
								<header class="mini">
									<span class="tile" style:background={t.tint}><Symbol name={t.symbol} /></span><b>{t.name}</b
									>
								</header>
								<svg width="60" height="60" viewBox="0 0 60 60">
									<circle cx="30" cy="30" r="24" class="track" />
									<circle
										cx="30"
										cy="30"
										r="24"
										class="arc"
										stroke-dasharray="{ring * t.level} {ring}"
										transform="rotate(-90 30 30)"
									/>
									<text x="30" y="35">{t.label}</text>
								</svg>
								<small>{t.note}</small>
							</section>
						{/each}
					</div>
				</div>
			{/if}
			<Cursor x={frame.cursor.x} y={frame.cursor.y} pulse={frame.pulse} />
		{/snippet}
	</Screen>

	<Overlay caption={frame.caption} end={frame.end} tool={tool('stats')} />
</Stage>

<style>
	.extras {
		position: absolute;
		top: 0;
		height: 100%;
		display: flex;
		align-items: center;
	}
	.item {
		height: 21px;
		padding: 0 8px;
		display: flex;
		align-items: center;
		border-radius: 8px;
	}
	/* macOS 26 marks an open menu bar extra with a soft capsule. */
	.item.open {
		background: color-mix(in srgb, currentColor 14%, transparent);
	}
	.other {
		display: flex;
		justify-content: center;
	}

	/* A menu in macOS 26: Liquid Glass, larger corners. */
	.menu {
		position: absolute;
		z-index: 30;
		padding: 7px;
		border-radius: 16px;
		background: rgba(246, 246, 248, 0.82);
		backdrop-filter: blur(40px) saturate(1.8);
		box-shadow:
			inset 0 0.5px 0 rgba(255, 255, 255, 0.9),
			0 18px 50px rgba(0, 0, 0, 0.22),
			0 0 0 0.5px rgba(0, 0, 0, 0.14);
		display: flex;
		flex-direction: column;
		gap: 7px;
		font:
			13px/1.3 -apple-system,
			BlinkMacSystemFont,
			'SF Pro Text',
			sans-serif;
		font-variant-numeric: tabular-nums;
		color: #1d1d1f;
		text-shadow: none;
		--primary: #1d1d1f;
		--card: rgba(0, 0, 0, 0.04);
		--well: rgba(0, 0, 0, 0.05);
		--secondary: #6e6e73;
		--accent: #0a84ff;
		--accent-2: #7db8f7;
		--accent-3: #b5d5f8;
	}
	:global(.dark) .menu {
		background: rgba(36, 36, 40, 0.78);
		box-shadow:
			inset 0 0.5px 0 rgba(255, 255, 255, 0.22),
			0 18px 50px rgba(0, 0, 0, 0.5),
			0 0 0 0.5px rgba(255, 255, 255, 0.14);
		color: #f5f5f7;
		--primary: #f5f5f7;
		--card: rgba(255, 255, 255, 0.06);
		--well: rgba(255, 255, 255, 0.05);
		--secondary: #98989d;
		--accent-2: #2f6fc0;
		--accent-3: #1f4a85;
	}
	.card {
		position: relative;
		padding: 12px;
		border-radius: 11px;
		background: var(--card);
	}
	header {
		height: 26px;
		margin-bottom: 8px;
		display: flex;
		align-items: center;
		gap: 8px;
		font-size: 15px;
	}
	header em {
		font-style: normal;
		font-size: 13px;
		color: var(--secondary);
	}
	.tile {
		width: 24px;
		height: 24px;
		border-radius: 7px;
		display: grid;
		place-items: center;
		color: #fff;
	}
	.big {
		margin-left: auto;
		font-size: 19px;
		font-weight: 600;
	}
	.big small {
		font-size: 12px;
		font-weight: 400;
		color: var(--secondary);
	}
	.chart {
		display: block;
		border-radius: 7px;
		background: var(--well);
	}
	.area {
		fill: color-mix(in srgb, var(--accent) 24%, transparent);
	}
	.line {
		fill: none;
		stroke: var(--accent);
		stroke-width: 1.5;
	}
	.rule {
		stroke: var(--secondary);
		stroke-width: 1;
	}
	.dot {
		fill: #fff;
		stroke: var(--accent);
		stroke-width: 2;
	}
	.tip {
		position: absolute;
		top: 52px;
		margin-left: 12px;
		padding: 3px 10px;
		border-radius: 999px;
		background: rgba(255, 255, 255, 0.95);
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
		font-size: 12px;
		white-space: nowrap;
		color: #3a3a3c;
	}
	:global(.dark) .tip {
		background: rgba(58, 58, 62, 0.95);
		color: #f2f2f7;
	}
	.legend {
		margin: 8px 0 0;
		display: flex;
		gap: 12px;
		white-space: nowrap;
		font-size: 12px;
		color: var(--secondary);
	}
	.legend.small {
		margin-top: 6px;
	}
	.legend b {
		color: var(--primary);
		font-weight: 500;
	}
	.legend i {
		display: inline-block;
		width: 7px;
		height: 7px;
		margin-right: 5px;
		border-radius: 50%;
		background: var(--accent);
	}
	.legend i.s {
		background: var(--accent-2);
	}
	.legend .ok {
		color: #30d158;
	}
	.cores {
		margin-top: 10px;
		height: 18px;
		display: flex;
		gap: 3px;
	}
	.cores span {
		position: relative;
		flex: 1;
		border-radius: 3px;
		background: var(--well);
		overflow: hidden;
	}
	.cores span.gap {
		margin-left: 8px;
	}
	.cores i {
		position: absolute;
		left: 0;
		right: 0;
		bottom: 0;
		background: var(--accent);
	}
	.membar {
		height: 7px;
		display: flex;
		gap: 2px;
		border-radius: 4px;
		background: var(--well);
		overflow: hidden;
	}
	.membar i {
		background: var(--accent);
	}
	.membar i.w {
		background: var(--accent-2);
	}
	.membar i.c {
		background: var(--accent-3);
	}
	.rates {
		margin-left: auto;
		display: flex;
		gap: 10px;
		font-size: 13px;
		font-weight: 600;
		white-space: nowrap;
	}
	.tiles {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 7px;
	}
	.ringcard {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 6px;
		padding: 10px 6px;
	}
	.mini {
		height: 22px;
		margin: 0;
		font-size: 13px;
		gap: 6px;
	}
	.mini .tile {
		width: 20px;
		height: 20px;
		border-radius: 6px;
	}
	.ringcard small {
		font-size: 11px;
		color: var(--secondary);
	}
	.track {
		fill: none;
		stroke: var(--well);
		stroke-width: 6;
	}
	.arc {
		fill: none;
		stroke: var(--accent);
		stroke-width: 6;
		stroke-linecap: round;
	}
	text {
		font-size: 13px;
		font-weight: 600;
		text-anchor: middle;
		fill: currentColor;
	}
</style>
