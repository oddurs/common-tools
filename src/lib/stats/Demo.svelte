<script lang="ts">
	import Cursor from '../Cursor.svelte';
	import Bar from './Bar.svelte';
	import { frameAt, historyLength, layouts, stage } from './demo';
	import { graph, percent, rate } from './format';

	let { time }: { time: number } = $props();

	const frame = $derived(frameAt(time));
	const r = $derived(frame.readings);
	const g = stage.graph;
	const hoverX = $derived(frame.hover === null ? 0 : g.width * (1 - frame.hover / (historyLength - 1)));
	const hoverValue = $derived(frame.hover === null ? 0 : r.cpuHistory[historyLength - 1 - frame.hover]);
	// Ring gauges: circumference of r = 26.
	const ring = 2 * Math.PI * 26;
</script>

<div class="stage" style:opacity={frame.opacity}>
	<div class="menubar">
		<span class="apple"></span>
		<span class="app">Finder</span>
		<span>File</span><span>Edit</span><span>View</span><span>Go</span><span>Window</span>
		<span class="spacer"></span>
		<span class="item" class:open={frame.menu > 0.5}><Bar items={layouts[frame.layout]} readings={r} /></span>
		<span class="clock">Thu 9:41</span>
	</div>

	{#if frame.lens > 0}
		<div class="lens" style:opacity={frame.lens} style:transform="translateY({(1 - frame.lens) * -8}px)">
			<div class="zoom"><Bar items={layouts[frame.layout]} readings={r} /></div>
		</div>
	{/if}

	{#if frame.menu > 0}
		<div
			class="menu"
			style:left="{stage.menu.x}px"
			style:top="{stage.menu.y}px"
			style:width="{stage.menu.width}px"
			style:opacity={frame.menu}
		>
			<section class="card">
				<header><span class="icon cpu">▣</span><b>CPU</b><span class="big">{percent(r.cpu)}</span></header>
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
			</section>

			<section class="card">
				<header>
					<span class="icon mem">▤</span><b>Memory</b><span class="big"
						>{(r.memory * 24).toFixed(0)} GB <small>of 24 GB</small></span
					>
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
					<span class="icon net">◍</span><b>Network</b><span class="rates"
						><span>↓ {rate(r.down)}</span><span>↑ {rate(r.up)}</span></span
					>
				</header>
				<svg class="chart small" width={g.width} height="34" viewBox="0 0 {g.width} 34">
					<path d={graph(r.netHistory, g.width, 34, 6, true)} class="area" />
					<path d={graph(r.netHistory, g.width, 34, 6)} class="line" />
				</svg>
			</section>

			<div class="tiles">
				{#each [['GPU', r.gpu / 100, percent(r.gpu), 'Utilization'], ['Storage', 0.87, '87%', '64 GB free'], ['Battery', 0.99, '99%', '0:09 to full']] as const as [name, level, label, note] (name)}
					<section class="card tile">
						<b>{name}</b>
						<svg width="64" height="64" viewBox="0 0 64 64">
							<circle cx="32" cy="32" r="26" class="track" />
							<circle
								cx="32"
								cy="32"
								r="26"
								class="arc"
								stroke-dasharray="{ring * level} {ring}"
								transform="rotate(-90 32 32)"
							/>
							<text x="32" y="37">{label}</text>
						</svg>
						<small>{note}</small>
					</section>
				{/each}
			</div>
		</div>
	{/if}

	{#if frame.caption}
		<p class="caption">{frame.caption}</p>
	{/if}

	<Cursor x={frame.cursor.x} y={frame.cursor.y} pulse={frame.pulse} />
</div>

<style>
	.stage {
		position: relative;
		width: 1280px;
		height: 800px;
		overflow: hidden;
		background: linear-gradient(160deg, #c9d6ff 0%, #e4e4ea 55%, #f5d7c4 100%);
		font:
			15px/1.4 -apple-system,
			BlinkMacSystemFont,
			'SF Pro Text',
			sans-serif;
		color: #1d1d1f;
		letter-spacing: -0.01em;
		-webkit-font-smoothing: antialiased;
	}

	.menubar {
		height: 30px;
		padding: 0 18px;
		display: flex;
		align-items: center;
		gap: 20px;
		background: rgba(246, 246, 246, 0.82);
		backdrop-filter: blur(20px);
		font-size: 14px;
	}
	.apple {
		font-size: 17px;
	}
	.app {
		font-weight: 700;
	}
	.spacer {
		flex: 1;
	}
	.item {
		padding: 0 6px;
		border-radius: 5px;
	}
	.item.open {
		background: rgba(0, 0, 0, 0.1);
	}

	.lens {
		position: absolute;
		right: 70px;
		top: 52px;
		padding: 18px 26px;
		border-radius: 22px;
		background: rgba(246, 246, 246, 0.94);
		box-shadow:
			0 20px 60px rgba(0, 0, 0, 0.2),
			0 0 0 0.5px rgba(0, 0, 0, 0.12);
	}
	.zoom {
		zoom: 2.6;
	}

	.menu {
		position: absolute;
		padding: 8px;
		border-radius: 14px;
		background: rgba(250, 250, 252, 0.94);
		backdrop-filter: blur(30px);
		box-shadow:
			0 18px 50px rgba(0, 0, 0, 0.25),
			0 0 0 0.5px rgba(0, 0, 0, 0.16);
		display: flex;
		flex-direction: column;
		gap: 8px;
		font-variant-numeric: tabular-nums;
	}
	.card {
		position: relative;
		padding: 12px;
		border-radius: 10px;
		background: rgba(0, 0, 0, 0.035);
		box-shadow: inset 0 0 0 0.5px rgba(0, 0, 0, 0.06);
	}
	header {
		height: 28px;
		margin-bottom: 8px;
		display: flex;
		align-items: center;
		gap: 8px;
		font-size: 15px;
	}
	.icon {
		width: 22px;
		height: 22px;
		border-radius: 6px;
		display: grid;
		place-items: center;
		color: #fff;
		font-size: 13px;
	}
	.icon.cpu {
		background: #3a8dff;
	}
	.icon.mem {
		background: #f2545b;
	}
	.icon.net {
		background: #4fb8f0;
	}
	.big {
		margin-left: auto;
		font-size: 19px;
		font-weight: 600;
	}
	.big small {
		font-size: 12px;
		font-weight: 400;
		color: #86868b;
	}
	.chart {
		display: block;
		border-radius: 6px;
		background: rgba(0, 0, 0, 0.04);
	}
	.area {
		fill: rgba(0, 113, 227, 0.22);
	}
	.line {
		fill: none;
		stroke: #0071e3;
		stroke-width: 1.5;
	}
	.rule {
		stroke: rgba(0, 0, 0, 0.35);
		stroke-width: 1;
	}
	.dot {
		fill: #fff;
		stroke: #0071e3;
		stroke-width: 2;
	}
	.tip {
		position: absolute;
		top: 46px;
		margin-left: 12px;
		padding: 3px 10px;
		border-radius: 999px;
		background: rgba(255, 255, 255, 0.95);
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
		font-size: 12px;
		white-space: nowrap;
		color: #3a3a3c;
	}
	.legend {
		margin: 8px 0 0;
		display: flex;
		gap: 12px;
		white-space: nowrap;
		font-size: 12px;
		color: #6e6e73;
	}
	.legend b {
		color: #1d1d1f;
		font-weight: 500;
	}
	.legend i {
		display: inline-block;
		width: 7px;
		height: 7px;
		margin-right: 5px;
		border-radius: 50%;
		background: #0071e3;
	}
	.legend i.s {
		background: #8fbdf5;
	}
	.legend .ok {
		color: #28a745;
	}
	.cores {
		margin-top: 10px;
		height: 20px;
		display: flex;
		gap: 3px;
	}
	.cores span {
		position: relative;
		flex: 1;
		border-radius: 3px;
		background: rgba(0, 0, 0, 0.07);
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
		background: #0071e3;
	}
	.membar {
		height: 7px;
		display: flex;
		gap: 2px;
		border-radius: 4px;
		background: rgba(0, 0, 0, 0.07);
		overflow: hidden;
	}
	.membar i {
		background: #0071e3;
	}
	.membar i.w {
		background: #5aa2ee;
	}
	.membar i.c {
		background: #a9cbf3;
	}
	.rates {
		margin-left: auto;
		display: flex;
		gap: 12px;
		font-size: 14px;
		font-weight: 600;
	}
	.tiles {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 8px;
	}
	.tile {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 6px;
		padding: 10px 6px;
		font-size: 13px;
	}
	.tile small {
		font-size: 11px;
		color: #86868b;
	}
	.track {
		fill: none;
		stroke: rgba(0, 0, 0, 0.08);
		stroke-width: 6;
	}
	.arc {
		fill: none;
		stroke: #0071e3;
		stroke-width: 6;
		stroke-linecap: round;
	}
	text {
		font-size: 14px;
		font-weight: 600;
		text-anchor: middle;
		fill: #1d1d1f;
	}

	.caption {
		position: absolute;
		left: 50%;
		bottom: 44px;
		transform: translateX(-50%);
		margin: 0;
		padding: 10px 20px;
		border-radius: 999px;
		background: rgba(29, 29, 31, 0.82);
		backdrop-filter: blur(12px);
		color: #f5f5f7;
		font-size: 20px;
		font-weight: 500;
		white-space: nowrap;
	}
</style>
