<script lang="ts">
	import Film from '../film/Film.svelte';
	import StatusItem from '../mac/StatusItem.svelte';
	import Symbol from '../mac/Symbol.svelte';
	import Window from '../mac/Window.svelte';
	import { statusSlot } from '../mac/geometry';
	import type { SymbolName } from '../mac/symbols';
	import { frameAt, windows, type WindowID, type Word } from './demo';

	let { time, dark = false }: { time: number; dark?: boolean } = $props();

	const frame = $derived(frameAt(time));
	const titles: Record<WindowID, string> = { notes: 'Notes', chat: 'Chat' };
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
		<div class="extras">
			{#each others as symbol (symbol)}
				<StatusItem width={statusSlot}><Symbol name={symbol} /></StatusItem>
			{/each}
			<StatusItem label="Current keyboard"><span class="flag">{frame.flag}</span></StatusItem>
		</div>
	{/snippet}

	{#each order as id (id)}
		{@const front = id === frame.front}
		<Window title={titles[id]} {...windows[id]} {front}>
			<div class="text">
				{#each lines(frame.windows[id]) as line, lineIndex (lineIndex)}
					<p>
						{#each line as { word, index }, position (index)}
							{#if position > 0}{' '}{/if}<span class="word"
								>{word.text}{#if frame.bubble?.window === id && frame.bubble.index === index && word.fixed}
									<!-- Its fade is drawn from the scene clock, not a CSS animation, so recorded frames match. -->
									<span class="bubble" style:opacity={frame.bubble.opacity}>
										<span>{word.fixed.flag}</span>
										<b>{word.fixed.replacement}</b>
										<s>{word.fixed.original}</s>
										<span class="hint">⌘Z</span>
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
		right: 0;
		height: 100%;
		display: flex;
		align-items: center;
	}
	/* The flag drawn at 15 points, as `StatusMenu.flagImage` draws it. */
	.flag {
		display: inline-block;
		font-size: 15px;
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

	/*
	 * The app's own fix bubble (`Bubble.swift`): callout text in a capsule of regular material with a
	 * hairline and no shadow, a little under the word and just left of it. Its metrics are the app's
	 * scaled with the text, which the film draws at twice a text field's size.
	 */
	.bubble {
		position: absolute;
		left: -7px;
		top: calc(100% + 10px);
		display: flex;
		align-items: center;
		gap: 15px;
		padding: 7px 15px;
		border-radius: 999px;
		white-space: nowrap;
		font-size: 22px;
		line-height: 1.2;
		background: rgba(238, 238, 242, 0.88);
		backdrop-filter: blur(24px) saturate(1.8);
		box-shadow: inset 0 0 0 0.5px rgba(0, 0, 0, 0.06);
		color: #1d1d1f;
		z-index: 2;
	}
	:global(.dark) .bubble {
		background: rgba(58, 58, 62, 0.86);
		color: #f5f5f7;
		box-shadow: inset 0 0 0 0.5px rgba(255, 255, 255, 0.06);
	}
	.bubble b {
		font-weight: 500;
	}
	.bubble s {
		color: rgba(60, 60, 67, 0.6);
	}
	:global(.dark) .bubble s {
		color: rgba(235, 235, 245, 0.6);
	}
	.bubble .hint {
		font:
			500 18px/1 -apple-system,
			sans-serif;
		color: rgba(60, 60, 67, 0.3);
	}
	:global(.dark) .bubble .hint {
		color: rgba(235, 235, 245, 0.3);
	}
</style>
