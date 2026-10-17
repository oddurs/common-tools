<script lang="ts">
	import { inlineMarkdown, shortDate, type Release } from './releases';
	import type { Tool } from './tools';

	let { tool, release }: { tool: Tool; release: Release } = $props();
</script>

{#if release.notes.length}
	<section class="ruled">
		<div class="head">
			<h2>What's new in {release.version}</h2>
			<span class="muted">{shortDate(release.date)} · <a href="{tool.repo}/releases">All releases ›</a></span>
		</div>
		<div class="notes">
			{#each release.notes as { heading, items } (heading)}
				<div>
					<h3>{heading}</h3>
					<ul>
						{#each items as item, i (i)}
							<!-- The CHANGELOG is ours; inlineMarkdown escapes everything but bold, code, and https links. -->
							<li>{@html inlineMarkdown(item)}</li>
						{/each}
					</ul>
				</div>
			{/each}
		</div>
	</section>
{/if}

<style>
	.head {
		display: flex;
		align-items: baseline;
		justify-content: space-between;
		gap: 16px;
		flex-wrap: wrap;
	}
	.notes {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
		gap: 24px 40px;
		margin-top: 16px;
	}
	h3 {
		margin: 0 0 6px;
		font-size: 13px;
		font-weight: 600;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		color: var(--secondary);
	}
	ul {
		margin: 0;
		padding-left: 18px;
		font-size: 15px;
	}
	li + li {
		margin-top: 6px;
	}
</style>
