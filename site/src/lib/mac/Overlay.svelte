<script lang="ts">
	// What sits on top of the video rather than on the screen: the caption, the keys being held,
	// and the closing card with the app's name.
	import { asset } from '$app/paths';
	import Symbol from './Symbol.svelte';
	import type { SymbolName } from './symbols';
	import type { AppSlug } from '../tools';

	let {
		caption,
		keys = [],
		end = 0,
		app
	}: {
		caption: string;
		keys?: (SymbolName | string)[];
		end?: number;
		app: { name: string; icon: `${AppSlug}/icon.png` };
	} = $props();

	const symbolic = (key: string): key is SymbolName => key === 'command' || key === 'option';
</script>

{#if keys.length}
	<div class="keys overlay" aria-label="Keys pressed">
		{#each keys as key, i (i)}
			<kbd
				>{#if symbolic(key)}<Symbol name={key} />{:else}{key}{/if}</kbd
			>
		{/each}
	</div>
{/if}

{#if caption && end < 1}
	<p class="caption overlay" style:opacity={1 - end}>{caption}</p>
{/if}

{#if end > 0}
	<div class="end overlay" style:opacity={end}>
		<img
			src={asset(app.icon)}
			alt=""
			width="168"
			height="168"
			style:transform="scale({0.92 + 0.08 * end})"
		/>
		<h1>{app.name}</h1>
		<p>Free for Mac · oddurs.github.io/common-tools</p>
	</div>
{/if}

<style>
	.keys {
		position: absolute;
		left: 40px;
		bottom: 40px;
		display: flex;
		gap: 8px;
		z-index: 60;
	}
	kbd {
		min-width: 50px;
		height: 50px;
		padding: 0 12px;
		display: grid;
		place-items: center;
		border-radius: 12px;
		background: rgba(255, 255, 255, 0.72);
		backdrop-filter: blur(20px) saturate(1.6);
		box-shadow:
			inset 0 1px 0 rgba(255, 255, 255, 0.9),
			0 3px 0 rgba(0, 0, 0, 0.14),
			0 8px 24px rgba(0, 0, 0, 0.18),
			0 0 0 0.5px rgba(0, 0, 0, 0.18);
		font:
			500 22px/1 -apple-system,
			BlinkMacSystemFont,
			sans-serif;
		color: #1d1d1f;
	}
	:global(.dark) kbd {
		background: rgba(60, 60, 64, 0.72);
		color: #f5f5f7;
		box-shadow:
			inset 0 1px 0 rgba(255, 255, 255, 0.18),
			0 3px 0 rgba(0, 0, 0, 0.4),
			0 8px 24px rgba(0, 0, 0, 0.4),
			0 0 0 0.5px rgba(255, 255, 255, 0.14);
	}

	/* A Liquid Glass capsule. */
	.caption {
		position: absolute;
		left: 50%;
		bottom: 40px;
		transform: translateX(-50%);
		margin: 0;
		padding: 12px 24px;
		border-radius: 999px;
		background: rgba(255, 255, 255, 0.55);
		backdrop-filter: blur(24px) saturate(1.8);
		box-shadow:
			inset 0 1px 0 rgba(255, 255, 255, 0.85),
			inset 0 -1px 0 rgba(255, 255, 255, 0.3),
			0 10px 30px rgba(0, 0, 0, 0.16),
			0 0 0 0.5px rgba(0, 0, 0, 0.1);
		color: #1d1d1f;
		font:
			600 21px/1.2 -apple-system,
			BlinkMacSystemFont,
			'SF Pro Display',
			sans-serif;
		letter-spacing: -0.01em;
		white-space: nowrap;
		z-index: 60;
	}
	:global(.dark) .caption {
		background: rgba(40, 40, 46, 0.55);
		color: #f5f5f7;
		box-shadow:
			inset 0 1px 0 rgba(255, 255, 255, 0.22),
			0 10px 30px rgba(0, 0, 0, 0.4),
			0 0 0 0.5px rgba(255, 255, 255, 0.14);
	}

	.end {
		position: absolute;
		inset: 0;
		z-index: 70;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		background: rgba(250, 250, 252, 0.55);
		backdrop-filter: blur(40px) saturate(1.4);
		color: #1d1d1f;
	}
	:global(.dark) .end {
		background: rgba(10, 10, 14, 0.55);
		color: #f5f5f7;
	}
	.end h1 {
		margin: 18px 0 0;
		font:
			700 56px/1.05 -apple-system,
			BlinkMacSystemFont,
			'SF Pro Display',
			sans-serif;
		letter-spacing: -0.02em;
	}
	.end p {
		margin: 12px 0 0;
		font:
			500 22px/1.3 -apple-system,
			BlinkMacSystemFont,
			sans-serif;
		opacity: 0.6;
	}
</style>
