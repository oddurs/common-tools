<script lang="ts">
	import { resolve } from '$app/paths';
	import type { Snippet } from 'svelte';
	import { download, type Tool } from './tools';

	let {
		tool,
		sections,
		children
	}: { tool: Tool; sections: [id: string, title: string][]; children: Snippet } = $props();
</script>

<svelte:head>
	<title>{tool.name} documentation</title>
	<meta name="description" content="How to install and use {tool.name}. {tool.summary}" />
</svelte:head>

<main>
	<p class="crumb"><a href={resolve(`${tool.slug}/`)}>{tool.name}</a> › Documentation</p>
	<h1>{tool.name} documentation</h1>
	<div class="layout">
		<nav aria-label="On this page">
			<ul>
				{#each sections as [id, title] (id)}
					<li><a href="#{id}">{title}</a></li>
				{/each}
			</ul>
			<a class="button" href={download(tool)}>Download</a>
		</nav>
		<article>{@render children()}</article>
	</div>
</main>

<style>
	.crumb {
		margin: 0;
		font-size: 14px;
		color: var(--secondary);
	}
	h1 {
		font-size: 40px;
	}
	.layout {
		display: grid;
		grid-template-columns: 200px 1fr;
		gap: 48px;
		margin-top: 40px;
	}
	nav {
		position: sticky;
		top: 72px;
		align-self: start;
		font-size: 14px;
	}
	nav ul {
		margin: 0 0 20px;
		padding: 0;
		list-style: none;
	}
	nav li {
		margin: 0 0 8px;
	}
	nav li a {
		color: var(--secondary);
	}
	nav li a:hover {
		color: var(--text);
		text-decoration: none;
	}
	nav .button {
		padding: 7px 16px;
		font-size: 14px;
	}
	article {
		min-width: 0;
		max-width: 680px;
	}
	article :global(h2) {
		margin: 48px 0 10px;
		font-size: 26px;
		scroll-margin-top: 72px;
	}
	article :global(h2:first-child) {
		margin-top: 0;
	}
	article :global(h3) {
		margin: 28px 0 6px;
		font-size: 18px;
		font-weight: 600;
	}
	article :global(p),
	article :global(li) {
		font-size: 16px;
	}
	article :global(p) {
		margin: 0 0 12px;
	}
	article :global(ol),
	article :global(ul) {
		margin: 0 0 12px;
		padding-left: 22px;
	}
	article :global(li) {
		margin-bottom: 6px;
	}
	article :global(pre) {
		margin: 8px 0 16px;
	}
	article :global(table) {
		margin: 8px 0 16px;
	}
	article :global(img) {
		display: block;
		max-width: 100%;
		height: auto;
		margin: 8px 0 16px;
	}
	article :global(.note) {
		padding: 14px 16px;
		border-radius: 12px;
		background: var(--panel);
		font-size: 15px;
	}
	@media (max-width: 760px) {
		.layout {
			grid-template-columns: 1fr;
			gap: 24px;
			margin-top: 24px;
		}
		nav {
			position: static;
		}
	}
</style>
