<script lang="ts">
	import Film from '../film/Film.svelte';
	import StatusItem from '../mac/StatusItem.svelte';
	import Symbol from '../mac/Symbol.svelte';
	import Window from '../mac/Window.svelte';
	import { statusSlot } from '../mac/geometry';
	import type { SymbolName } from '../mac/symbols';
	import { cardHeight, frameAt, note, notes, panel, size } from './demo';
	import type { Row } from './results';

	let { time, dark = false }: { time: number; dark?: boolean } = $props();

	const frame = $derived(frameAt(time));
	const card = $derived(cardHeight(frame.sections));

	// Each icon as Icon Services draws it, in the light and the dark icon style.
	const icons = import.meta.glob<string>('./icons/*/*.png', {
		eager: true,
		query: '?url',
		import: 'default'
	});
	const icon = (name: string) => icons[`./icons/${dark ? 'dark' : 'light'}/${name}.png`];

	/** Other apps' menu bar extras, left of Common Command's. */
	const others: SymbolName[] = ['icloud.fill', 'music.note'];

	/** The title in runs, the matched letters a step bolder, as ResultRow draws it. */
	function runs(row: Row): { text: string; bold: boolean }[] {
		const bold = new Set(row.bold ?? []);
		const out: { text: string; bold: boolean }[] = [];
		[...row.title].forEach((char, i) => {
			const b = bold.has(i);
			if (out.length && out[out.length - 1].bold === b) out[out.length - 1].text += char;
			else out.push({ text: char, bold: b });
		});
		return out;
	}
</script>

<Film {frame} {dark} slug="command" app="Notes" menus={['File', 'Edit', 'Format', 'View', 'Window', 'Help']}>
	{#snippet extras()}
		<div class="extras">
			{#each others as symbol (symbol)}
				<StatusItem width={statusSlot}><Symbol name={symbol} /></StatusItem>
			{/each}
			<StatusItem width={statusSlot} label="Common Command"
				><Symbol name="command" scale={14 / 22} /></StatusItem
			>
		</div>
	{/snippet}

	<Window title="Notes" {...notes} front>
		<div class="note">
			<h2>{note.title}</h2>
			{#each note.lines as line (line)}<p>{line}</p>{/each}
			<p>
				{note.last}{frame.added}<span class="note-caret" class:on={frame.noteCaret}></span>
			</p>
		</div>
	</Window>

	{#if frame.panel > 0}
		<div
			class="panel"
			style:left="{panel.x}px"
			style:top="{panel.y}px"
			style:width="{size.width}px"
			style:opacity={frame.panel}
		>
			<div class="field glass" style:height="{size.field}px">
				<span class="lead"
					><Symbol name="magnifyingglass" scale={(size.fieldFont * 0.82) / 13.5} /></span
				>
				<span class="query">
					{#if frame.query}
						<span class:selected={frame.selectAll}>{frame.query}</span>
					{/if}<span class="caret" class:on={frame.fieldCaret}></span>{#if !frame.query}<span
							class="placeholder">Search</span
						>{/if}
				</span>
				<span class="scopes">
					{#each ['square.grid.2x2', 'folder', 'bolt'] as const as scope (scope)}
						<span class="scope"><Symbol name={scope} /></span>
					{/each}
				</span>
			</div>

			{#if card > 0}
				<div class="results glass" style:height="{card}px" style:margin-top="{size.gap}px">
					<div class="list">
						{#each frame.sections as section, s (section.title)}
							<div class="header">{section.title}</div>
							{#each section.rows as row, r (row.title + r)}
								<div class="row" class:selected={s === 0 && r === 0}>
									{#if row.badge}
										<span class="kind-badge"
											><Symbol
												name={row.icon as SymbolName}
												scale={row.icon === 'equal' ? 1 : 12 / 13.5}
											/></span
										>
									{:else}
										<img
											src={icon(row.icon)}
											alt=""
											width={size.icon}
											height={size.icon}
										/>
									{/if}
									<span class="title"
										>{#each runs(row) as run, i (i)}{#if run.bold}<b>{run.text}</b
												>{:else}{run.text}{/if}{/each}</span
									>
									{#if row.subtitle}<span class="subtitle">{row.subtitle}</span>{/if}
								</div>
							{/each}
						{/each}
					</div>
				</div>
			{/if}
		</div>
	{/if}
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

	/* The note, in Notes' own type, set large enough to read in the film. */
	.note {
		padding: 24px 44px;
		font:
			22px/1.55 -apple-system,
			BlinkMacSystemFont,
			'SF Pro Text',
			sans-serif;
		letter-spacing: -0.01em;
	}
	/* The space under the title puts the gap between the field and the card between two lines. */
	.note h2 {
		margin: 0 0 22px;
		font:
			700 32px/1.2 -apple-system,
			BlinkMacSystemFont,
			'SF Pro Display',
			sans-serif;
		letter-spacing: -0.02em;
	}
	.note p {
		margin: 0;
	}
	/* Notes tints its caret yellow. */
	.note-caret {
		display: inline-block;
		width: 2px;
		height: 1.15em;
		margin-left: 1px;
		vertical-align: -0.2em;
		background: #e6a700;
		opacity: 0;
	}
	.note-caret.on {
		opacity: 1;
	}

	/*
	 * The panel: the field's capsule and the results card, each a piece of Liquid Glass with a hairline
	 * edge (Tokens.Color.borderCard) and the window's shadow following its outline.
	 */
	.panel {
		position: absolute;
		z-index: 10;
		--ink: #1d1d1f;
		--secondary: rgba(0, 0, 0, 0.5);
		--placeholder: rgba(0, 0, 0, 0.32);
		--accent: #007aff;
		--selection: rgba(0, 122, 255, 0.28);
		color: var(--ink);
	}
	:global(.dark) .panel {
		--ink: #f5f5f7;
		--secondary: rgba(255, 255, 255, 0.55);
		--placeholder: rgba(255, 255, 255, 0.35);
		--selection: rgba(64, 140, 255, 0.45);
	}
	.glass {
		position: relative;
		box-sizing: border-box;
		background: rgba(250, 250, 252, 0.74);
		backdrop-filter: blur(28px) saturate(1.7);
		box-shadow:
			inset 0 0 0 0.5px rgba(0, 0, 0, 0.06),
			inset 0 1px 0 rgba(255, 255, 255, 0.7),
			0 18px 50px rgba(0, 0, 0, 0.22),
			0 0 0 0.5px rgba(0, 0, 0, 0.1);
	}
	:global(.dark) .glass {
		background: rgba(36, 36, 40, 0.72);
		box-shadow:
			inset 0 0 0 0.5px rgba(255, 255, 255, 0.06),
			inset 0 1px 0 rgba(255, 255, 255, 0.1),
			0 18px 50px rgba(0, 0, 0, 0.5),
			0 0 0 0.5px rgba(0, 0, 0, 0.5);
	}

	.field {
		display: flex;
		align-items: center;
		gap: 8px;
		padding: 0 15px 0 18px;
		border-radius: 25px;
	}
	.lead {
		width: 22px;
		display: flex;
		justify-content: center;
		color: var(--secondary);
	}
	.query {
		flex: 1;
		display: flex;
		align-items: center;
		height: 100%;
		font-size: 20px;
		white-space: pre;
	}
	.query .selected {
		background: var(--selection);
		border-radius: 2px;
	}
	.placeholder {
		color: var(--placeholder);
	}
	.caret {
		width: 2px;
		height: 24px;
		margin: 0 1px;
		border-radius: 1px;
		background: var(--accent);
		opacity: 0;
	}
	.caret.on {
		opacity: 1;
	}
	.scopes {
		display: flex;
		gap: 2px;
	}
	.scope {
		width: 31px;
		height: 31px;
		display: grid;
		place-items: center;
		color: var(--secondary);
	}

	.results {
		border-radius: 20.4px;
		overflow: hidden;
	}
	.list {
		padding: 7px;
	}
	.header {
		height: 25.5px;
		box-sizing: border-box;
		display: flex;
		align-items: flex-end;
		padding: 0 8px 2px;
		font-size: 11px;
		font-weight: 600;
		color: var(--secondary);
	}
	.row {
		height: 34px;
		display: flex;
		align-items: center;
		gap: 8px;
		padding: 0 8px;
		border-radius: 13.4px;
		font-size: 14px;
	}
	.row.selected {
		background: var(--accent);
		color: #fff;
		--secondary: rgba(255, 255, 255, 0.6);
	}
	.row img {
		flex: none;
	}
	.title {
		flex: 1;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}
	.title b {
		font-weight: 600;
	}
	.subtitle {
		margin-left: 16px;
		font-size: 12px;
		color: var(--secondary);
		white-space: nowrap;
	}
	/* IconBadge: the kind's symbol on an accent gradient, rounded like an app icon. */
	.kind-badge {
		flex: none;
		width: 24px;
		height: 24px;
		display: grid;
		place-items: center;
		border-radius: 6.5px;
		color: #fff;
		background: linear-gradient(rgba(255, 255, 255, 0.18), rgba(255, 255, 255, 0)), var(--accent);
	}
</style>
