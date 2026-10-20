<script lang="ts">
	import Film from '../film/Film.svelte';
	import StatusItem from '../mac/StatusItem.svelte';
	import Symbol from '../mac/Symbol.svelte';
	import type { SymbolName } from '../mac/symbols';
	import Editor from './Editor.svelte';
	import Glyph from './Glyph.svelte';
	import Mochi from './Mochi.svelte';
	import Settings from './Settings.svelte';
	import {
		desktopFile,
		frameAt,
		itemWidth,
		menuOrigin,
		names,
		sheet,
		win,
		type GlyphID,
		type Source
	} from './demo';

	let { time, dark = false }: { time: number; dark?: boolean } = $props();

	const frame = $derived(frameAt(time));
	const sourceOf = (id: GlyphID): Source => frame.glyphs.find((g) => g.id === id)?.source ?? 'star';

	/** GlyphModel.summary: what the glyph is drawn from, and how. */
	function summary(id: GlyphID): string {
		const source = sourceOf(id);
		if (source === 'star' || source === 'kaomoji') return 'Text · Silhouette';
		if (source === 'flower') return 'Text · Colour';
		if (source === 'photo') return 'Image · Colour';
		if (source === 'subject') return 'Image · Colour · Subject lifted';
		return 'Image · Silhouette · Subject lifted';
	}

	const rows = $derived(
		frame.rows.map((id) => ({ name: names[id], source: sourceOf(id), summary: summary(id) }))
	);
	const sheetY = win.y + win.titleBar;

	/** MenuBarController's menu, below the card: SF Symbol icons on macOS 26, then Settings and Quit. */
	type Item = { title: string; symbol: SymbolName; key?: string; off?: boolean; subtitle?: string };
	const menu: (Item | 'separator')[] = [
		{ title: 'Edit Glyph…', symbol: 'slider.horizontal.3' },
		{ title: 'Choose Image…', symbol: 'photo' },
		// Enabled only while the clipboard holds an image.
		{ title: 'Paste Image', symbol: 'doc.on.clipboard', off: true },
		'separator',
		{ title: 'New Glyph', symbol: 'plus' },
		{ title: 'Hide Glyph', symbol: 'eye.slash', subtitle: 'Show it again in Settings' },
		'separator',
		{ title: 'Settings…', symbol: 'gearshape', key: '⌘,' },
		{ title: 'Quit Common Glyph', symbol: 'power', key: '⌘Q' }
	];
</script>

<Film {frame} {dark} slug="glyph" app="Common Glyph" menus={['Edit', 'Window']}>
	{#snippet extras()}
		<div class="extras">
			{#each frame.glyphs as glyph (glyph.id)}
				<StatusItem
					width={itemWidth(glyph.source) * glyph.entrance}
					open={glyph.id === 'mochi' && frame.menu > 0.5}
					label={names[glyph.id]}
				>
					<span class="glyph" style:opacity={glyph.entrance}><Glyph source={glyph.source} /></span>
				</StatusItem>
			{/each}
		</div>
	{/snippet}

	<figure
		class="file"
		style:left="{desktopFile.x - 40}px"
		style:top="{desktopFile.y - 30}px"
		class:lifted={!!frame.drag}
	>
		<span class="thumb"><Mochi mode="photo" width={64} height={48} /></span>
		<figcaption>mochi.png</figcaption>
	</figure>

	<section
		class="window"
		style:opacity={frame.settings}
		style:left="{win.x}px"
		style:top="{win.y}px"
		style:width="{win.width}px"
		style:height="{win.height}px"
	>
		<header style:height="{win.titleBar}px">
			<span class="lights"><i class="close"></i><i></i><i></i></span>
			<span class="title">Common Glyph Settings</span>
		</header>
		<div class="form">
			<Settings {rows} />
		</div>
	</section>

	{#if frame.sheet && frame.settings > 0}
		{@const s = frame.sheet}
		<div
			class="sheet form"
			style:left="{win.x}px"
			style:top="{sheetY}px"
			style:height="{sheet.height}px"
			style:opacity={s.open}
			style:transform="translateY({(1 - s.open) * -14}px) scale({0.97 + 0.03 * s.open})"
		>
			{#if s.id === 'mochi'}
				<Editor
					name="Mochi"
					glyph={sourceOf('mochi')}
					style={frame.style}
					alone
					source={{
						kind: 'image',
						picture: frame.picture,
						scroll: frame.scroll,
						background: frame.background,
						popup: frame.popup
					}}
				/>
			{:else}
				{@const text = frame.text[s.id]}
				<Editor
					name={names[s.id]}
					glyph={sourceOf(s.id)}
					style={text === '🌸' ? 'color' : 'silhouette'}
					alone={false}
					source={{ kind: 'text', text }}
				/>
			{/if}
		</div>
	{/if}

	{#snippet top()}
		{#if frame.drag}
			<figure class="file ghost" style:left="{frame.drag.x - 32}px" style:top="{frame.drag.y - 24}px">
				<span class="thumb"><Mochi mode="photo" width={64} height={48} /></span>
				{#if frame.drag.over}<b class="badge">+</b>{/if}
				<figcaption>mochi.png</figcaption>
			</figure>
		{/if}

		{#if frame.menu > 0}
			<div
				class="menu"
				style:left="{menuOrigin.x}px"
				style:top="{menuOrigin.y}px"
				style:opacity={frame.menu}
				style:transform="translateY({(1 - frame.menu) * -4}px)"
			>
				<div class="glyph-card">
					<span class="tile"><Glyph source={sourceOf('mochi')} fit={52 * 0.64} /></span>
					<span class="lines">
						<b>Mochi</b>
						<span>{summary('mochi')}</span>
						<span class="dim"
							>{frame.glyphs.length - 1 === 1
								? '1 other glyph'
								: `${frame.glyphs.length - 1} other glyphs`}</span
						>
					</span>
				</div>
				{#each menu as item, i (i)}
					{#if item === 'separator'}
						<hr />
					{:else}
						<div class="item" class:off={item.off} class:two={!!item.subtitle}>
							<span class="icon"><Symbol name={item.symbol} /></span>
							<span class="name"
								>{item.title}{#if item.subtitle}<small>{item.subtitle}</small>{/if}</span
							>
							{#if item.key}<kbd>{item.key}</kbd>{/if}
						</div>
					{/if}
				{/each}
			</div>
		{/if}
	{/snippet}
</Film>

<style>
	.extras {
		position: absolute;
		top: 0;
		right: 0;
		height: 100%;
		display: flex;
		align-items: center;
	}
	.glyph {
		display: flex;
		justify-content: center;
		overflow: hidden;
	}

	/* The picture on the desktop, as Finder shows an image file: its thumbnail and its name. */
	.file {
		position: absolute;
		width: 80px;
		margin: 0;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 5px;
	}
	.file.lifted {
		opacity: 0.55;
	}
	.thumb {
		display: block;
		border: 2px solid #fff;
		border-radius: 3px;
		overflow: hidden;
		box-shadow: 0 2px 6px rgba(0, 0, 0, 0.25);
	}
	.file figcaption {
		padding: 1px 6px;
		border-radius: 4px;
		font-size: 12px;
		line-height: 15px;
		color: #1d1d1f;
	}
	:global(.dark) .file figcaption {
		color: #f5f5f7;
		text-shadow: 0 1px 2px rgba(0, 0, 0, 0.6);
	}
	.ghost {
		z-index: 45;
		opacity: 0.75;
	}
	.badge {
		position: absolute;
		top: -8px;
		right: 0;
		width: 20px;
		height: 20px;
		display: grid;
		place-items: center;
		border-radius: 50%;
		background: #30c048;
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
		font:
			700 16px/1 -apple-system,
			BlinkMacSystemFont,
			sans-serif;
		color: #fff;
	}

	/* Settings: a titled, closable window (SettingsWindowHost), so only its close button is live. */
	.window {
		position: absolute;
		overflow: hidden;
		border-radius: 16px;
		background: var(--f-bg);
		box-shadow:
			0 30px 80px rgba(0, 0, 0, 0.28),
			0 0 0 0.5px rgba(0, 0, 0, 0.22);
		--f-bg: #fffefe;
	}
	:global(.dark) .window {
		--f-bg: #282828;
		box-shadow:
			0 30px 80px rgba(0, 0, 0, 0.6),
			0 0 0 0.5px rgba(255, 255, 255, 0.16);
	}
	.window header {
		display: flex;
		align-items: center;
		padding: 0 14px;
	}
	.lights {
		display: flex;
		gap: 8px;
	}
	.lights i {
		width: 12px;
		height: 12px;
		border-radius: 50%;
		background: rgba(128, 128, 128, 0.3);
	}
	.lights i.close {
		background: #ff5f57;
		box-shadow: inset 0 0 0 0.5px rgba(0, 0, 0, 0.12);
	}
	.title {
		flex: 1;
		margin-right: 52px;
		text-align: center;
		font-size: 13px;
		font-weight: 600;
		color: #3c3c43;
	}
	:global(.dark) .title {
		color: #d1d1d6;
	}

	/* The editor's sheet over Settings. */
	.sheet {
		position: absolute;
		z-index: 5;
		width: 460px;
		border-radius: 0 0 16px 16px;
		background: var(--f-bg);
		box-shadow:
			0 18px 50px rgba(0, 0, 0, 0.3),
			0 0 0 0.5px rgba(0, 0, 0, 0.18);
		transform-origin: 50% 0;
	}
	:global(.dark) .sheet {
		box-shadow:
			0 18px 50px rgba(0, 0, 0, 0.6),
			0 0 0 0.5px rgba(255, 255, 255, 0.14);
	}

	/* A grouped SwiftUI Form on macOS 26 (`.formStyle(.grouped)`, 460 points wide): rounded sections
	   on the window's background, Title Case headers, secondary footnotes. Colours were sampled from
	   offscreen renders of Common Glyph's views; controls are drawn as they look in the key window. */
	.form {
		position: relative;
		font:
			13px/16px -apple-system,
			BlinkMacSystemFont,
			'SF Pro Text',
			sans-serif;
		color: var(--f-label);
		text-shadow: none;
		--f-bg: #fffefe;
		--f-section: #f5f5f5;
		--f-rule: #e6e6e6;
		--f-label: rgba(0, 0, 0, 0.85);
		--f-secondary: rgba(0, 0, 0, 0.5);
		--f-tertiary: rgba(0, 0, 0, 0.26);
		--f-control: #e3e3e3;
		--f-selected: #fff;
		--f-accent: #0a84ff;
		--f-knob: #fff;
	}
	:global(.dark) .form {
		--f-bg: #282828;
		--f-section: #313131;
		--f-rule: #3d3d3d;
		--f-label: rgba(255, 255, 255, 0.88);
		--f-secondary: rgba(255, 255, 255, 0.55);
		--f-tertiary: rgba(255, 255, 255, 0.25);
		--f-control: #454545;
		--f-selected: #6b6b6e;
		--f-knob: #f2f2f2;
	}
	.form :global(.f-sheet) {
		position: relative;
	}
	.form :global(.f-scroll) {
		position: relative;
		overflow: hidden;
	}
	.form :global(.f-content) {
		position: relative;
		height: 900px;
	}
	.form :global(.f-section) {
		margin: 0 20px;
		padding: 0 10px;
		border-radius: 10px;
		background: var(--f-section);
	}
	.form :global(.f-preview) {
		padding: 10px;
		display: flex;
		flex-direction: column;
		gap: 8px;
	}
	.form :global(.f-row) {
		height: 40px;
		display: flex;
		align-items: center;
		gap: 8px;
		white-space: nowrap;
	}
	.form :global(.f-row.short) {
		height: 37px;
	}
	.form :global(.f-row.short2) {
		height: 39px;
	}
	.form :global(.f-row.short3) {
		height: 38px;
	}
	.form :global(.f-row.tall) {
		height: 44px;
	}
	.form :global(.f-row.buttons) {
		height: 44px;
	}
	.form :global(.f-row.listed) {
		height: 52px;
		gap: 12px;
	}
	.form :global(.f-row.add) {
		height: 47px;
	}
	.form :global(.f-row + .f-row),
	.form :global(.f-rule) {
		border-top: 1px solid var(--f-rule);
	}
	.form :global(.f-grow) {
		flex: 1;
	}
	.form :global(.f-header) {
		height: 18px;
		margin: 0 30px 9px;
		font-size: 13px;
		font-weight: 700;
		line-height: 18px;
	}
	.form :global(.f-foot) {
		margin: 7px 30px 0;
		font-size: 12px;
		line-height: 15px;
		color: var(--f-secondary);
		white-space: normal;
	}
	.form :global(.f-secondary) {
		color: var(--f-secondary);
	}
	.form :global(.title3) {
		font-size: 15px;
	}
	.form :global(.f-two) {
		display: flex;
		flex-direction: column;
		gap: 1px;
	}
	.form :global(.f-two small) {
		font-size: 11px;
		line-height: 14px;
		color: var(--f-secondary);
	}
	.form :global(.f-chevron) {
		color: var(--f-tertiary);
	}
	.form :global(.f-tile) {
		width: 32px;
		height: 32px;
		flex: none;
		display: grid;
		place-items: center;
		border-radius: 8.6px;
		background: rgba(0, 0, 0, 0.047);
		box-shadow: inset 0 0 0 0.5px rgba(0, 0, 0, 0.06);
	}
	:global(.dark) .form :global(.f-tile) {
		background: rgba(255, 255, 255, 0.047);
		box-shadow: inset 0 0 0 0.5px rgba(255, 255, 255, 0.06);
	}
	.form :global(img) {
		flex: none;
	}

	/* MenuBarPreview: each bar forced to one appearance, whatever the window's. */
	.form :global(.f-bar) {
		height: 28px;
		padding: 0 12px;
		display: flex;
		align-items: center;
		justify-content: flex-end;
		gap: 14px;
		border-radius: 8px;
		font-weight: 500;
	}
	.form :global(.f-bar.light) {
		background: #fffefe;
		color: rgba(0, 0, 0, 0.88);
		box-shadow: inset 0 0 0 1px rgba(0, 0, 0, 0.1);
	}
	.form :global(.f-bar.dark) {
		background: #232323;
		color: rgba(255, 255, 255, 0.92);
		box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.16);
	}

	/* Push buttons: a soft fill, the default one in the accent colour. */
	.form :global(.f-btn) {
		height: 24px;
		padding: 0 12px;
		display: inline-flex;
		flex: none;
		align-items: center;
		justify-content: center;
		border-radius: 7px;
		background: var(--f-control);
		white-space: nowrap;
	}
	.form :global(.f-btn.icon) {
		padding: 0 11px;
	}
	.form :global(.f-btn.default) {
		background: var(--f-accent);
		color: #fff;
	}
	.form :global(.f-btn.off) {
		color: var(--f-tertiary);
	}

	/* Segmented pickers: a raised selection on a sunken track. */
	.form :global(.f-seg) {
		height: 24px;
		padding: 1px;
		box-sizing: border-box;
		display: flex;
		border-radius: 7px;
		background: var(--f-control);
	}
	.form :global(.f-seg > span) {
		flex: 1;
		display: flex;
		align-items: center;
		justify-content: center;
		border-radius: 6px;
	}
	.form :global(.f-seg > span.on) {
		background: var(--f-selected);
		box-shadow:
			0 1px 2px rgba(0, 0, 0, 0.14),
			0 0 0 0.5px rgba(0, 0, 0, 0.06);
	}

	/* Switches: on in the accent colour; one that can't be turned off is dimmed. */
	.form :global(.f-switch) {
		position: relative;
		flex: none;
		width: 36px;
		height: 20px;
		border-radius: 10px;
		background: var(--f-control);
	}
	.form :global(.f-switch.on) {
		background: var(--f-accent);
	}
	.form :global(.f-switch.small) {
		width: 30px;
		height: 17px;
	}
	.form :global(.f-switch.disabled) {
		opacity: 0.45;
	}
	.form :global(.f-switch::after) {
		content: '';
		position: absolute;
		top: 2px;
		left: 2px;
		width: 22px;
		height: calc(100% - 4px);
		border-radius: 999px;
		background: var(--f-knob);
		box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
	}
	.form :global(.f-switch.small::after) {
		width: 17px;
	}
	.form :global(.f-switch.on::after) {
		left: auto;
		right: 2px;
	}

	.form :global(.f-slider) {
		position: relative;
		width: 220px;
		height: 4px;
		border-radius: 2px;
		background: var(--f-control);
	}
	.form :global(.f-slider > i) {
		position: absolute;
		top: 0;
		bottom: 0;
		left: 0;
		border-radius: 2px;
		background: var(--f-accent);
	}
	.form :global(.f-slider b) {
		position: absolute;
		top: -8px;
		width: 22px;
		height: 20px;
		margin-left: -11px;
		border-radius: 999px;
		background: var(--f-knob);
		box-shadow:
			0 1px 3px rgba(0, 0, 0, 0.25),
			0 0 0 0.5px rgba(0, 0, 0, 0.08);
	}

	.form :global(.f-popup) {
		display: flex;
		align-items: center;
		gap: 9px;
	}
	.form :global(.f-popup > i) {
		width: 20px;
		height: 20px;
		display: grid;
		place-items: center;
		border-radius: 6px;
		background: var(--f-control);
	}

	/* The image source: the drop zone, then CropEditor's picture under its crop box. */
	.form :global(.well) {
		position: relative;
		height: 281px;
		padding: 10px 0;
	}
	.form :global(.f-drop) {
		position: absolute;
		inset: 10px 0;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 4px;
		color: var(--f-secondary);
	}
	.form :global(.f-drop svg) {
		position: absolute;
		inset: 0;
		color: var(--f-tertiary);
	}
	.form :global(.f-drop span) {
		margin-top: 4px;
		color: var(--f-label);
	}
	.form :global(.f-drop small) {
		font-size: 12px;
	}
	.form :global(.f-crop) {
		position: absolute;
		top: 10px;
	}
	.form :global(.f-crop .box) {
		position: absolute;
		inset: 0;
		box-shadow:
			inset 0 0 0 2.5px rgba(30, 30, 34, 0.55),
			inset 0 0 0 2px #fff;
	}
	.form :global(.f-crop .handle) {
		position: absolute;
		width: 12px;
		height: 12px;
		margin: -6px;
		border-radius: 50%;
		background: #fff;
		box-shadow: 0 0 0 1px rgba(30, 30, 34, 0.55);
	}
	.form :global(.handle.tl) {
		left: 0;
		top: 0;
	}
	.form :global(.handle.tr) {
		right: 0;
		top: 0;
	}
	.form :global(.handle.bl) {
		left: 0;
		bottom: 0;
	}
	.form :global(.handle.br) {
		right: 0;
		bottom: 0;
	}

	.form :global(.f-grid) {
		padding: 10px 0 11px;
		display: grid;
		grid-template-columns: repeat(6, 1fr);
		gap: 3px 4px;
	}
	.form :global(.f-grid .f-btn) {
		height: 34px;
		padding: 0;
		font-size: 15px;
		overflow: hidden;
	}

	/* The sheet's own buttons, under a rule. */
	.form :global(.f-footer) {
		height: 57px;
		padding: 0 16px;
		box-sizing: border-box;
		display: flex;
		align-items: center;
		gap: 8px;
		border-top: 1px solid var(--f-rule);
	}

	/* The Background pop-up's menu, as NSPopUpButton opens it: the checked row over the button. */
	.form :global(.f-menu) {
		position: absolute;
		z-index: 10;
		padding: 6px 5px;
		border-radius: 12px;
		background: rgba(246, 246, 248, 0.92);
		backdrop-filter: blur(30px);
		box-shadow:
			0 12px 36px rgba(0, 0, 0, 0.22),
			0 0 0 0.5px rgba(0, 0, 0, 0.14);
	}
	:global(.dark) .form :global(.f-menu) {
		background: rgba(44, 44, 48, 0.92);
		box-shadow:
			0 12px 36px rgba(0, 0, 0, 0.5),
			0 0 0 0.5px rgba(255, 255, 255, 0.14);
	}
	.form :global(.f-menu span) {
		height: 24px;
		padding: 0 8px 0 4px;
		display: flex;
		align-items: center;
		border-radius: 6px;
	}
	.form :global(.f-menu span.hover) {
		background: var(--f-accent);
		color: #fff;
	}
	.form :global(.f-menu span > i) {
		width: 20px;
		display: flex;
		justify-content: center;
	}

	/* A menu in macOS 26: Liquid Glass, larger corners. */
	.menu {
		position: absolute;
		z-index: 30;
		width: 320px;
		padding: 5px 0;
		border-radius: 14px;
		background: rgba(246, 246, 248, 0.84);
		backdrop-filter: blur(40px) saturate(1.8);
		box-shadow:
			inset 0 0.5px 0 rgba(255, 255, 255, 0.9),
			0 18px 50px rgba(0, 0, 0, 0.22),
			0 0 0 0.5px rgba(0, 0, 0, 0.14);
		font:
			13px/16px -apple-system,
			BlinkMacSystemFont,
			'SF Pro Text',
			sans-serif;
		color: #1d1d1f;
		text-shadow: none;
		--secondary: rgba(0, 0, 0, 0.5);
		--tertiary: rgba(0, 0, 0, 0.28);
		--tint: rgba(0, 0, 0, 0.047);
		--hairline: rgba(0, 0, 0, 0.06);
		--rule: rgba(0, 0, 0, 0.1);
	}
	:global(.dark) .menu {
		background: rgba(36, 36, 40, 0.8);
		box-shadow:
			inset 0 0.5px 0 rgba(255, 255, 255, 0.22),
			0 18px 50px rgba(0, 0, 0, 0.5),
			0 0 0 0.5px rgba(255, 255, 255, 0.14);
		color: #f5f5f7;
		--secondary: rgba(255, 255, 255, 0.55);
		--tertiary: rgba(255, 255, 255, 0.3);
		--tint: rgba(255, 255, 255, 0.047);
		--hairline: rgba(255, 255, 255, 0.06);
		--rule: rgba(255, 255, 255, 0.12);
	}
	/* GlyphCard: Common UI's Card, inset 8 by 4, holding the glyph's tile, its name and its summary. */
	.glyph-card {
		margin: 4px 8px;
		padding: 12px;
		display: flex;
		align-items: center;
		gap: 12px;
		border-radius: 12px;
		background: var(--tint);
		box-shadow: inset 0 0 0 0.5px var(--hairline);
	}
	.tile {
		width: 52px;
		height: 52px;
		flex: none;
		display: grid;
		place-items: center;
		border-radius: 14px;
		background: var(--tint);
		box-shadow: inset 0 0 0 0.5px var(--hairline);
	}
	.lines {
		display: flex;
		flex-direction: column;
		gap: 4px;
		font-size: 11px;
		line-height: 13px;
		color: var(--secondary);
	}
	.lines b {
		font-size: 13px;
		line-height: 16px;
		color: #1d1d1f;
	}
	:global(.dark) .lines b {
		color: #f5f5f7;
	}
	.lines .dim {
		color: var(--tertiary);
	}
	hr {
		margin: 5px 14px;
		border: 0;
		border-top: 1px solid var(--rule);
	}
	.item {
		height: 24px;
		margin: 0 5px;
		padding: 0 10px 0 8px;
		display: flex;
		align-items: center;
		gap: 8px;
		border-radius: 6px;
	}
	.item.two {
		height: 36px;
	}
	.item.off {
		color: var(--tertiary);
	}
	.icon {
		width: 18px;
		display: flex;
		justify-content: center;
	}
	.name {
		flex: 1;
		display: flex;
		flex-direction: column;
	}
	.name small {
		font-size: 11px;
		line-height: 14px;
		color: var(--secondary);
	}
	/* A menu writes its shortcuts as plain text; undo the site's global key cap. */
	kbd {
		all: unset;
		font: inherit;
		color: var(--secondary);
	}
</style>
