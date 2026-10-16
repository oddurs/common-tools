<script lang="ts">
	import Cursor from '../Cursor.svelte';
	import Overlay from '../mac/Overlay.svelte';
	import Screen from '../mac/Screen.svelte';
	import Stage from '../mac/Stage.svelte';
	import Symbol from '../mac/Symbol.svelte';
	import Window from '../mac/Window.svelte';
	import { tool } from '../tools';
	import { frameAt, metrics } from './demo';

	let { time, dark = false }: { time: number; dark?: boolean } = $props();

	const frame = $derived(frameAt(time));
</script>

<Stage {dark} opacity={frame.opacity}>
	<Screen
		{dark}
		camera={frame.camera}
		app="Notes"
		menus={['File', 'Edit', 'Format', 'View', 'Window', 'Help']}
	>
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
			<span class="icon" style:left="{frame.chevron.x}px" style:width="{metrics.chevron}px">
				<Symbol name={frame.chevron.open ? 'chevron.compact.right' : 'chevron.compact.left'} />
			</span>
		{/snippet}

		<Window title="Notes" x={330} y={300} width={720} height={420}>
			<div class="note">
				<h2>Tidy up</h2>
				<p>Fewer icons, same apps.</p>
			</div>
		</Window>

		{#snippet top()}
			<Cursor x={frame.cursor.x} y={frame.cursor.y} pulse={frame.pulse} />
		{/snippet}
	</Screen>

	<Overlay caption={frame.caption} keys={frame.keys} end={frame.end} tool={tool('bar')} />
</Stage>

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
