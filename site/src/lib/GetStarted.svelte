<script lang="ts">
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import Keys from './Keys.svelte';
	import OpenAnyway from './OpenAnyway.svelte';
	import { brewLine, curlLine, download, installGuide, type Tool } from './tools';

	let { tool }: { tool: Tool } = $props();

	const release = $derived(page.data.releases?.[tool.slug]);
</script>

<section class="ruled">
	<h2>Get started.</h2>
	<ol>
		<li>
			<b>Download</b>
			<span
				><a href={download(tool, release)}>{tool.asset}</a>, unzip it, and move {tool.name} to Applications.</span
			>
		</li>
		<li>
			<b>Open it</b>
			<span><OpenAnyway {tool} /></span>
		</li>
		{#if tool.permission}
			<li>
				<b>Allow {tool.permission.name}</b>
				<span>{tool.name} asks for it {tool.permission.why}. Flip the switch in System Settings.</span
				>
			</li>
		{/if}
		<li>
			<b>Set it up</b>
			<span><Keys text={tool.firstRun} /></span>
		</li>
	</ol>
	<p class="muted">
		Or, from a terminal, with no Open Anyway step:
		{#if release?.cask}<code>{brewLine(tool)}</code> or{/if}
		<code>{curlLine(tool)}</code>. Every step, with checksums, is in the
		<a href={tool.docs ? resolve(`${tool.slug}/docs/`) : installGuide}
			>{tool.docs ? 'docs' : 'install guide'}</a
		>.
	</p>
</section>

<style>
	ol {
		margin: 16px 0;
		padding: 0;
		list-style: none;
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
		gap: 40px;
		counter-reset: step;
	}
	li {
		counter-increment: step;
		display: flex;
		flex-direction: column;
		gap: 4px;
		font-size: 15px;
		color: var(--text-secondary);
	}
	li::before {
		content: counter(step);
		display: grid;
		place-items: center;
		width: 28px;
		height: 28px;
		margin-bottom: 6px;
		border-radius: 50%;
		background: var(--surface-card);
		color: var(--text-primary);
		font-weight: 600;
	}
	li > b {
		color: var(--text-primary);
		font-size: 17px;
	}
	code {
		word-break: break-all;
	}
	@media (max-width: 760px) {
		ol {
			grid-template-columns: 1fr;
			gap: 20px;
		}
	}
</style>
