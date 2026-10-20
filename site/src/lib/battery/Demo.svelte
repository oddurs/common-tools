<script lang="ts">
	import { asset } from '$app/paths';
	import Film from '../film/Film.svelte';
	import StatusItem from '../mac/StatusItem.svelte';
	import Symbol from '../mac/Symbol.svelte';
	import { statusSlot } from '../mac/geometry';
	import type { SymbolName } from '../mac/symbols';
	import Item from './Item.svelte';
	import {
		chargedAlert,
		frameAt,
		hiddenSystem,
		history,
		notification,
		span,
		stage,
		type Sample
	} from './demo';
	import { duration, percent } from './item';

	let { time, dark = false }: { time: number; dark?: boolean } = $props();

	const frame = $derived(frameAt(time));
	const r = $derived(frame.reading);
	const d = $derived(frame.details);
	const note = notification(chargedAlert / 100);

	/** Other apps' menu bar extras, left of Common Battery. */
	const others: SymbolName[] = ['headphones', 'icloud.fill'];

	/** Format.status: what the battery is doing, in one line. */
	const status = $derived(
		r.state === 'charging'
			? `${duration(r.minutes)} until full`
			: r.minutes === null
				? 'Calculating…'
				: `${duration(r.minutes)} remaining`
	);
	const facts = $derived<[string, string][]>([
		['Power Source', d.adapter ? `${d.adapter} W Adapter` : 'Battery'],
		[d.watts > 0 ? 'Charging At' : 'Using', `${Math.abs(d.watts).toFixed(1)} W`],
		['Cycles', '156 of 1,000'],
		['Full Charge', '7,872 of 8,579 mAh'],
		['Temperature', '88°F']
	]);

	// ChargeChart: 44 points tall across the card's 296. Runs break at gaps over five minutes; each
	// run splits where charging starts or stops, the boundary sample shared so the line stays whole,
	// and a stretch takes its second sample's colour.
	const chart = { width: 296, height: 44 };
	type Stretch = { charging: boolean; line: string; area: string };
	const stretches: Stretch[] = (() => {
		const runs: Sample[][] = [];
		for (const s of history) {
			const run = runs[runs.length - 1];
			if (run && s.minute - run[run.length - 1].minute <= 5) run.push(s);
			else runs.push([s]);
		}
		const out: Stretch[] = [];
		for (const run of runs) {
			const parts: Sample[][] = [[run[0]]];
			for (const s of run.slice(1)) {
				const part = parts[parts.length - 1];
				part.push(s);
				if (s.charging !== part[part.length - 2].charging) parts.push([s]);
			}
			for (const part of parts.filter((p) => p.length > 1)) {
				const xy = part.map((s) => [
					((s.minute / span) * chart.width).toFixed(2),
					(chart.height * (1 - s.level)).toFixed(2)
				]);
				const line = `M${xy.map((p) => p.join(',')).join('L')}`;
				const [first, last] = [xy[0], xy[xy.length - 1]];
				out.push({
					charging: (part[1] ?? part[0]).charging,
					line,
					area: `${line}L${last[0]},${chart.height}L${first[0]},${chart.height}Z`
				});
			}
		}
		return out;
	})();
</script>

<Film
	{frame}
	{dark}
	slug="battery"
	app="Notes"
	menus={['File', 'Edit', 'Format', 'View', 'Window', 'Help']}
	hideSystem={hiddenSystem}
>
	{#snippet extras()}
		<div class="tray">
			{#each others as symbol (symbol)}
				<StatusItem width={statusSlot}><Symbol name={symbol} /></StatusItem>
			{/each}
			<StatusItem open={frame.menu > 0.5} label="Common Battery">
				<Item reading={r} />
			</StatusItem>
		</div>
	{/snippet}

	{#snippet top()}
		{#if frame.banner > 0}
			<aside
				class="banner"
				style:left="{stage.banner.x}px"
				style:top="{stage.banner.y}px"
				style:width="{stage.banner.width}px"
				style:opacity={Math.min(1, frame.banner * 1.6)}
				style:transform="translateX({(1 - frame.banner) * (stage.banner.width + 24)}px)"
			>
				<img src={asset('battery/icon.png')} alt="" width="36" height="36" />
				<div class="note">
					<p class="title"><b>{note.title}</b><time>now</time></p>
					<p>{note.body}</p>
				</div>
			</aside>
		{/if}

		{#if frame.menu > 0}
			<div
				class="menu"
				style:left="{stage.menu.x}px"
				style:top="{stage.menu.y}px"
				style:width="{stage.menu.width}px"
				style:opacity={frame.menu}
				style:transform="translateY({(1 - frame.menu) * -4}px)"
			>
				<div class="panel">
					<section class="group">
						<header>
							<span class="heading"><b>Battery</b><small>{status}</small></span>
							<span class="level">{percent(r.level)}</span>
						</header>
						<svg
							class="chart"
							width={chart.width}
							height={chart.height}
							viewBox="0 0 {chart.width} {chart.height}"
						>
							<rect
								class="half"
								x="0"
								y={chart.height / 2 - 0.25}
								width={chart.width}
								height="0.5"
							/>
							{#each stretches as s, i (i)}
								<path d={s.area} class="area" class:charging={s.charging} />
								<path d={s.line} class="line" class:charging={s.charging} />
							{/each}
						</svg>
						<p class="axis"><span>12 hours ago</span><span>Now</span></p>
						<dl>
							{#each facts as [label, value] (label)}
								<dt>{label}</dt>
								<dd>{value}</dd>
							{/each}
						</dl>
					</section>
				</div>
				<hr />
				<p class="row">
					<span class="glyph"><Symbol name="battery.100percent" scale={0.86} /></span>Battery
					Settings…
				</p>
				<p class="row"><span class="glyph"></span>Settings…<kbd>⌘,</kbd></p>
				<p class="row"><span class="glyph"></span>Quit Common Battery<kbd>⌘Q</kbd></p>
			</div>
		{/if}
	{/snippet}
</Film>

<style>
	.tray {
		position: absolute;
		top: 0;
		right: 0;
		height: 100%;
		display: flex;
		align-items: center;
	}

	/* An NSMenu in macOS 26: Liquid Glass, larger corners. */
	.menu {
		position: absolute;
		z-index: 30;
		padding: 5px 0;
		border-radius: 14px;
		background: rgba(246, 246, 248, 0.84);
		backdrop-filter: blur(40px) saturate(1.8);
		box-shadow:
			inset 0 0.5px 0 rgba(255, 255, 255, 0.9),
			0 18px 50px rgba(0, 0, 0, 0.22),
			0 0 0 0.5px rgba(0, 0, 0, 0.14);
		font:
			13px/1.25 -apple-system,
			BlinkMacSystemFont,
			'SF Pro Text',
			sans-serif;
		letter-spacing: 0;
		color: rgba(0, 0, 0, 0.85);
		text-shadow: none;
		--primary: rgba(0, 0, 0, 0.85);
		--secondary: rgba(0, 0, 0, 0.5);
		--tertiary: rgba(0, 0, 0, 0.26);
		--card: rgba(0, 0, 0, 0.047);
		--card-border: rgba(0, 0, 0, 0.06);
		--separator: rgba(0, 0, 0, 0.1);
		--accent: #007aff;
		--success: #34c759;
	}
	:global(.dark) .menu {
		background: rgba(36, 36, 40, 0.8);
		box-shadow:
			inset 0 0.5px 0 rgba(255, 255, 255, 0.22),
			0 18px 50px rgba(0, 0, 0, 0.5),
			0 0 0 0.5px rgba(255, 255, 255, 0.14);
		color: rgba(255, 255, 255, 0.88);
		--primary: rgba(255, 255, 255, 0.88);
		--secondary: rgba(255, 255, 255, 0.55);
		--tertiary: rgba(255, 255, 255, 0.28);
		--card: rgba(255, 255, 255, 0.047);
		--card-border: rgba(255, 255, 255, 0.06);
		--separator: rgba(255, 255, 255, 0.12);
		--accent: #0a84ff;
		--success: #30d158;
	}

	/* PanelView: a Card 320 wide, 8 either side and 4 above and below. */
	.panel {
		padding: 4px 8px;
	}
	.group {
		padding: 12px;
		border-radius: 12px;
		background: var(--card);
		box-shadow: inset 0 0 0 0.5px var(--card-border);
		display: flex;
		flex-direction: column;
		gap: 8px;
	}
	header {
		display: flex;
		align-items: baseline;
		justify-content: space-between;
	}
	.heading {
		display: flex;
		flex-direction: column;
		gap: 4px;
	}
	.heading b {
		font-size: 13px;
		font-weight: 700;
		color: var(--primary);
	}
	.heading small {
		font-size: 11px;
		color: var(--secondary);
		font-variant-numeric: tabular-nums;
	}
	.level {
		font-size: 22px;
		font-weight: 600;
		font-variant-numeric: tabular-nums;
		color: var(--primary);
	}
	.chart {
		display: block;
		border-radius: 8px;
		background: var(--card);
	}
	.half {
		fill: var(--separator);
	}
	.area {
		fill: color-mix(in srgb, var(--accent) 25%, transparent);
	}
	.area.charging {
		fill: color-mix(in srgb, var(--success) 25%, transparent);
	}
	.line {
		fill: none;
		stroke: var(--accent);
		stroke-width: 1.5;
		stroke-linecap: round;
		stroke-linejoin: round;
	}
	.line.charging {
		stroke: var(--success);
	}
	.axis {
		margin: -4px 0 0;
		display: flex;
		justify-content: space-between;
		font-size: 10px;
		color: var(--tertiary);
	}
	dl {
		margin: 0;
		display: grid;
		grid-template-columns: max-content 1fr;
		column-gap: 12px;
		row-gap: 4px;
		font-size: 11px;
		font-variant-numeric: tabular-nums;
		white-space: nowrap;
	}
	dt {
		color: var(--secondary);
	}
	dd {
		margin: 0;
		color: var(--primary);
	}

	hr {
		margin: 5px 10px;
		border: 0;
		border-top: 1px solid var(--separator);
	}
	.row {
		margin: 0 5px;
		height: 24px;
		padding: 0 10px 0 6px;
		display: flex;
		align-items: center;
		font-size: 13px;
	}
	.glyph {
		width: 22px;
		display: flex;
		justify-content: center;
		margin-right: 4px;
	}
	kbd {
		margin-left: auto;
		font: inherit;
		color: var(--secondary);
	}

	/* A notification banner in macOS 26: Liquid Glass, the app's icon, the title over the body. */
	.banner {
		position: absolute;
		z-index: 30;
		box-sizing: border-box;
		padding: 12px 14px 12px 12px;
		display: flex;
		align-items: center;
		gap: 10px;
		border-radius: 20px;
		background: rgba(246, 246, 248, 0.8);
		backdrop-filter: blur(40px) saturate(1.8);
		box-shadow:
			inset 0 0.5px 0 rgba(255, 255, 255, 0.9),
			0 12px 36px rgba(0, 0, 0, 0.2),
			0 0 0 0.5px rgba(0, 0, 0, 0.12);
		font:
			13px/1.3 -apple-system,
			BlinkMacSystemFont,
			'SF Pro Text',
			sans-serif;
		letter-spacing: 0;
		color: rgba(0, 0, 0, 0.85);
		text-shadow: none;
	}
	:global(.dark) .banner {
		background: rgba(40, 40, 44, 0.78);
		box-shadow:
			inset 0 0.5px 0 rgba(255, 255, 255, 0.2),
			0 12px 36px rgba(0, 0, 0, 0.5),
			0 0 0 0.5px rgba(255, 255, 255, 0.14);
		color: rgba(255, 255, 255, 0.9);
	}
	.banner img {
		flex: none;
		display: block;
	}
	.note {
		flex: 1;
		min-width: 0;
	}
	.note p {
		margin: 0;
	}
	.title {
		display: flex;
		justify-content: space-between;
		align-items: baseline;
	}
	.title b {
		font-weight: 600;
	}
	time {
		font-size: 12px;
		opacity: 0.5;
	}
</style>
