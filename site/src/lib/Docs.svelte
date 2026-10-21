<script lang="ts">
	import { resolve } from '$app/paths';
	import type { Snippet } from 'svelte';
	import Meta from './Meta.svelte';
	import { docsDescription } from './seo';
	import { page } from '$app/state';
	import { download, type Tool } from './tools';

	let {
		tool,
		sections,
		children
	}: { tool: Tool; sections: [id: string, title: string][]; children: Snippet } = $props();

	const release = $derived(page.data.releases?.[tool.slug]);
</script>

<Meta title="{tool.name} documentation" description={docsDescription(tool)} path="{tool.slug}/docs/" {tool} />

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
			<a class="button" href={download(tool, release)}>Download</a>
		</nav>
		<article>{@render children()}</article>
	</div>
</main>

<style>
	.crumb {
		margin: 0;
		font: var(--type-footnote);
		letter-spacing: var(--type-footnote-tracking);
		color: var(--text-secondary);
	}
	h1 {
		font: var(--type-title);
		letter-spacing: var(--type-title-tracking);
	}
	.layout {
		display: grid;
		grid-template-columns: 200px 1fr;
		gap: var(--space-xxl);
		margin-top: var(--space-xxl);
	}
	nav {
		position: sticky;
		top: var(--space-section);
		align-self: start;
		font: var(--type-footnote);
		letter-spacing: var(--type-footnote-tracking);
	}
	nav ul {
		margin: 0 0 var(--space-lg);
		padding: 0;
		list-style: none;
	}
	nav li {
		margin: 0 0 var(--space-xs);
	}
	nav li a {
		color: var(--text-secondary);
	}
	nav li a:hover {
		color: var(--text-primary);
		text-decoration: none;
	}
	nav .button {
		padding: var(--space-xs) var(--space-md);
	}
	article {
		min-width: 0;
		max-width: var(--layout-prose);
	}
	article :global(h2) {
		margin: var(--space-xxl) 0 var(--space-xs);
		font: var(--type-title2);
		letter-spacing: var(--type-title2-tracking);
		scroll-margin-top: var(--space-section);
	}
	article :global(h2:first-child) {
		margin-top: 0;
	}
	article :global(h3) {
		margin: var(--space-lg) 0 var(--space-xxs);
		font: var(--type-body);
		font-weight: var(--weight-semibold);
		letter-spacing: var(--type-body-tracking);
	}
	article :global(p),
	article :global(li) {
		font-size: 16px;
	}
	article :global(p) {
		margin: 0 0 var(--space-sm);
	}
	article :global(ol),
	article :global(ul) {
		margin: 0 0 var(--space-sm);
		padding-left: var(--space-lg);
	}
	article :global(li) {
		margin-bottom: var(--space-xxs);
	}
	article :global(pre),
	article :global(table) {
		margin: var(--space-xs) 0 var(--space-md);
	}
	article :global(img) {
		display: block;
		max-width: 100%;
		height: auto;
		margin: var(--space-xs) 0 var(--space-md);
	}
	@media (max-width: 760px) {
		.layout {
			grid-template-columns: 1fr;
			gap: var(--space-lg);
			margin-top: var(--space-lg);
		}
		nav {
			position: static;
		}
	}
</style>
