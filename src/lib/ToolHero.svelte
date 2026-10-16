<script lang="ts">
	import { asset, resolve } from '$app/paths';
	import { download, type Tool } from './tools';

	let { tool, docs = true }: { tool: Tool; docs?: boolean } = $props();
</script>

<header>
	<img src={asset(tool.icon)} alt="" width="96" height="96" />
	<h1>{tool.name}</h1>
	<p class="lede">{tool.tagline}</p>
	<div class="actions">
		<a class="button" href={download(tool)}>Download for Mac</a>
		{#if docs}<a class="link" href={resolve(`${tool.slug}/docs/`)}>Read the docs ›</a>{/if}
		<a class="link" href={tool.repo}>View on GitHub ›</a>
	</div>
	<p class="fine">Free and open source · {tool.requires}</p>
</header>

<style>
	header {
		text-align: center;
	}
	img {
		display: block;
		margin: 0 auto;
	}
	.actions {
		margin-top: 26px;
		display: flex;
		gap: 14px;
		justify-content: center;
		flex-wrap: wrap;
	}
</style>
