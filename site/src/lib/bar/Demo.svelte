<script lang="ts">
	import Film from '../film/Film.svelte';
	import Symbol from '../mac/Symbol.svelte';
	import Window from '../mac/Window.svelte';
	import { frameAt, metrics } from './demo';

	let { time, dark = false }: { time: number; dark?: boolean } = $props();

	const frame = $derived(frameAt(time));
</script>

<Film {frame} {dark} slug="bar" app="Notes" menus={['File', 'Edit', 'Format', 'View', 'Window', 'Help']}>
	{#snippet extras()}
		{#each frame.icons as icon (icon.symbol)}
			<span
				class="icon"
				class:lifted={icon.lifted}
				style:left="{icon.x}px"
				style:width="{metrics.slot}px"
				style:opacity={icon.opacity}><Symbol name={icon.symbol} /></span
			>
		{/each}
		{#if frame.line.opacity > 0}
			<!-- Glyphs.line: a 1 × 12 pt hairline in its 4 pt marker item. -->
			<span
				class="icon"
				style:left="{frame.line.x}px"
				style:width="{metrics.marker}px"
				style:opacity={frame.line.opacity}><i class="line"></i></span
			>
		{/if}
		<span class="icon" style:left="{frame.chevron.x}px" style:width="{metrics.chevron}px">
			<!-- Glyphs.swift: a 6 × 9 pt canvas, right-angled arms 3.5 pt from a tip inset 1 pt, 1.25 pt stroke. -->
			<svg width="6" height="9" viewBox="0 0 6 9" aria-hidden="true">
				<path
					d={frame.chevron.open ? 'M1.5 1 L5 4.5 L1.5 8' : 'M4.5 1 L1 4.5 L4.5 8'}
					fill="none"
					stroke="currentColor"
					stroke-width="1.25"
					stroke-linejoin="miter"
					stroke-linecap="butt"
				/>
			</svg>
		</span>
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
	.icon.lifted {
		top: 3px;
		filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.35));
	}
	.line {
		width: 1px;
		height: 12px;
		background: currentColor;
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
