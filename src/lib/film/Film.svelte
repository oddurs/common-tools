<script lang="ts">
	// Draws a film's frame: the Mac screen through the camera, the pointer, and the overlay (caption,
	// keys held, closing card). A scene supplies only what is its own: the app's menu bar item, its
	// windows, its menus.
	import type { Snippet } from 'svelte';
	import Cursor from './Cursor.svelte';
	import Overlay from '../mac/Overlay.svelte';
	import Screen from '../mac/Screen.svelte';
	import Stage from '../mac/Stage.svelte';
	import { tool, type Tool } from '../tools';
	import type { BaseFrame } from './director';

	let {
		frame,
		dark,
		slug,
		app,
		menus,
		extras,
		children,
		top: topContent
	}: {
		frame: BaseFrame;
		dark: boolean;
		slug: Tool['slug'];
		/** The frontmost app, whose name and menus fill the left of the menu bar. */
		app: string;
		menus: string[];
		/** The scene's menu bar extras, laid out from the right as in `Screen`. */
		extras?: Snippet;
		/** Windows and anything else on the desktop. */
		children?: Snippet;
		/** Menus that drop from the menu bar, drawn over it and under the pointer. */
		top?: Snippet;
	} = $props();
</script>

<Stage {dark} opacity={frame.opacity}>
	<Screen {dark} camera={frame.camera} {app} {menus} {extras} {children}>
		{#snippet top()}
			{@render topContent?.()}
			{#if frame.cursor}
				<Cursor x={frame.cursor.x} y={frame.cursor.y} pulse={frame.pulse} />
			{/if}
		{/snippet}
	</Screen>
	<Overlay caption={frame.caption} keys={frame.keys} end={frame.end} tool={tool(slug)} />
</Stage>
