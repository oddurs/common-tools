<script lang="ts">
	// The overlay's loupe (Overlay.swift, Loupe): 21 device pixels of the frozen screen across, six
	// points each, on a faint grid, the one under the pointer ringed in black and white, inside a dark
	// line and a light one.
	import type { Point } from '../film/motion';
	import { pixel } from './scene';
	import type { Rect } from './size';

	let { at, pointer, dark }: { at: Rect; pointer: Point; dark: boolean } = $props();

	const count = 21;
	const cell = 6;
	const side = count * cell;
	const half = (count - 1) / 2;
	const hair = 0.5;

	const cells = $derived.by(() => {
		const cx = Math.floor(pointer.x * 2);
		const cy = Math.floor(pointer.y * 2);
		const out: { x: number; y: number; fill: string }[] = [];
		for (let j = 0; j < count; j++)
			for (let i = 0; i < count; i++) {
				const [r, g, b] = pixel(cx + i - half, cy + j - half, dark);
				out.push({ x: i * cell, y: j * cell, fill: `rgb(${r | 0},${g | 0},${b | 0})` });
			}
		return out;
	});
	const grid = Array.from({ length: count - 1 }, (_, i) => (i + 1) * cell)
		.map((o) => `M${o} 0V${side}M0 ${o}H${side}`)
		.join('');
	const c = half * cell;
</script>

<svg
	class="loupe"
	style:left="{at.x}px"
	style:top="{at.y}px"
	width={side}
	height={side}
	viewBox="0 0 {side} {side}"
>
	<defs>
		<clipPath id="loupe-shape"><rect width={side} height={side} rx="10" /></clipPath>
	</defs>
	<g clip-path="url(#loupe-shape)">
		{#each cells as p, i (i)}<rect x={p.x} y={p.y} width={cell} height={cell} fill={p.fill} />{/each}
		<path d={grid} stroke="rgba(128,128,128,0.25)" stroke-width={hair} fill="none" />
		<rect
			x={c - hair * 1.5}
			y={c - hair * 1.5}
			width={cell + hair * 3}
			height={cell + hair * 3}
			fill="none"
			stroke="#000"
			stroke-width={hair}
		/>
		<rect
			x={c - hair / 2}
			y={c - hair / 2}
			width={cell + hair}
			height={cell + hair}
			fill="none"
			stroke="#fff"
			stroke-width={hair}
		/>
		<rect
			x={hair / 2}
			y={hair / 2}
			width={side - hair}
			height={side - hair}
			rx="9.75"
			fill="none"
			stroke="rgba(0,0,0,0.45)"
			stroke-width={hair}
		/>
		<rect
			x={hair * 1.5}
			y={hair * 1.5}
			width={side - hair * 3}
			height={side - hair * 3}
			rx="9.25"
			fill="none"
			stroke="rgba(255,255,255,0.7)"
			stroke-width={hair}
		/>
	</g>
</svg>

<style>
	.loupe {
		position: absolute;
		display: block;
	}
</style>
