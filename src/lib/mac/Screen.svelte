<script lang="ts">
	// A Mac screen as macOS 26 draws it: wallpaper, the transparent menu bar with the app's menus on
	// the left and the system's extras on the right.
	import type { Snippet } from 'svelte';
	import Symbol from './Symbol.svelte';
	import { clock, extrasRight, menuBarHeight, screen, systemItems, viewport } from './geometry';
	import type { Camera } from '../film/motion';

	let {
		dark,
		camera,
		app,
		menus,
		extras,
		children,
		top
	}: {
		dark: boolean;
		camera: Camera;
		app: string;
		menus: string[];
		/** Third-party menu bar extras, laid out right to left from `extrasRight`. */
		extras?: Snippet;
		/** Windows and anything else on the desktop. */
		children?: Snippet;
		/** Drawn over the menu bar: menus that drop from it, and the pointer. */
		top?: Snippet;
	} = $props();

	const tx = $derived(viewport.width / 2 - camera.x * camera.zoom);
	const ty = $derived(viewport.height / 2 - camera.y * camera.zoom);
</script>

<div
	class="screen"
	class:dark
	style:width="{screen.width}px"
	style:height="{screen.height}px"
	style:transform="translate({tx}px, {ty}px) scale({camera.zoom})"
>
	<div class="wallpaper"></div>

	<div class="desktop">{@render children?.()}</div>

	<div class="menubar" style:height="{menuBarHeight}px">
		<div class="menus">
			<span class="item apple"><Symbol name="apple.logo" /></span>
			<span class="item app">{app}</span>
			{#each menus as menu (menu)}<span class="item">{menu}</span>{/each}
		</div>

		<div class="extras" style:width="{extrasRight}px">{@render extras?.()}</div>

		<div class="system" style:left="{extrasRight}px">
			{#each [...systemItems].reverse() as item (item.symbol)}
				<span class="slot" style:width="{item.width}px"><Symbol name={item.symbol} /></span>
			{/each}
			<span class="clock" style:width="{clock.width}px">{clock.text}</span>
		</div>
	</div>

	{@render top?.()}
</div>

<style>
	.screen {
		position: absolute;
		left: 0;
		top: 0;
		overflow: hidden;
		transform-origin: 0 0;
		font:
			13px/1 -apple-system,
			BlinkMacSystemFont,
			'SF Pro Text',
			sans-serif;
		letter-spacing: -0.003em;
		color: #000;
		-webkit-font-smoothing: antialiased;
		--menu-text: rgba(0, 0, 0, 0.88);
	}
	.screen.dark {
		color: #fff;
		--menu-text: rgba(255, 255, 255, 0.95);
	}

	/* An abstract wallpaper in each appearance: soft light washes, or a deep night glow. */
	.wallpaper {
		position: absolute;
		inset: 0;
		background:
			radial-gradient(70% 60% at 18% 22%, rgba(140, 190, 255, 0.85), transparent 70%),
			radial-gradient(60% 55% at 82% 30%, rgba(196, 170, 255, 0.7), transparent 70%),
			radial-gradient(70% 60% at 70% 95%, rgba(255, 196, 160, 0.85), transparent 70%),
			linear-gradient(170deg, #dfe9ff, #f3eaf5 55%, #fde3d2);
	}
	.dark .wallpaper {
		background:
			radial-gradient(60% 55% at 20% 18%, rgba(46, 92, 220, 0.75), transparent 70%),
			radial-gradient(55% 50% at 85% 30%, rgba(112, 60, 200, 0.55), transparent 70%),
			radial-gradient(70% 60% at 65% 100%, rgba(0, 150, 170, 0.45), transparent 70%),
			linear-gradient(170deg, #0b1230, #0d0d1c 55%, #0a1a24);
	}

	.desktop {
		position: absolute;
		inset: 0;
	}

	/* Transparent, as macOS 26 draws it; the wallpaper shows through. */
	.menubar {
		position: absolute;
		left: 0;
		top: 0;
		width: 100%;
		color: var(--menu-text);
	}
	.dark .menubar {
		text-shadow: 0 0 6px rgba(0, 0, 0, 0.25);
	}
	.menus {
		position: absolute;
		left: 10px;
		top: 0;
		height: 100%;
		display: flex;
		align-items: center;
	}
	.item {
		padding: 0 10px;
		font-size: 13px;
	}
	.apple {
		padding: 0 12px 0 10px;
	}
	.app {
		font-weight: 700;
	}
	.extras {
		position: absolute;
		left: 0;
		top: 0;
		height: 100%;
		overflow: hidden;
	}
	.system {
		position: absolute;
		top: 0;
		height: 100%;
		display: flex;
		align-items: center;
	}
	.slot {
		display: flex;
		justify-content: center;
	}
	.clock {
		text-align: right;
		font-variant-numeric: tabular-nums;
		white-space: pre;
	}
</style>
