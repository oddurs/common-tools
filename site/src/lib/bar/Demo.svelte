<script lang="ts">
	import Film from '../film/Film.svelte';
	import StatusItem from '../mac/StatusItem.svelte';
	import Symbol from '../mac/Symbol.svelte';
	import Window from '../mac/Window.svelte';
	import { chosen, frameAt, metrics, stage } from './demo';

	let { time, dark = false }: { time: number; dark?: boolean } = $props();

	const frame = $derived(frameAt(time));
	const chosenName = $derived(frame.dropdown.rows[chosen].name);
</script>

<Film {frame} {dark} slug="bar" app="Notes" menus={['File', 'Edit', 'Format', 'View', 'Window', 'Help']}>
	{#snippet extras()}
		{#each frame.icons as icon, i (i)}
			<span
				class="icon"
				style:left="{icon.x}px"
				style:width="{metrics.slot}px"
				style:opacity={icon.opacity}><Symbol name={icon.symbol} /></span
			>
		{/each}
		<span class="icon" style:left="{frame.folder.x}px" style:width="{metrics.folder}px"
			><StatusItem open={frame.folder.open} width={metrics.folder}
				><Symbol name="ellipsis.circle" /><b class="name">More</b></StatusItem
			></span
		>
	{/snippet}

	{#snippet top()}
		{#if frame.dropdown.opacity > 0}
			<!-- The More folder's menu: each hidden icon by its app, in menu bar order. -->
			<div
				class="menu"
				style:left="{stage.dropdown.x}px"
				style:top="{stage.dropdown.y}px"
				style:width="{metrics.dropdownWidth}px"
				style:opacity={frame.dropdown.opacity}
			>
				{#each frame.dropdown.rows as row, i (row.symbol)}
					<div class="row" class:highlight={frame.dropdown.highlight === i}>
						<span class="app"><Symbol name={row.symbol} scale={0.8} /></span>{row.name}
					</div>
				{/each}
			</div>
		{/if}
		{#if frame.itemMenu.opacity > 0}
			<div
				class="menu"
				style:left="{frame.itemMenu.x}px"
				style:top="{stage.dropdown.y}px"
				style:width="{metrics.itemMenuWidth}px"
				style:opacity={frame.itemMenu.opacity}
			>
				<div class="row title">{chosenName}</div>
				<div class="row">Show History…</div>
				<div class="row">Clear History</div>
				<div class="separator"></div>
				<div class="row">Settings…</div>
			</div>
		{/if}
	{/snippet}

	<Window title="Notes" x={330} y={300} width={720} height={420}>
		<div class="note">
			<h2>Tidy up</h2>
			<p>Fewer icons, same apps.</p>
		</div>
	</Window>
</Film>

<style>
	.icon {
		position: absolute;
		top: 0;
		height: 100%;
		display: flex;
		align-items: center;
		justify-content: center;
	}
	/* The folder's name beside its symbol, as the menu bar sets a status item's title. */
	.name {
		margin-left: 5px;
		font-weight: 500;
	}

	/* A menu in macOS 26: Liquid Glass, larger corners. */
	.menu {
		position: absolute;
		z-index: 30;
		padding: 5px;
		border-radius: 12px;
		background: rgba(246, 246, 248, 0.82);
		backdrop-filter: blur(40px) saturate(1.8);
		box-shadow:
			inset 0 0.5px 0 rgba(255, 255, 255, 0.9),
			0 18px 50px rgba(0, 0, 0, 0.22),
			0 0 0 0.5px rgba(0, 0, 0, 0.14);
		font:
			13px/1.3 -apple-system,
			BlinkMacSystemFont,
			'SF Pro Text',
			sans-serif;
		color: #1d1d1f;
		text-shadow: none;
		--tile: rgba(0, 0, 0, 0.06);
		--secondary: #6e6e73;
		--highlight: #0a84ff;
	}
	:global(.dark) .menu {
		background: rgba(36, 36, 40, 0.78);
		box-shadow:
			inset 0 0.5px 0 rgba(255, 255, 255, 0.22),
			0 18px 50px rgba(0, 0, 0, 0.5),
			0 0 0 0.5px rgba(255, 255, 255, 0.14);
		color: #f5f5f7;
		--tile: rgba(255, 255, 255, 0.1);
		--secondary: #98989d;
	}
	.row {
		height: 24px;
		padding: 0 8px;
		display: flex;
		align-items: center;
		gap: 8px;
		border-radius: 6px;
	}
	.row.highlight {
		background: var(--highlight);
		color: white;
	}
	.row.title {
		color: var(--secondary);
		font-weight: 600;
	}
	/* Stands in for the app's icon. */
	.app {
		width: 18px;
		height: 18px;
		display: grid;
		place-items: center;
		border-radius: 5px;
		background: var(--tile);
	}
	.separator {
		height: 1px;
		margin: 4px 8px;
		background: color-mix(in srgb, currentColor 15%, transparent);
	}
	.note {
		padding: 30px 36px;
	}
	.note h2 {
		margin: 0 0 8px;
		font:
			700 28px/1.2 -apple-system,
			BlinkMacSystemFont,
			'SF Pro Display',
			sans-serif;
	}
	.note p {
		margin: 0;
		font:
			22px/1.4 -apple-system,
			BlinkMacSystemFont,
			sans-serif;
	}
</style>
