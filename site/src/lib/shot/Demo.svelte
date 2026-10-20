<script lang="ts">
	import Film from '../film/Film.svelte';
	import StatusItem from '../mac/StatusItem.svelte';
	import Symbol from '../mac/Symbol.svelte';
	import Window from '../mac/Window.svelte';
	import { statusSlot } from '../mac/geometry';
	import type { SymbolName } from '../mac/symbols';
	import Code from './Code.svelte';
	import Loupe from './Loupe.svelte';
	import Panel from './Panel.svelte';
	import Picture from './Picture.svelte';
	import { film, frameAt, panel, selection, toast } from './demo';
	import { chat, composer, editor, pane, sidebarWidth, thread, typed } from './scene';
	import { caption } from './size';

	let { time, dark = false }: { time: number; dark?: boolean } = $props();

	const frame = $derived(frameAt(time));
	const o = $derived(frame.overlay);

	/** Other apps' menu bar extras, left of Common Shot. */
	const others: SymbolName[] = ['icloud.fill', 'music.note'];
	const files = ['Clipboard.swift', 'FileName.swift', 'Geometry.swift', 'Gesture.swift', 'ImageSize.swift'];
	const hint: [string, boolean][] = [
		['Drag', true],
		[' an area     ', false],
		['Click', true],
		[' a window     ', false],
		['↩', true],
		[' whole screen     ', false],
		['⌥', true],
		[' copy text     ', false],
		['esc', true],
		[' cancel', false]
	];
	const copied = caption(selection.width * 2, selection.height * 2);
	/** The shot as an attachment in the message field, and in the message once it's sent. */
	const chip = { width: 132, height: (132 * selection.height) / selection.width };
	const inMessage = { width: 300, height: (300 * selection.height) / selection.width };
	const grow = $derived(frame.attached * (chip.height + 12));
	// The caret blinks, except in the frozen picture under the overlay, which holds it as it was.
	const blink = (t: number) => Math.floor(t / 530) % 2 === 0;
	const caretOn = $derived(frame.overlay ? blink(film.marks.freeze) : blink(frame.t));
</script>

<Film {frame} {dark} slug="shot" app="Chat" menus={['File', 'Edit', 'View', 'Window', 'Help']}>
	{#snippet extras()}
		<div class="extras">
			{#each others as symbol (symbol)}
				<StatusItem width={statusSlot}><Symbol name={symbol} /></StatusItem>
			{/each}
			<StatusItem width={statusSlot} open={frame.panel > 0.5} label="Common Shot"
				><Symbol name="camera.viewfinder" /></StatusItem
			>
		</div>
	{/snippet}

	<Window title="Geometry.swift" {...editor} front={false}>
		<div class="sidebar" style:width="{sidebarWidth}px" style:height="{editor.height - 52}px">
			<p class="folder">ShotKit</p>
			{#each files as file (file)}
				<p class="file" class:selected={file === 'Geometry.swift'}>{file}</p>
			{/each}
		</div>
		<div class="code" style:left="{pane.x - editor.x}px"><Code /></div>
	</Window>

	<Window title="Chat" {...chat}>
		<div class="chat" style:height="{chat.height - 52}px">
			<div class="thread" style:bottom="{chat.y + chat.height - composer.y + grow + 16}px">
				{#each thread as message (message.time)}
					<div class="message">
						<span class="avatar {message.name.toLowerCase()}">{message.name[0]}</span>
						<div>
							<p class="who"><b>{message.name}</b><span>{message.time}</span></p>
							<p>{message.text}</p>
						</div>
					</div>
				{/each}
				{#if frame.sent > 0}
					<div
						class="message"
						style:opacity={frame.sent}
						style:transform="translateY({(1 - frame.sent) * 12}px)"
					>
						<span class="avatar alex">A</span>
						<div>
							<p class="who"><b>Alex</b><span>9:41 AM</span></p>
							<p>{typed}</p>
							<div class="sent-shot">
								<Picture rect={selection} width={inMessage.width} height={inMessage.height} />
							</div>
						</div>
					</div>
				{/if}
			</div>
			<div
				class="composer"
				style:left="{composer.x - chat.x}px"
				style:top="{composer.y - chat.y - 52 - grow}px"
				style:width="{composer.width}px"
				style:height="{composer.height + grow}px"
			>
				{#if frame.attached > 0}
					<div
						class="chip"
						style:opacity={frame.attached}
						style:transform="scale({0.94 + 0.06 * frame.attached})"
					>
						<Picture rect={selection} width={chip.width} height={chip.height} />
					</div>
				{/if}
				<p class="field">
					{#if frame.sent > 0}<span class="placeholder">Message Maya</span>{:else}{typed}<span
							class="caret"
							class:on={caretOn}
						></span>{/if}
				</p>
			</div>
		</div>
	</Window>

	{#snippet top()}
		{#if o}
			{#if o.hole}
				<div
					class="hole"
					style:left="{o.hole.x}px"
					style:top="{o.hole.y}px"
					style:width="{o.hole.width}px"
					style:height="{o.hole.height}px"
				></div>
			{:else}
				<div class="dim"></div>
			{/if}
			{#if o.pill}
				<p class="material pill" style:left="{o.pill.right}px" style:top="{o.pill.top}px">
					<b>{o.pill.runs[0]}</b><span>{`  ${o.pill.runs[1]}`}</span>
				</p>
			{/if}
			{#if o.hint}
				<p class="material hint">
					{#each hint as [text, key], i (i)}{#if key}<b>{text}</b>{:else}<span>{text}</span
							>{/if}{/each}
				</p>
			{/if}
			<Loupe at={o.loupe} pointer={frame.pointer} {dark} />
			<svg
				class="crosshair"
				style:left="{frame.pointer.x - 12}px"
				style:top="{frame.pointer.y - 12}px"
				width="24"
				height="24"
				viewBox="0 0 24 24"
			>
				<path d="M12 4.5V19.5M4.5 12H19.5" stroke="#fff" stroke-width="3.2" stroke-linecap="round" />
				<path d="M12 4.5V19.5M4.5 12H19.5" stroke="#000" stroke-width="1.5" stroke-linecap="round" />
			</svg>
		{/if}

		{#if frame.flight}
			<div
				class="flight"
				style:left="{frame.flight.x}px"
				style:top="{frame.flight.y}px"
				style:border-radius="{frame.flight.radius}px"
			>
				<Picture rect={selection} width={frame.flight.width} height={frame.flight.height} />
			</div>
		{/if}

		{#if frame.toast.opacity > 0}
			<div
				class="toast"
				style:left="{toast.card.x}px"
				style:top="{toast.card.y}px"
				style:width="{toast.card.width}px"
				style:height="{toast.card.height}px"
				style:opacity={frame.toast.opacity}
				style:transform="translateX({frame.toast.dx}px)"
			>
				<div class="thumb">
					<Picture rect={selection} width={toast.thumb.width} height={toast.thumb.height} />
				</div>
				<p>{copied}</p>
			</div>
		{/if}

		{#if frame.panel > 0}
			<Panel x={panel.x} y={panel.y} opacity={frame.panel} hover={frame.hoverTile} />
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

	/* The editor: a source list, then the code. */
	.sidebar {
		position: absolute;
		left: 0;
		top: 0;
		box-sizing: border-box;
		padding: 10px 10px;
		background: #f4f4f6;
		border-right: 1px solid var(--rule);
	}
	:global(.dark) .sidebar {
		background: #262628;
	}
	.sidebar p {
		margin: 0;
		height: 26px;
		padding: 0 10px;
		display: flex;
		align-items: center;
		border-radius: 7px;
		font-size: 13px;
	}
	.sidebar .folder {
		font-size: 11px;
		font-weight: 600;
		opacity: 0.5;
	}
	.sidebar .selected {
		background: rgba(0, 0, 0, 0.09);
	}
	:global(.dark) .sidebar .selected {
		background: rgba(255, 255, 255, 0.1);
	}
	.code {
		position: absolute;
		top: 0;
	}

	/* The chat: the thread anchored above the message field. */
	.chat {
		position: relative;
		overflow: hidden;
		font-size: 13px;
		line-height: 20px;
	}
	.chat p {
		margin: 0;
	}
	.thread {
		position: absolute;
		left: 20px;
		right: 20px;
		display: flex;
		flex-direction: column;
		gap: 14px;
	}
	.message {
		display: flex;
		gap: 12px;
	}
	.avatar {
		width: 32px;
		height: 32px;
		flex: none;
		display: grid;
		place-items: center;
		border-radius: 50%;
		color: #fff;
		font-weight: 600;
	}
	.avatar.maya {
		background: #ff9f0a;
	}
	.avatar.alex {
		background: #5e5ce6;
	}
	.who {
		display: flex;
		gap: 8px;
		align-items: baseline;
	}
	.who span {
		font-size: 11px;
		opacity: 0.5;
	}
	.sent-shot {
		margin-top: 8px;
		width: fit-content;
		overflow: hidden;
		border-radius: 8px;
		box-shadow: 0 0 0 0.5px var(--rule-strong, rgba(0, 0, 0, 0.18));
	}
	:global(.dark) .sent-shot,
	:global(.dark) .chip {
		--rule-strong: rgba(255, 255, 255, 0.2);
	}
	.composer {
		position: absolute;
		box-sizing: border-box;
		border-radius: 12px;
		box-shadow: inset 0 0 0 1px rgba(0, 0, 0, 0.16);
		background: #fff;
	}
	:global(.dark) .composer {
		background: #28282b;
		box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.2);
	}
	.chip {
		position: absolute;
		left: 12px;
		top: 12px;
		overflow: hidden;
		border-radius: 8px;
		box-shadow: 0 0 0 0.5px var(--rule-strong, rgba(0, 0, 0, 0.18));
		transform-origin: 0 100%;
	}
	.field {
		position: absolute;
		left: 14px;
		right: 14px;
		bottom: 14px;
		height: 20px;
		display: flex;
		align-items: center;
		white-space: pre;
	}
	.placeholder {
		opacity: 0.4;
	}
	.caret {
		width: 1.5px;
		height: 17px;
		margin-left: 1px;
		background: #007aff;
		opacity: 0;
	}
	.caret.on {
		opacity: 1;
	}

	/* The overlay: the frozen screen dimmed, all but what is lit, which has a one-pixel accent edge. */
	.dim {
		position: absolute;
		inset: 0;
		background: rgba(0, 0, 0, 0.3);
	}
	.hole {
		position: absolute;
		box-shadow:
			0 0 0 0.5px #007aff,
			0 0 0 4000px rgba(0, 0, 0, 0.3);
	}
	:global(.dark) .hole {
		box-shadow:
			0 0 0 0.5px #0a84ff,
			0 0 0 4000px rgba(0, 0, 0, 0.3);
	}

	/* MaterialLabel: a 24-point capsule of the blurred picture under the window colour, a hairline,
	   12-point monospaced digits, the key words semibold. */
	.material {
		position: absolute;
		margin: 0;
		box-sizing: border-box;
		height: 24px;
		padding: 0 10px;
		display: flex;
		align-items: center;
		white-space: pre;
		border-radius: 12px;
		background: rgba(236, 236, 236, 0.72);
		backdrop-filter: blur(14px) saturate(1.4);
		box-shadow: inset 0 0 0 0.5px rgba(0, 0, 0, 0.1);
		color: rgba(0, 0, 0, 0.85);
		font:
			12px/1 -apple-system,
			BlinkMacSystemFont,
			sans-serif;
		font-variant-numeric: tabular-nums;
		text-shadow: none;
		z-index: 20;
	}
	.material b {
		font-weight: 600;
	}
	.material span {
		color: rgba(0, 0, 0, 0.5);
	}
	:global(.dark) .material {
		background: rgba(36, 36, 38, 0.72);
		box-shadow: inset 0 0 0 0.5px rgba(255, 255, 255, 0.12);
		color: rgba(255, 255, 255, 0.88);
	}
	:global(.dark) .material span {
		color: rgba(255, 255, 255, 0.55);
	}
	.pill {
		transform: translateX(-100%);
	}
	.hint {
		left: 50%;
		bottom: 24px;
		transform: translateX(-50%);
	}
	.crosshair {
		position: absolute;
		z-index: 50;
	}

	/* The picture on its way to the corner, then the preview it lands in. */
	.flight {
		position: absolute;
		z-index: 25;
		overflow: hidden;
		box-shadow:
			0 10px 30px rgba(0, 0, 0, 0.3),
			0 0 0 0.5px rgba(0, 0, 0, 0.2);
	}
	.toast {
		position: absolute;
		z-index: 24;
		box-sizing: border-box;
		padding: 12px;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 8px;
		border-radius: 12px;
		background: rgba(238, 238, 240, 0.8);
		backdrop-filter: blur(30px) saturate(1.6);
		box-shadow:
			0 14px 40px rgba(0, 0, 0, 0.25),
			0 0 0 0.5px rgba(0, 0, 0, 0.15);
		color: rgba(0, 0, 0, 0.88);
		text-shadow: none;
	}
	:global(.dark) .toast {
		background: rgba(46, 46, 50, 0.8);
		box-shadow:
			0 14px 40px rgba(0, 0, 0, 0.5),
			0 0 0 0.5px rgba(255, 255, 255, 0.16);
		color: rgba(255, 255, 255, 0.92);
	}
	.toast .thumb {
		overflow: hidden;
		border-radius: 8px;
	}
	.toast p {
		margin: 0;
		height: 14px;
		font-size: 11px;
		line-height: 14px;
		font-weight: 500;
		white-space: nowrap;
	}

	/* The editor's code pane (Code.svelte), in the editor's default colours. */
	:global(.shot-code) {
		position: absolute;
		left: 0;
		top: 0;
		overflow: hidden;
		background: #fff;
		color: #1d1d1f;
		font:
			12px / 20px ui-monospace,
			'SF Mono',
			Menlo,
			monospace;
		letter-spacing: 0;
		white-space: pre;
		--keyword: #9b2393;
		--type: #3900a0;
		--number: #1c00cf;
		--comment: #5d6c79;
		--gutter: #a3a3aa;
	}
	:global(.dark .shot-code) {
		background: #1f1f24;
		color: #dfdfe0;
		--keyword: #fc5fa3;
		--type: #d0a8ff;
		--number: #d0bf69;
		--comment: #7f8c98;
		--gutter: #66666e;
	}
	:global(.shot-code .gutter),
	:global(.shot-code .line) {
		position: absolute;
	}
	:global(.shot-code .gutter) {
		left: 0;
		width: 36px;
		text-align: right;
		color: var(--gutter);
		font-variant-numeric: tabular-nums;
	}
	:global(.shot-code .keyword) {
		color: var(--keyword);
		font-weight: 600;
	}
	:global(.shot-code .type) {
		color: var(--type);
	}
	:global(.shot-code .number) {
		color: var(--number);
	}
	:global(.shot-code .comment) {
		color: var(--comment);
	}

	/* The history panel (Panel.svelte). Its colours live here with the rest of the scene's. */
	/* The menu's own material, the system menu's 12-point corner and a hairline. */
	:global(.shot-panel) {
		position: absolute;
		z-index: 40;
		box-sizing: border-box;
		width: 336px;
		padding: 8px;
		display: flex;
		flex-direction: column;
		gap: 8px;
		border-radius: 12px;
		background: rgba(242, 242, 244, 0.82);
		backdrop-filter: blur(40px) saturate(1.8);
		box-shadow:
			inset 0 0 0 0.5px rgba(0, 0, 0, 0.12),
			0 18px 50px rgba(0, 0, 0, 0.22),
			0 0 0 0.5px rgba(0, 0, 0, 0.1);
		color: rgba(0, 0, 0, 0.88);
		text-shadow: none;
		font:
			13px/16px -apple-system,
			BlinkMacSystemFont,
			'SF Pro Text',
			sans-serif;
		--secondary: rgba(0, 0, 0, 0.5);
		--tertiary: rgba(0, 0, 0, 0.26);
		--card: rgba(0, 0, 0, 0.047);
		--card-edge: rgba(0, 0, 0, 0.059);
		--media: #e4e4ea;
		--accent: #007aff;
	}
	:global(.dark .shot-panel) {
		background: rgba(40, 40, 44, 0.8);
		box-shadow:
			inset 0 0 0 0.5px rgba(255, 255, 255, 0.14),
			0 18px 50px rgba(0, 0, 0, 0.5),
			0 0 0 0.5px rgba(0, 0, 0, 0.6);
		color: rgba(255, 255, 255, 0.92);
		--secondary: rgba(255, 255, 255, 0.55);
		--tertiary: rgba(255, 255, 255, 0.28);
		--card: rgba(255, 255, 255, 0.047);
		--card-edge: rgba(255, 255, 255, 0.059);
		--media: #1c1c1e;
		--accent: #0a84ff;
	}

	/* MenuRow: a 16-point symbol column, 8 points, the title, the shortcut in the secondary colour. */
	:global(.shot-panel .row) {
		height: 22px;
		padding: 0 8px;
		display: flex;
		align-items: center;
		gap: 8px;
	}
	:global(.shot-panel .icon) {
		width: 16px;
		display: flex;
		justify-content: center;
	}
	:global(.shot-panel .row > span:not(.icon)) {
		flex: 1;
	}
	:global(.shot-panel .row kbd) {
		font: inherit;
		color: var(--secondary);
	}
	:global(.shot-panel hr) {
		margin: 0 8px;
		border: 0;
		border-top: 0.5px solid var(--card-edge);
		border-top-color: color-mix(in srgb, currentColor 18%, transparent);
	}

	/* Card and SectionHeader. */
	:global(.shot-panel .group) {
		padding: 12px;
		display: flex;
		flex-direction: column;
		gap: 8px;
		border-radius: 12px;
		background: var(--card);
		box-shadow: inset 0 0 0 0.5px var(--card-edge);
	}
	:global(.shot-panel header) {
		display: flex;
		align-items: baseline;
		gap: 8px;
		font-size: 11px;
		line-height: 14px;
	}
	:global(.shot-panel header b) {
		font-weight: 600;
		color: var(--secondary);
	}
	:global(.shot-panel header span) {
		color: var(--tertiary);
	}
	:global(.shot-panel .grid) {
		display: grid;
		grid-template-columns: 1fr 1fr;
		column-gap: 8px;
		row-gap: 12px;
	}

	/* ThumbnailTile: the picture whole, letterboxed in the media surface, then its caption. */
	:global(.shot-panel .tile) {
		margin: 0;
		display: flex;
		flex-direction: column;
		gap: 4px;
	}
	:global(.shot-panel .media) {
		position: relative;
		margin: 2px;
		aspect-ratio: 16 / 10;
		display: grid;
		place-items: center;
		overflow: hidden;
		border-radius: 8px;
		background: var(--media);
		box-shadow: inset 0 0 0 1px var(--card-edge);
	}
	:global(.shot-panel .tile.hover .media::after) {
		content: '';
		position: absolute;
		inset: 0;
		background: currentColor;
		opacity: 0.06;
	}
	:global(.shot-panel figcaption) {
		padding: 0 2px;
		display: flex;
		flex-direction: column;
	}
	:global(.shot-panel .title) {
		display: flex;
		align-items: center;
		gap: 4px;
		font-size: 11px;
		line-height: 14px;
		font-weight: 600;
	}
	:global(.shot-panel .sub) {
		font-size: 10px;
		line-height: 13px;
		font-variant-numeric: tabular-nums;
		color: var(--secondary);
	}

	/* App icons, small: an editor, a terminal, a chat. */
	:global(.shot-panel .app) {
		width: 14px;
		height: 14px;
		border-radius: 3.5px;
		flex: none;
		box-shadow: inset 0 0 0 0.5px rgba(0, 0, 0, 0.15);
	}
	:global(.shot-panel .app.editor) {
		background: linear-gradient(160deg, #5ac8fa, #0a60ff);
	}
	:global(.shot-panel .app.terminal) {
		background: linear-gradient(160deg, #3a3a3c, #111);
	}
	:global(.shot-panel .app.chat) {
		background: linear-gradient(160deg, #6ee08a, #1fae4b);
	}

	/* Miniatures of the earlier shots. */
	:global(.shot-panel .term) {
		align-self: stretch;
		justify-self: stretch;
		padding: 8px 9px;
		display: flex;
		flex-direction: column;
		gap: 4px;
		background: #1e1e1e;
	}
	:global(.shot-panel .log .term) {
		margin: 22px 0;
		justify-content: center;
	}
	:global(.shot-panel .term i) {
		height: 3px;
		max-width: 100%;
		border-radius: 1px;
		background: rgba(255, 255, 255, 0.55);
	}
	:global(.shot-panel .mini-chat) {
		width: 56px;
		height: 54px;
		padding: 5px;
		box-sizing: border-box;
		display: flex;
		flex-direction: column;
		gap: 4px;
		border-radius: 3px;
		background: #fff;
	}
	:global(.dark .shot-panel .mini-chat) {
		background: #2a2a2c;
	}
	:global(.shot-panel .mini-chat .bubble) {
		width: 70%;
		height: 7px;
		border-radius: 3px;
		background: rgba(128, 128, 128, 0.35);
	}
	:global(.shot-panel .mini-chat .mine) {
		align-self: flex-end;
		background: rgba(10, 132, 255, 0.6);
	}
	:global(.shot-panel .mini-chat .field) {
		margin-top: auto;
		height: 7px;
		border-radius: 3px;
		box-shadow: inset 0 0 0 0.5px rgba(128, 128, 128, 0.6);
	}
	:global(.shot-panel .mini-screen) {
		position: absolute;
		inset: 0;
		background:
			radial-gradient(70% 60% at 18% 22%, rgba(140, 190, 255, 0.85), transparent 70%),
			radial-gradient(70% 60% at 70% 95%, rgba(255, 196, 160, 0.85), transparent 70%),
			linear-gradient(170deg, #dfe9ff, #f3eaf5 55%, #fde3d2);
	}
	:global(.dark .shot-panel .mini-screen) {
		background:
			radial-gradient(60% 55% at 20% 18%, rgba(46, 92, 220, 0.75), transparent 70%),
			linear-gradient(170deg, #0b1230, #0d0d1c 55%, #0a1a24);
	}
	:global(.shot-panel .mini-screen i) {
		position: absolute;
		border-radius: 3px;
		background: #fff;
		box-shadow: 0 2px 6px rgba(0, 0, 0, 0.25);
	}
	:global(.dark .shot-panel .mini-screen i) {
		background: #1e1e20;
	}
	:global(.shot-panel .mini-screen .w1) {
		left: 10%;
		top: 14%;
		width: 50%;
		height: 58%;
	}
	:global(.shot-panel .mini-screen .w2) {
		left: 52%;
		top: 30%;
		width: 40%;
		height: 56%;
	}
</style>
