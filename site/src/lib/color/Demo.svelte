<script lang="ts">
	import Film from '../film/Film.svelte';
	import StatusItem from '../mac/StatusItem.svelte';
	import Symbol from '../mac/Symbol.svelte';
	import Window from '../mac/Window.svelte';
	import { statusSlot } from '../mac/geometry';
	import type { SymbolName } from '../mac/symbols';
	import {
		bands,
		contrast,
		css,
		editorMetrics,
		family,
		formats,
		frameAt,
		horizon,
		loupe,
		magnified,
		palette,
		poster,
		recent,
		stage,
		sun,
		sunLine,
		windows
	} from './demo';

	let { time, dark = false }: { time: number; dark?: boolean } = $props();

	const frame = $derived(frameAt(time));
	const grid = $derived(frame.loupe ? magnified(frame.loupe) : []);
	const order = $derived(
		frame.front === 'browser' ? (['editor', 'browser'] as const) : (['browser', 'editor'] as const)
	);
	const lines = $derived(
		css.map((line, i) =>
			i === sunLine && frame.pasted ? line.replace(': ;', `: ${palette.sun};`) : line
		)
	);
	const copied = $derived(frame.card ? formats[frame.card.format] : null);

	/** Other apps' menu bar extras, left of Common Color. */
	const others: SymbolName[] = ['icloud.fill', 'music.note'];

	/** A line of CSS in its parts, so a hex value gets the editor's colour swatch before it. */
	function tokens(line: string): { kind: string; text: string }[] {
		if (line.startsWith('/*')) return [{ kind: 'comment', text: line }];
		const property = line.match(/^(\s*)(--[a-z]+|[a-z-]+)(:\s*)(.*)$/);
		if (property) {
			const [, indent, name, colon, rest] = property;
			const value = rest.match(/^(#[0-9a-f]{6})(;)$/);
			return [
				{ kind: 'plain', text: indent },
				{ kind: 'property', text: name },
				{ kind: 'plain', text: colon },
				...(value
					? [
							{ kind: 'swatch', text: value[1] },
							{ kind: 'value', text: value[1] },
							{ kind: 'plain', text: value[2] }
						]
					: [{ kind: rest.startsWith('var') ? 'function' : 'plain', text: rest }])
			];
		}
		return [{ kind: line.trim() === '}' ? 'plain' : 'selector', text: line }];
	}

	// Where the poster sits in the browser window's body, under its 52-point title bar.
	const posterIn = { x: poster.x - windows.browser.x, y: poster.y - windows.browser.y - 52 };
	const half = (loupe.cells * loupe.cell) / 2;
	const gridlines = Array.from({ length: loupe.cells - 1 }, (_, k) => (k + 1) * loupe.cell);
	/** The editor's colour swatch and its margin, before a hex value. */
	const decorator = 14;
	const verdicts = contrast.rows.map((row) => ({
		size: row.size,
		levels: [
			{ level: 'AA', passes: row.aa },
			{ level: 'AAA', passes: row.aaa }
		]
	}));
</script>

<Film
	{frame}
	{dark}
	slug="color"
	app={frame.front === 'browser' ? 'Safari' : 'Code'}
	menus={frame.front === 'browser'
		? ['File', 'Edit', 'View', 'History', 'Bookmarks', 'Window', 'Help']
		: ['File', 'Edit', 'Selection', 'View', 'Go', 'Run', 'Terminal', 'Window', 'Help']}
>
	{#snippet extras()}
		<div class="extras">
			{#each others as symbol (symbol)}
				<StatusItem width={statusSlot}><Symbol name={symbol} /></StatusItem>
			{/each}
			<StatusItem width={statusSlot} open={frame.panel > 0.5} label="Common Color"
				><Symbol name="eyedropper" /></StatusItem
			>
		</div>
	{/snippet}

	{#each order as id (id)}
		{#if id === 'browser'}
			<Window title="kiln.studio" {...windows.browser} front={frame.front === 'browser'}>
				<div class="page" style:height="{windows.browser.height - 52}px">
					<svg
						class="poster"
						style:left="{posterIn.x}px"
						style:top="{posterIn.y}px"
						width={poster.width}
						height={poster.height}
						viewBox="{poster.x} {poster.y} {poster.width} {poster.height}"
						shape-rendering="geometricPrecision"
					>
						<rect
							x={poster.x}
							y={poster.y}
							width={poster.width}
							height={poster.height}
							fill={palette.ink}
						/>
						<circle cx={sun.x} cy={sun.y} r={sun.r} fill={palette.sun} />
						<rect
							x={poster.x}
							y={horizon}
							width={poster.width}
							height={poster.y + poster.height - horizon}
							fill={palette.paper}
						/>
						{#each bands as band (band.y)}
							<rect
								x={poster.x}
								y={band.y}
								width={poster.width}
								height={band.height}
								fill={band.color}
							/>
						{/each}
						<text
							x={poster.x + 32}
							y={poster.y + poster.height - 64}
							class="poster-title"
							fill={palette.ink}>SUNSET No. 4</text
						>
						<text
							x={poster.x + 32}
							y={poster.y + poster.height - 40}
							class="poster-by"
							fill={palette.ink}>KILN STUDIO · SCREEN PRINT</text
						>
					</svg>
					<div
						class="about"
						style:left="{posterIn.x + poster.width + 56}px"
						style:top="{posterIn.y + 20}px"
					>
						<p class="kicker">Kiln Studio</p>
						<h2>Sunset No. 4</h2>
						<p class="lede-text">
							Screen print in five inks on 300 g cotton paper. Signed and numbered.
						</p>
						<dl>
							<div>
								<dt>Size</dt>
								<dd>50 × 70 cm</dd>
							</div>
							<div>
								<dt>Edition</dt>
								<dd>40</dd>
							</div>
						</dl>
						<p class="price">€45</p>
						<span class="buy">Add to Cart</span>
					</div>
				</div>
			</Window>
		{:else}
			<Window title="tokens.css — kiln-site" {...windows.editor} front={frame.front === 'editor'}>
				<div class="code" style:padding-top="{editorMetrics.top}px">
					{#each lines as line, i (i)}
						<div class="line" style:height="{editorMetrics.line}px">
							<span class="number" style:width="{editorMetrics.gutter}px">{i + 1}</span>
							<span class="src"
								>{#each tokens(line) as token, j (j)}{#if token.kind === 'swatch'}<i
											class="decorator"
											style:background={token.text}
										></i>{:else}<span class={token.kind}>{token.text}</span
										>{/if}{/each}{#if i === sunLine && frame.front === 'editor'}<span
										class="caret"
										class:on={frame.caretOn}
										style:left="{editorMetrics.char * line.indexOf(';') +
											(frame.pasted ? decorator : 0)}px"
									></span>{/if}</span
							>
						</div>
					{/each}
				</div>
			</Window>
		{/if}
	{/each}

	{#snippet top()}
		{#if frame.panel > 0}
			<div
				class="panel"
				style:left="{stage.panel.x}px"
				style:top="{stage.panel.y}px"
				style:opacity={frame.panel}
			>
				<div class="row" class:hover={frame.hover === 'pick'}>
					<span class="icon"><Symbol name="eyedropper" /></span>
					<span class="title">Pick Color</span>
					<span class="shortcut">⌃⇧⌘C</span>
				</div>

				<section class="group">
					<div class="hero">
						<i class="swatch big" style:background={palette.sun}></i>
						<div>
							<p class="hex">{formats[0].text}</p>
							<p class="family">{family}</p>
						</div>
					</div>
					<div class="formats">
						<div class="row copy" class:hover={frame.hover === 'copy'}>
							<span class="title">Copy as Hex</span>
							<span class="shortcut">↩</span>
						</div>
						{#if frame.formats > 0}
							<div
								class="more"
								style:height="{frame.formats * 126}px"
								style:opacity={frame.formats}
							>
								{#each formats.slice(1) as format, i (format.title)}
									<div class="row format" class:hover={frame.hover === i + 1}>
										<span class="name">{format.title}</span>
										<span class="value">{format.text}</span>
										<span class="shortcut">{i + 2}</span>
									</div>
								{/each}
							</div>
						{/if}
					</div>
					<p class="toggle">
						{frame.formats > 0 ? 'Fewer Formats' : 'All Formats'}
						<Symbol name={frame.formats > 0 ? 'chevron.up' : 'chevron.down'} />
					</p>
				</section>

				<section class="group">
					<header>
						<b>Recent</b><span class="detail">{recent.length} colors</span><span class="clear"
							>Clear</span
						>
					</header>
					<div class="recent">
						{#each recent as color, i (color)}
							<span class="cell" class:selected={i === 0}
								><i class="swatch" style:background={color}></i></span
							>
						{/each}
					</div>
				</section>

				<section class="group">
					<header><b>Contrast</b><span class="detail">Newest two picks</span></header>
					<div class="ratio">
						<span class="sample" style:background={palette.ink} style:color={palette.sun}>Aa</span
						>
						<div>
							<p class="ratio-text">{contrast.text}</p>
							<p class="family">{contrast.verdict}</p>
						</div>
					</div>
					<div class="verdicts">
						{#each verdicts as row (row.size)}
							<span class="size">{row.size} text</span>
							{#each row.levels as { level, passes } (level)}
								<span class="verdict" class:passes>
									<Symbol name={passes ? 'checkmark.circle.fill' : 'xmark.circle'} />
									<span>{level}</span>
								</span>
							{/each}
						{/each}
					</div>
				</section>

				<hr />
				<div class="rows">
					<div class="row">
						<span class="icon"><Symbol name="gearshape" /></span>
						<span class="title">Settings…</span>
						<span class="shortcut">⌘,</span>
					</div>
					<div class="row">
						<span class="icon"><Symbol name="power" /></span>
						<span class="title">Quit Common Color</span>
						<span class="shortcut">⌘Q</span>
					</div>
				</div>
			</div>
		{/if}

		{#if frame.card && copied}
			<div
				class="confirmation"
				style:left="{frame.card.x}px"
				style:top="{frame.card.y}px"
				style:opacity={frame.card.opacity}
			>
				<i class="swatch" style:background={palette.sun}></i>
				<div>
					<p class="what">Copied as {copied.title}</p>
					<p class="text">{copied.text}</p>
				</div>
			</div>
		{/if}

		{#if frame.loupe}
			<div
				class="loupe"
				style:left="{frame.loupe.x - half}px"
				style:top="{frame.loupe.y - half}px"
				style:width="{half * 2}px"
				style:height="{half * 2}px"
				style:opacity={frame.loupe.opacity}
				style:transform="scale({0.9 + 0.1 * frame.loupe.opacity})"
			>
				<svg width={half * 2} height={half * 2} viewBox="0 0 {half * 2} {half * 2}">
					{#each grid as row, j (j)}
						{#each row as color, i (i)}
							<rect
								x={i * loupe.cell}
								y={j * loupe.cell}
								width={loupe.cell}
								height={loupe.cell}
								fill={color}
							/>
						{/each}
					{/each}
					{#each gridlines as at (at)}
						<line x1={at} x2={at} y1="0" y2={half * 2} class="gridline" />
						<line y1={at} y2={at} x1="0" x2={half * 2} class="gridline" />
					{/each}
					<rect
						x={half - loupe.cell / 2}
						y={half - loupe.cell / 2}
						width={loupe.cell}
						height={loupe.cell}
						class="target"
					/>
				</svg>
				<span class="rim"></span>
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

	/* The browser's page: a print shop's product page, light or dark as the system is. */
	.page {
		position: relative;
		background: #fbfaf7;
		color: #1d1d1f;
		--soft: #6e6e73;
		--line: rgba(0, 0, 0, 0.08);
	}
	:global(.dark) .page {
		background: #161617;
		color: #f5f5f7;
		--soft: #98989d;
		--line: rgba(255, 255, 255, 0.1);
	}
	.poster {
		position: absolute;
		display: block;
		box-shadow:
			0 18px 40px rgba(0, 0, 0, 0.18),
			0 0 0 0.5px rgba(0, 0, 0, 0.1);
	}
	.poster-title {
		font:
			800 30px/1 -apple-system,
			BlinkMacSystemFont,
			'SF Pro Display',
			sans-serif;
		letter-spacing: 0.04em;
	}
	.poster-by {
		font:
			600 11px/1 -apple-system,
			BlinkMacSystemFont,
			sans-serif;
		letter-spacing: 0.16em;
	}
	.about {
		position: absolute;
		width: 300px;
	}
	.about p,
	.about h2,
	.about dl {
		margin: 0;
	}
	.kicker {
		font-size: 12px;
		font-weight: 600;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		color: var(--soft);
	}
	.about h2 {
		margin-top: 10px;
		font:
			700 38px/1.1 -apple-system,
			BlinkMacSystemFont,
			'SF Pro Display',
			sans-serif;
		letter-spacing: -0.02em;
	}
	.lede-text {
		margin-top: 16px !important;
		font-size: 16px;
		line-height: 1.5;
		color: var(--soft);
	}
	.about dl {
		margin-top: 24px;
		border-top: 1px solid var(--line);
	}
	.about dl div {
		display: flex;
		justify-content: space-between;
		padding: 12px 0;
		border-bottom: 1px solid var(--line);
		font-size: 15px;
	}
	.about dt {
		color: var(--soft);
	}
	.about dd {
		margin: 0;
	}
	.price {
		margin-top: 28px !important;
		font-size: 26px;
		font-weight: 600;
	}
	.buy {
		display: inline-block;
		margin-top: 16px;
		padding: 13px 28px;
		border-radius: 999px;
		background: #14213d;
		color: #f4efe6;
		font-size: 15px;
		font-weight: 600;
	}
	:global(.dark) .buy {
		background: #f4efe6;
		color: #14213d;
	}

	/* The editor: line numbers, CSS in a quiet theme, and a swatch before each colour, as editors draw them. */
	.code {
		font:
			15px/26px 'SF Mono',
			ui-monospace,
			Menlo,
			monospace;
		white-space: pre;
		--comment: #8e8e93;
		--property: #2f5fb3;
		--selector: #8a3fb0;
		--value: #b3480f;
		--number: #b0b0b5;
	}
	:global(.dark) .code {
		--comment: #7c7c82;
		--property: #8cb4ff;
		--selector: #d7a4f5;
		--value: #ffad7a;
		--number: #5c5c62;
	}
	.line {
		display: flex;
	}
	.number {
		flex: none;
		padding-right: 16px;
		box-sizing: content-box;
		text-align: right;
		color: var(--number);
	}
	.src {
		position: relative;
	}
	.comment {
		color: var(--comment);
	}
	.property {
		color: var(--property);
	}
	.selector {
		color: var(--selector);
	}
	.value,
	.function {
		color: var(--value);
	}
	.decorator {
		display: inline-block;
		width: 10px;
		height: 10px;
		margin: 0 4px 0 0;
		vertical-align: -1px;
		box-shadow: 0 0 0 1px rgba(128, 128, 128, 0.5);
	}
	.caret {
		position: absolute;
		top: 4px;
		width: 2px;
		height: 18px;
		background: #0a84ff;
		opacity: 0;
	}
	.caret.on {
		opacity: 1;
	}

	/* Common Color's panel, to the app's renders: MenuPanelSurface around ColorPanel. Sizes in points. */
	.panel {
		position: absolute;
		z-index: 30;
		width: 336px;
		box-sizing: border-box;
		padding: 8px;
		display: flex;
		flex-direction: column;
		gap: 8px;
		border-radius: 12px;
		background: rgba(244, 244, 246, 0.84);
		backdrop-filter: blur(40px) saturate(1.8);
		box-shadow:
			inset 0 0.5px 0 rgba(255, 255, 255, 0.9),
			0 18px 50px rgba(0, 0, 0, 0.22),
			0 0 0 0.5px rgba(0, 0, 0, 0.16);
		font:
			13px/16px -apple-system,
			BlinkMacSystemFont,
			'SF Pro Text',
			sans-serif;
		text-shadow: none;
		color: var(--label);
		--label: rgba(0, 0, 0, 0.85);
		--secondary: rgba(0, 0, 0, 0.5);
		--tertiary: rgba(0, 0, 0, 0.26);
		--card: rgba(0, 0, 0, 0.047);
		--card-line: rgba(0, 0, 0, 0.059);
		--separator: rgba(0, 0, 0, 0.1);
		--accent: #007aff;
		--success: #34c759;
		--danger: #ff3b30;
	}
	:global(.dark) .panel {
		background: rgba(38, 38, 42, 0.8);
		box-shadow:
			inset 0 0.5px 0 rgba(255, 255, 255, 0.2),
			0 18px 50px rgba(0, 0, 0, 0.5),
			0 0 0 0.5px rgba(255, 255, 255, 0.16);
		--label: rgba(255, 255, 255, 0.86);
		--secondary: rgba(255, 255, 255, 0.55);
		--tertiary: rgba(255, 255, 255, 0.25);
		--card: rgba(255, 255, 255, 0.047);
		--card-line: rgba(255, 255, 255, 0.059);
		--separator: rgba(255, 255, 255, 0.12);
		--accent: #0a84ff;
		--success: #30d158;
		--danger: #ff453a;
	}
	.panel p {
		margin: 0;
	}
	.row {
		height: 22px;
		padding: 0 8px;
		display: flex;
		align-items: center;
		gap: 8px;
		border-radius: 4px;
	}
	.row .icon {
		width: 16px;
		display: flex;
		justify-content: center;
	}
	.row .title {
		flex: 1;
	}
	.shortcut {
		color: var(--secondary);
		font-variant-numeric: tabular-nums;
	}
	.row.hover {
		background: var(--accent);
		color: #fff;
	}
	.row.hover .shortcut,
	.row.hover .name {
		color: #fff;
	}
	.group {
		padding: 12px;
		border-radius: 12px;
		background: var(--card);
		box-shadow: inset 0 0 0 0.5px var(--card-line);
	}
	.swatch {
		display: block;
		width: 34px;
		height: 34px;
		border-radius: 4px;
		box-shadow: inset 0 0 0 1px var(--card-line);
	}
	.swatch.big {
		width: 64px;
		height: 64px;
		border-radius: 8px;
	}
	.hero {
		display: flex;
		align-items: center;
		gap: 12px;
	}
	.hex,
	.ratio-text {
		font:
			600 17px/22px 'SF Mono',
			ui-monospace,
			Menlo,
			monospace;
	}
	.ratio-text {
		font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
		font-variant-numeric: tabular-nums;
	}
	.family {
		margin-top: 2px !important;
		font-size: 11px;
		line-height: 14px;
		color: var(--secondary);
	}
	.formats {
		margin-top: 8px;
	}
	.row.copy {
		height: 26px;
		padding: 0 4px;
	}
	.more {
		overflow: hidden;
	}
	.row.format {
		height: 21px;
		padding: 0 4px;
		font-size: 12px;
	}
	.format .name {
		flex: none;
		width: 68px;
		color: var(--secondary);
	}
	.format .value {
		flex: 1;
		min-width: 0;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		font-family: 'SF Mono', ui-monospace, Menlo, monospace;
	}
	.toggle {
		margin-top: 8px !important;
		padding: 0 4px;
		height: 13px;
		display: flex;
		align-items: center;
		gap: 4px;
		font-size: 10px;
		color: var(--accent);
	}
	header {
		height: 14px;
		display: flex;
		align-items: baseline;
		gap: 8px;
		font-size: 11px;
		line-height: 14px;
	}
	header b {
		font-weight: 600;
		color: var(--secondary);
	}
	header .detail {
		color: var(--tertiary);
	}
	header .clear {
		margin-left: auto;
		color: var(--accent);
	}
	.recent {
		margin-top: 8px;
		display: grid;
		grid-template-columns: repeat(6, 1fr);
		gap: 8px;
	}
	.cell {
		justify-self: center;
		width: 40px;
		height: 40px;
		box-sizing: border-box;
		padding: 3px;
		border-radius: 7px;
	}
	.cell.selected {
		box-shadow: inset 0 0 0 2px var(--accent);
	}
	.ratio {
		margin-top: 8px;
		display: flex;
		align-items: center;
		gap: 12px;
	}
	.sample {
		width: 64px;
		height: 44px;
		display: grid;
		place-items: center;
		border-radius: 8px;
		box-shadow: inset 0 0 0 1px var(--card-line);
		font:
			600 17px/1 -apple-system,
			BlinkMacSystemFont,
			'SF Pro Display',
			sans-serif;
	}
	.verdicts {
		margin-top: 8px;
		display: grid;
		grid-template-columns: auto auto auto;
		justify-content: start;
		column-gap: 16px;
		row-gap: 4px;
		font-size: 11px;
		line-height: 14px;
	}
	.verdicts .size {
		color: var(--secondary);
	}
	.verdict {
		display: flex;
		align-items: center;
		gap: 4px;
		color: var(--secondary);
	}
	.verdict :global(.symbol) {
		color: var(--danger);
	}
	.verdict.passes {
		color: var(--label);
	}
	.verdict.passes :global(.symbol) {
		color: var(--success);
	}
	hr {
		margin: 0 8px;
		border: 0;
		border-top: 1px solid var(--separator);
	}

	/* ConfirmationCard: the popover material, the swatch, what was copied and the exact text. */
	.confirmation {
		position: absolute;
		z-index: 40;
		display: flex;
		align-items: center;
		gap: 12px;
		padding: 8px 12px;
		border-radius: 12px;
		background: rgba(246, 246, 248, 0.86);
		backdrop-filter: blur(30px) saturate(1.8);
		box-shadow:
			0 10px 30px rgba(0, 0, 0, 0.2),
			0 0 0 0.5px rgba(0, 0, 0, 0.14);
		color: rgba(0, 0, 0, 0.85);
		font:
			11px/14px -apple-system,
			BlinkMacSystemFont,
			'SF Pro Text',
			sans-serif;
		text-shadow: none;
		white-space: nowrap;
	}
	:global(.dark) .confirmation {
		background: rgba(44, 44, 48, 0.86);
		box-shadow:
			0 10px 30px rgba(0, 0, 0, 0.45),
			0 0 0 0.5px rgba(255, 255, 255, 0.16);
		color: rgba(255, 255, 255, 0.86);
	}
	.confirmation .swatch {
		width: 32px;
		height: 32px;
		border-radius: 8px;
		box-shadow: inset 0 0 0 1px rgba(0, 0, 0, 0.06);
	}
	.confirmation p {
		margin: 0;
	}
	.what {
		font-weight: 600;
	}
	.confirmation .text {
		margin-top: 2px;
		font:
			10px/13px 'SF Mono',
			ui-monospace,
			Menlo,
			monospace;
		opacity: 0.6;
	}

	/* NSColorSampler's loupe: a round magnifier over the screen's own pixels, the picked one squared off. */
	.loupe {
		position: absolute;
		z-index: 60;
		border-radius: 50%;
		overflow: hidden;
		box-shadow:
			0 0 0 0.5px rgba(0, 0, 0, 0.35),
			0 8px 24px rgba(0, 0, 0, 0.35);
	}
	.loupe svg {
		display: block;
	}
	.rim {
		position: absolute;
		inset: 0;
		border-radius: 50%;
		box-shadow:
			inset 0 0 0 3px rgba(255, 255, 255, 0.92),
			inset 0 0 0 3.5px rgba(0, 0, 0, 0.25);
	}
	.gridline {
		stroke: rgba(128, 128, 128, 0.28);
		stroke-width: 0.6;
	}
	.target {
		fill: none;
		stroke: #fff;
		stroke-width: 1.5;
		outline: 1px solid rgba(0, 0, 0, 0.6);
	}
</style>
