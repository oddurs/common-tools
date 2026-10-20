<script lang="ts">
	// The overlay's loupe (Overlay.swift, Loupe): 21 device pixels of the frozen screen across, six
	// points each, on a faint grid, the one under the pointer ringed in black and white, inside a dark
	// line and a light one. The pixels are drawn as a 2× screen would hold them: the flat colours
	// from scene.ts, then the text, set in its own fonts on a canvas, so a glyph breaks into the
	// pixels it really has.
	import type { Point } from '../film/motion';
	import { backdrop, textRuns, type TextRun } from './scene';
	import type { Rect } from './size';

	let { at, pointer, dark }: { at: Rect; pointer: Point; dark: boolean } = $props();

	const count = 21;
	const cell = 6;
	const side = count * cell;
	const half = (count - 1) / 2;
	const hair = 0.5;

	let canvas: HTMLCanvasElement | undefined;
	const runs: Record<'light' | 'dark', TextRun[]> = { light: textRuns(false), dark: textRuns(true) };

	/** The 21 × 21 device pixels centred on (cx, cy), as rgb() strings, row by row. */
	function sample(cx: number, cy: number): string[] {
		const x0 = cx - half;
		const y0 = cy - half;
		const flat = () =>
			Array.from({ length: count * count }, (_, i) => {
				const [r, g, b] = backdrop(x0 + (i % count), y0 + Math.floor(i / count), dark);
				return [r, g, b];
			});
		if (typeof document === 'undefined') return flat().map(([r, g, b]) => `rgb(${r},${g},${b})`);
		canvas ??= document.createElement('canvas');
		canvas.width = count;
		canvas.height = count;
		const ctx = canvas.getContext('2d', { willReadFrequently: true })!;
		const image = ctx.createImageData(count, count);
		flat().forEach(([r, g, b], i) => image.data.set([r, g, b, 255], i * 4));
		ctx.putImageData(image, 0, 0);
		ctx.setTransform(2, 0, 0, 2, -x0, -y0);
		const top = y0 / 2 - 4;
		const bottom = (y0 + count) / 2 + 16;
		for (const run of runs[dark ? 'dark' : 'light']) {
			if (run.baseline < top || run.baseline > bottom) continue;
			let x = run.x;
			for (const piece of run.pieces) {
				ctx.font = piece.font;
				ctx.fillStyle = piece.colour;
				ctx.textAlign = run.right ? 'right' : 'left';
				x += piece.gap ?? 0;
				ctx.fillText(piece.text, x, run.baseline);
				x += ctx.measureText(piece.text).width;
			}
		}
		ctx.setTransform(1, 0, 0, 1, 0, 0);
		const data = ctx.getImageData(0, 0, count, count).data;
		return Array.from(
			{ length: count * count },
			(_, i) => `rgb(${data[i * 4]},${data[i * 4 + 1]},${data[i * 4 + 2]})`
		);
	}

	const cells = $derived.by(() =>
		sample(Math.floor(pointer.x * 2), Math.floor(pointer.y * 2)).map((fill, i) => ({
			x: (i % count) * cell,
			y: Math.floor(i / count) * cell,
			fill
		}))
	);
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
