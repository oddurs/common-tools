<script lang="ts">
	import { asset } from '$app/paths';
	import Film from '../film/Film.svelte';
	import { extrasRight } from '../mac/geometry';
	import StatusItem from '../mac/StatusItem.svelte';
	import Symbol from '../mac/Symbol.svelte';
	import Window from '../mac/Window.svelte';
	import { frameAt, iconMenu, menuLayout, metrics, stage, type Hidden } from './demo';

	let { time, dark = false }: { time: number; dark?: boolean } = $props();

	const frame = $derived(frameAt(time));
	const panel = $derived(frame.panel);
	/** ProgressView's mini spinner: eight spokes, turning a spoke at a time. */
	const spoke = $derived(Math.floor(frame.spin / 90) % 8);
</script>

{#snippet icon(row: Hidden)}
	{#if row.slug}
		<img
			class="app-icon"
			src={asset(`${row.slug}/icon.png` as Parameters<typeof asset>[0])}
			alt=""
			width="16"
			height="16"
		/>
	{:else if row.tile}
		<!-- Another app's icon: a tile in its colours with its symbol, at the 16 pt a menu draws it. -->
		<span class="tile" style:background="linear-gradient(180deg, {row.tile[0]}, {row.tile[1]})"
			><Symbol name={row.symbol} scale={0.5} /></span
		>
	{:else}
		<span class="glyph"><Symbol name={row.symbol} scale={0.9} /></span>
	{/if}
{/snippet}

<Film {frame} {dark} slug="bar" app="Notes" menus={['File', 'Edit', 'Format', 'View', 'Window', 'Help']}>
	{#snippet extras()}
		<div class="bar" style:width="{extrasRight}px">
			{#each frame.icons as item, i (i)}
				{#if item.opacity > 0}
					<span
						class="slot"
						style:left="{item.x}px"
						style:width="{metrics.slot}px"
						style:opacity={item.opacity}
						><StatusItem width={metrics.slot} open={item.open}
							><Symbol name={item.symbol} /></StatusItem
						></span
					>
				{/if}
			{/each}
			{#if frame.folder.opacity > 0}
				<span
					class="slot"
					style:left="{frame.folder.x}px"
					style:width="{metrics.folder}px"
					style:opacity={frame.folder.opacity}
					><StatusItem open={frame.folder.open} width={metrics.folder} label="More"
						><Symbol name="ellipsis.circle" /><b class="name">More</b></StatusItem
					></span
				>
			{/if}
		</div>
	{/snippet}

	{#snippet top()}
		{#if panel.opacity > 0}
			<!-- FolderPanel on MenuPanelSurface: the filter, the rows in their groups, the footer. -->
			<div
				class="surface panel"
				style:left="{stage.panel.x}px"
				style:top="{stage.panel.y}px"
				style:width="{metrics.panelWidth}px"
				style:height="{panel.height}px"
				style:opacity={panel.opacity}
			>
				{#each panel.items as item, i (i)}
					<div class="item {item.kind}" style:top="{metrics.panelPadding + item.y}px">
						{#if item.kind === 'filter'}
							<span class="glyph secondary"><Symbol name="magnifyingglass" scale={0.9} /></span>
							<span class="text">{item.query}</span>
							<span class="count">{item.count}</span>
						{:else if item.kind === 'header'}
							{item.title}
						{:else if item.kind === 'divider'}
							<hr />
						{:else if item.kind === 'row'}
							<div class="lit" class:on={panel.selected === item.target}>
								{@render icon(item.row)}
								<span class="text">{item.row.name}</span>
								{#if panel.busy === item.target}
									<span class="spinner" aria-label="Opening">
										{#each Array(8) as _, s (s)}
											<i
												style:transform="rotate({s * 45}deg)"
												style:opacity={1 - ((spoke - s + 8) % 8) * 0.1}
											></i>
										{/each}
									</span>
								{/if}
							</div>
						{:else}
							<div class="lit" class:on={panel.selected === item.target}>
								<span class="text">{item.title}</span>
								{#if item.shortcut}<span class="shortcut">{item.shortcut}</span>{/if}
							</div>
						{/if}
					</div>
				{/each}
			</div>
		{/if}
		{#if frame.menu.opacity > 0}
			<!-- The chosen icon's own menu: a stock macOS menu, opened under the icon beside the folder. -->
			<div
				class="surface menu"
				style:left="{frame.menu.x}px"
				style:top="{stage.panel.y}px"
				style:width="{metrics.menuWidth}px"
				style:height="{menuLayout.height}px"
				style:opacity={frame.menu.opacity}
			>
				{#each iconMenu as entry, i (i)}
					<div class="menu-item" style:top="{menuLayout.tops[i]}px" class:separator={!entry}>
						{#if entry}
							<div
								class="lit"
								class:on={frame.menu.highlight === i}
								class:heading={entry.heading}
							>
								<span class="text">{entry.title}</span>
								{#if entry.shortcut}<span class="shortcut">{entry.shortcut}</span>{/if}
							</div>
						{:else}
							<hr />
						{/if}
					</div>
				{/each}
			</div>
		{/if}
	{/snippet}

	<Window title="Notes" x={150} y={260} width={600} height={400}>
		<div class="note">
			<h2>Tidy up</h2>
			<p>Fewer icons, same apps.</p>
		</div>
	</Window>
</Film>

<style>
	.bar {
		position: absolute;
		top: 0;
		right: 0;
		height: 100%;
	}
	.slot {
		position: absolute;
		top: 0;
		height: 100%;
		display: flex;
	}
	/* The folder's name beside its symbol, as the menu bar sets a status item's title. */
	.name {
		margin-left: 5px;
		font-weight: 500;
	}

	/* The menu material, the system menu's corner and a hairline, as macOS 26 draws a menu. */
	.surface {
		position: absolute;
		z-index: 30;
		box-sizing: border-box;
		border-radius: 12px;
		background: rgba(246, 246, 248, 0.84);
		backdrop-filter: blur(40px) saturate(1.8);
		box-shadow:
			inset 0 0.5px 0 rgba(255, 255, 255, 0.9),
			0 18px 50px rgba(0, 0, 0, 0.2),
			0 0 0 0.5px rgba(0, 0, 0, 0.14);
		font:
			13px/16px -apple-system,
			BlinkMacSystemFont,
			'SF Pro Text',
			sans-serif;
		color: rgba(0, 0, 0, 0.86);
		text-shadow: none;
		--secondary: rgba(0, 0, 0, 0.5);
		--tertiary: rgba(0, 0, 0, 0.28);
		--separator: rgba(0, 0, 0, 0.1);
		--accent: #007aff;
	}
	:global(.dark) .surface {
		background: rgba(40, 40, 44, 0.8);
		box-shadow:
			inset 0 0.5px 0 rgba(255, 255, 255, 0.2),
			0 18px 50px rgba(0, 0, 0, 0.5),
			0 0 0 0.5px rgba(255, 255, 255, 0.14);
		color: rgba(255, 255, 255, 0.88);
		--secondary: rgba(255, 255, 255, 0.55);
		--tertiary: rgba(255, 255, 255, 0.3);
		--separator: rgba(255, 255, 255, 0.12);
		--accent: #0a84ff;
	}

	.item {
		position: absolute;
		left: 8px;
		right: 8px;
	}
	.item.filter,
	.lit {
		height: 22px;
		padding: 0 8px;
		display: flex;
		align-items: center;
		gap: 8px;
	}
	.lit {
		border-radius: 4px;
	}
	.lit.on {
		background: var(--accent);
		color: white;
	}
	.text {
		flex: 1;
		white-space: nowrap;
	}
	.shortcut,
	.secondary {
		color: var(--secondary);
	}
	.lit.on .shortcut {
		color: white;
	}
	.count {
		color: var(--tertiary);
		font-variant-numeric: tabular-nums;
	}
	/* SectionHeader: the subheadline style, semibold, in the secondary colour. */
	.item.header {
		height: 14px;
		padding: 0 8px;
		font-size: 11px;
		line-height: 14px;
		font-weight: 600;
		color: var(--secondary);
	}
	.item.divider,
	.menu-item.separator {
		height: 9px;
		padding: 0 8px;
		display: flex;
		align-items: center;
	}
	hr {
		flex: 1;
		margin: 0;
		border: 0;
		height: 1px;
		background: var(--separator);
	}

	.app-icon,
	.tile,
	.glyph {
		flex: none;
		width: 16px;
		height: 16px;
	}
	.glyph {
		display: grid;
		place-items: center;
	}
	/* An app icon's squircle inside its 16 pt square, as macOS insets one. */
	.tile {
		box-sizing: border-box;
		margin: 1px;
		width: 14px;
		height: 14px;
		display: grid;
		place-items: center;
		border-radius: 3.4px;
		color: white;
		box-shadow:
			inset 0 0.5px 0 rgba(255, 255, 255, 0.35),
			0 0.5px 1px rgba(0, 0, 0, 0.25);
	}

	.spinner {
		position: relative;
		width: 11px;
		height: 11px;
	}
	.spinner i {
		position: absolute;
		left: 4.75px;
		top: 0;
		width: 1.5px;
		height: 3.5px;
		border-radius: 1px;
		background: currentColor;
		transform-origin: 0.75px 5.5px;
	}

	.menu-item {
		position: absolute;
		left: 5px;
		right: 5px;
	}
	.menu .lit {
		height: 24px;
		padding: 0 10px;
		border-radius: 6px;
	}
	.menu .lit.heading {
		font-size: 11px;
		font-weight: 600;
		color: var(--secondary);
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
