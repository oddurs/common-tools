<script lang="ts">
	// SettingsView, under the editor: the preview of every glyph, the Glyphs list with Add Glyph,
	// General, and the start of the Common Tools section. Styles live in Demo.svelte, under `.form`.
	import { asset } from '$app/paths';
	import Symbol from '../mac/Symbol.svelte';
	import Glyph from './Glyph.svelte';
	import Preview from './Preview.svelte';
	import type { Source } from './demo';

	let { rows }: { rows: { name: string; source: Source; summary: string }[] } = $props();

	const family = [
		{ slug: 'stats', name: 'Common Stats', summary: 'System stats in the menu bar' },
		{ slug: 'keys', name: 'Common Keys', summary: 'Fixes words typed on the wrong keyboard' },
		{ slug: 'bar', name: 'Common Bar', summary: 'Hides the menu bar icons you rarely use' },
		{ slug: 'glyph', name: 'Common Glyph', summary: 'Your own image in the menu bar' },
		{
			slug: 'command',
			name: 'Common Command',
			summary: 'Opens apps, files, and settings from the keyboard'
		}
	] as const;
</script>

<div class="f-settings">
	<div class="f-block" style:margin-top="20px"><Preview glyphs={rows.map((row) => row.source)} /></div>

	<h3 class="f-header" style:margin-top="34px">Glyphs</h3>
	<div class="f-section">
		{#each rows as row (row.name)}
			<div class="f-row listed">
				<span class="f-tile"><Glyph source={row.source} fit={32 * 0.64} /></span>
				<span class="f-grow f-two"><span>{row.name}</span><small>{row.summary}</small></span>
				<i class="f-switch small on" class:disabled={rows.length === 1}></i>
				<span class="f-chevron"><Symbol name="chevron.right" /></span>
			</div>
		{/each}
		<div class="f-row add"><span class="f-btn">Add Glyph</span></div>
	</div>
	<p class="f-foot">Click a glyph to edit it. Hold ⌘ and drag a glyph in the menu bar to move it.</p>

	<h3 class="f-header" style:margin-top="30px">General</h3>
	<div class="f-section">
		<div class="f-row short"><span class="f-grow">Open at login</span><i class="f-switch"></i></div>
		<div class="f-row short">
			<span class="f-grow">Check for updates daily</span><i class="f-switch"></i>
		</div>
	</div>
	<p class="f-foot">Starts when you log in.</p>

	<h3 class="f-header" style:margin-top="30px">Common Tools</h3>
	<div class="f-section">
		{#each family as tool (tool.slug)}
			<div class="f-row listed">
				<img src={asset(`${tool.slug}/icon.png`)} alt="" width="32" height="32" />
				<span class="f-grow f-two"><span>{tool.name}</span><small>{tool.summary}</small></span>
				{#if tool.slug === 'glyph'}<span class="f-secondary">This app</span>{:else}<span class="f-btn"
						>Get…</span
					>{/if}
			</div>
		{/each}
	</div>
</div>
