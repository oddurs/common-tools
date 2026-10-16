<script lang="ts">
	import Film from '../film/Film.svelte';
	import Symbol from '../mac/Symbol.svelte';
	import Window from '../mac/Window.svelte';
	import { extrasRight, screen, statusSlot } from '../mac/geometry';
	import type { SymbolName } from '../mac/symbols';
	import { frameAt, windows, type WindowID, type Word } from './demo';

	let { time, dark = false }: { time: number; dark?: boolean } = $props();

	const frame = $derived(frameAt(time));
	const titles: Record<WindowID, string> = { notes: 'Notes', chat: 'Chat' };
	// Entrances are drawn from the scene clock, not CSS animations, so recorded frames match it.
	const flagScale = $derived(1 + 0.45 * Math.max(0, 1 - frame.sinceFlag / 450));
	const bubbleIn = $derived(Math.min(1, frame.sinceBubble / 140));
	const order: WindowID[] = $derived(frame.front === 'notes' ? ['chat', 'notes'] : ['notes', 'chat']);

	/** Other apps' menu bar extras, left of Common Keys. */
	const others: SymbolName[] = ['icloud.fill', 'music.note'];

	function lines(words: Word[]): { word: Word; index: number }[][] {
		const result: { word: Word; index: number }[][] = [[]];
		words.forEach((word, index) => {
			if (word.newline) result.push([]);
			result[result.length - 1].push({ word, index });
		});
		return result;
	}
</script>

<Film
	frame={{ ...frame, keys: [...frame.keys] }}
	{dark}
	slug="keys"
	app={titles[frame.front]}
	menus={['File', 'Edit', 'Format', 'View', 'Window', 'Help']}
>
	{#snippet extras()}
		<div class="extras" style:right="{screen.width - extrasRight}px">
			{#each others as symbol (symbol)}
				<span class="slot" style:width="{statusSlot}px"><Symbol name={symbol} /></span>
			{/each}
			<span class="slot flag" style:width="{statusSlot + 4}px" aria-label="Current keyboard"
				><span style:transform="scale({flagScale})">{frame.flag}</span></span
			>
		</div>
	{/snippet}

	{#each order as id (id)}
		{@const front = id === frame.front}
		<Window title={titles[id]} {...windows[id]} {front}>
			<div class="text">
				{#each lines(frame.windows[id]) as line, lineIndex (lineIndex)}
					<p>
						{#each line as { word, index }, position (index)}
							{#if position > 0}{' '}{/if}<span class="word" class:fixed={!!word.fixed}
								>{word.text}{#if frame.bubble?.window === id && frame.bubble.index === index && word.fixed}
									<span
										class="bubble"
										style:opacity={bubbleIn}
										style:transform="translateY({(1 - bubbleIn) * -3}px)"
									>
										<span>{word.fixed.flag}</span>
										<b>{word.fixed.replacement}</b>
										<s>{word.fixed.original}</s>
										<kbd>⌘Z</kbd>
									</span>
								{/if}</span
							>{#if front && index === frame.windows[id].length - 1}<span
									class="caret"
									class:on={frame.caretOn}
								></span>{/if}
						{/each}
					</p>
				{/each}
			</div>
		</Window>
	{/each}
</Film>

<style>
	.extras {
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
	.flag span {
		display: inline-block;
		font-size: 16px;
		line-height: 1;
	}

	.text {
		padding: 28px 34px;
		font:
			26px/1.5 -apple-system,
			BlinkMacSystemFont,
			'SF Pro Text',
			sans-serif;
		letter-spacing: -0.01em;
	}
	.text p {
		margin: 0;
		min-height: 1.5em;
	}
	.word {
		position: relative;
		border-radius: 4px;
	}
	.word.fixed {
		background: rgba(10, 132, 255, 0.1);
	}
	:global(.dark) .word.fixed {
		background: rgba(10, 132, 255, 0.24);
	}
	.caret {
		display: inline-block;
		width: 2px;
		height: 1.1em;
		margin-left: 1px;
		vertical-align: -0.18em;
		background: #0a84ff;
		opacity: 0;
	}
	.caret.on {
		opacity: 1;
	}

	/* The app's own fix bubble: flag, the fixed word, what it was, and how to take it back. */
	.bubble {
		position: absolute;
		left: -8px;
		top: calc(100% + 6px);
		display: flex;
		align-items: center;
		gap: 8px;
		padding: 5px 12px;
		border-radius: 999px;
		white-space: nowrap;
		font-size: 17px;
		line-height: 1.2;
		background: rgba(250, 250, 252, 0.86);
		backdrop-filter: blur(24px) saturate(1.8);
		box-shadow:
			inset 0 0.5px 0 rgba(255, 255, 255, 0.9),
			0 6px 18px rgba(0, 0, 0, 0.16),
			0 0 0 0.5px rgba(0, 0, 0, 0.12);
		color: #1d1d1f;
		z-index: 2;
	}
	:global(.dark) .bubble {
		background: rgba(50, 50, 56, 0.86);
		color: #f5f5f7;
		box-shadow:
			inset 0 0.5px 0 rgba(255, 255, 255, 0.2),
			0 6px 18px rgba(0, 0, 0, 0.4),
			0 0 0 0.5px rgba(255, 255, 255, 0.14);
	}
	.bubble b {
		font-weight: 600;
	}
	.bubble s {
		color: #8e8e93;
	}
	.bubble kbd {
		font:
			600 12px/1 -apple-system,
			sans-serif;
		color: #aeaeb2;
	}
</style>
