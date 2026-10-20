<script lang="ts" module>
	export type Series = {
		name: string;
		/** Oldest first; the last is now. */
		values: number[];
		/** Which step of the palette colour it takes. */
		ink: 'strong' | 'medium' | 'soft';
		/** A line over a gradient. Otherwise a solid band beneath the others. */
		emphasis: boolean;
	};
</script>

<script lang="ts">
	// The menu's HistoryChart: a fixed time axis with the newest sample on the right, monotone
	// curves, faint quarter lines (or a midline when mirrored), a scale label on rate graphs, and the
	// hover read-back: a rule, a dot on each line, and what each read at that moment. Styled in
	// Demo.svelte.
	import { series as path, yOf, type Rect } from './chart';
	import { ago } from './format';

	let {
		id,
		width,
		height = 48,
		up,
		down = [],
		peak,
		format,
		hover = null,
		interval = 1
	}: {
		id: string;
		width: number;
		height?: number;
		up: Series[];
		down?: Series[];
		/** What full height means: 1 for fractions, the visible peak for rates. */
		peak: number;
		format: (value: number) => string;
		/** The hovered sample, counted back from now. */
		hover?: number | null;
		/** Seconds between samples. */
		interval?: number;
	} = $props();

	const mirrored = $derived(down.length > 0);
	const capacity = 180;
	const step = $derived(width / (capacity - 1));
	const plot: Rect = $derived({ x: 0, y: 2, width, height: height - 4 });
	const upper: Rect = $derived(mirrored ? { ...plot, height: plot.height / 2 } : plot);
	const lower: Rect = $derived({ ...plot, y: plot.y + plot.height / 2, height: plot.height / 2 });
	const scaled = (s: Series) => s.values.map((v) => v / peak);

	const hx = $derived(hover === null ? 0 : width - hover * step);
	const at = (s: Series) => s.values[s.values.length - 1 - (hover ?? 0)];
	const readout = $derived(
		[...down, ...up]
			.filter((s) => s.emphasis)
			.map((s) => `${s.name} ${format(at(s))}`)
			.join('  ')
	);
	/** About how wide the label's capsule is, to flip it left of the rule near the right edge. */
	const labelWidth = $derived(12 + 6 + 5.6 * (ago((hover ?? 0) * interval).length + readout.length));
	const flip = $derived(hx > width - labelWidth - 12);
</script>

<div class="chart" style:width="{width}px" style:height="{height}px">
	<svg {width} {height} viewBox="0 0 {width} {height}">
		<defs>
			{#each [...up.map((s) => [s, upper, false] as const), ...down.map((s) => [s, lower, true] as const)] as [s, rect, isDown] (s.name)}
				<linearGradient
					id="{id}-{s.name}"
					gradientUnits="userSpaceOnUse"
					x1="0"
					x2="0"
					y1={isDown ? rect.y + rect.height : rect.y}
					y2={isDown ? rect.y : rect.y + rect.height}
				>
					<stop offset="0" class={s.ink} stop-opacity="0.42" />
					<stop offset="1" class={s.ink} stop-opacity="0.04" />
				</linearGradient>
			{/each}
		</defs>
		{#if mirrored}
			<rect y={height / 2 - 0.25} {width} height="0.5" class="grid" />
		{:else}
			{#each [0.25, 0.5, 0.75] as f (f)}
				<line x1="0" x2={width} y1={height * (1 - f)} y2={height * (1 - f)} class="grid dashed" />
			{/each}
		{/if}
		{#each up.filter((s) => !s.emphasis) as s (s.name)}
			<path d={path(scaled(s), upper, step).area} class="band {s.ink}" />
		{/each}
		{#each [...up
				.filter((s) => s.emphasis)
				.map((s) => [s, upper, false] as const), ...down.map((s) => [s, lower, true] as const)] as [s, rect, isDown] (s.name)}
			{@const p = path(scaled(s), rect, step, isDown)}
			<path d={p.area} fill="url(#{id}-{s.name})" />
			<path d={p.line} class="line {s.ink}" />
		{/each}
		{#if hover !== null}
			<rect x={hx - 0.5} y="0" width="1" {height} class="rule" />
			{#each [...up
					.filter((s) => s.emphasis)
					.map((s) => [s, upper, false] as const), ...down.map((s) => [s, lower, true] as const)] as [s, rect, isDown] (s.name)}
				{@const y = yOf(Math.min(Math.max(at(s) / peak, 0), 1), rect, isDown)}
				<circle cx={hx} cy={y} r="3.5" class="halo" />
				<circle cx={hx} cy={y} r="2" class="dot {s.ink}" />
			{/each}
		{/if}
	</svg>
	{#if hover !== null}
		<span
			class="readback"
			style:left={flip ? undefined : `${hx + 6}px`}
			style:right={flip ? `${width - hx + 6}px` : undefined}
			><span class="ago">{ago(hover * interval)}</span>{readout}</span
		>
	{:else if mirrored}
		<!-- Auto-scaling hides magnitude; say what full height means. -->
		<span class="scale">{format(peak)}</span>
	{/if}
</div>
