<script lang="ts">
	// The menu bar item as BarRenderer draws it, in the menu bar's own ink like the template image it
	// is: the time and percentage in 12-point monospaced digits, and the icon, whose outline and nub
	// sit back at 45% behind a full-strength fill. While charging, a bolt sits over the middle with a
	// clear halo and spills past the body.
	import { baseline, bolt, boltAspect, font, height, icon, layout, width, type Reading } from './item';

	let { reading }: { reading: Reading } = $props();

	const id = $props.id();
	const pieces = $derived(layout(reading));

	const b = icon.body;
	/** The body sits on a whole point, so its outline stays sharp. */
	const top = Math.round((height - b.height) / 2);
	const midY = top + b.height / 2;
	const inner = { x: 2, y: top + 2, width: b.width - 4, height: b.height - 4 };
	const fill = $derived(reading.level > 0 ? Math.max(inner.width * reading.level, 1.5) : 0);

	const boltHeight = b.height + 2;
	const boltWidth = boltHeight * boltAspect;
	const boltPoints = bolt
		.map(
			([x, y]) =>
				`${(b.width / 2 - boltWidth / 2 + x * boltWidth).toFixed(3)},${(midY - boltHeight / 2 + y * boltHeight).toFixed(3)}`
		)
		.join(' ');
	const charging = $derived(reading.state === 'charging');
</script>

<span class="item" style:width="{width}px" style:height="{height}px">
	{#each pieces as piece (piece.part)}
		{#if piece.text !== undefined}
			<span class="text" style:left="{piece.x}px" style:top="{baseline - font.capHeight}px"
				>{piece.text}</span
			>
		{:else}
			<svg
				class="icon"
				style:left="{piece.x}px"
				width={b.width + icon.nubGap + icon.nub.width}
				{height}
				viewBox="0 0 {b.width + icon.nubGap + icon.nub.width} {height}"
			>
				{#if charging}
					<mask id="halo-{id}" maskUnits="userSpaceOnUse">
						<rect width="100%" height="100%" fill="white" />
						<polygon points={boltPoints} fill="black" stroke="black" stroke-width="2.5" />
					</mask>
				{/if}
				<g mask={charging ? `url(#halo-${id})` : undefined}>
					<rect
						x="0.5"
						y={top + 0.5}
						width={b.width - 1}
						height={b.height - 1}
						rx="3.5"
						fill="none"
						stroke="currentColor"
						stroke-opacity={icon.outline}
					/>
					<rect
						x={b.width + icon.nubGap}
						y={midY - icon.nub.height / 2}
						width={icon.nub.width}
						height={icon.nub.height}
						rx="0.75"
						fill="currentColor"
						fill-opacity={icon.outline}
					/>
					<rect
						x={inner.x}
						y={inner.y}
						width={fill}
						height={inner.height}
						rx="1.5"
						fill="currentColor"
					/>
				</g>
				{#if charging}
					<polygon points={boltPoints} fill="currentColor" />
				{/if}
			</svg>
		{/if}
	{/each}
</span>

<style>
	.item {
		position: relative;
		display: block;
		flex: none;
		text-shadow: none;
	}
	.text {
		position: absolute;
		font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
		font-size: 12px;
		font-weight: 400;
		font-variant-numeric: tabular-nums;
		letter-spacing: 0;
		line-height: 1;
		white-space: pre;
		text-box: trim-both cap alphabetic;
	}
	.icon {
		position: absolute;
		top: 0;
		overflow: visible;
	}
</style>
