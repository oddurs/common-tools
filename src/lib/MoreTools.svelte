<script lang="ts">
	import { asset, resolve } from '$app/paths';
	import { tools, type Tool } from './tools';

	let { tool }: { tool: Tool } = $props();

	const others = $derived(tools.filter((t) => t.slug !== tool.slug));
</script>

<section class="ruled">
	<h2>More Common Tools.</h2>
	<div class="cards">
		{#each others as t (t.slug)}
			<a class="card" href={resolve(`${t.slug}/`)}>
				<img src={asset(t.icon)} alt="" width="56" height="56" />
				<span>
					<b>{t.name}</b>
					<span class="muted">{t.summary}</span>
				</span>
			</a>
		{/each}
	</div>
</section>

<style>
	.cards {
		display: grid;
		grid-template-columns: repeat(2, 1fr);
		gap: 16px;
		margin-top: 16px;
	}
	.card {
		display: flex;
		gap: 16px;
		align-items: center;
		padding: 18px;
		border-radius: 16px;
		background: var(--panel);
		color: var(--text);
		transition: transform 0.15s ease;
	}
	.card:hover {
		text-decoration: none;
		transform: translateY(-2px);
	}
	.card > span {
		display: flex;
		flex-direction: column;
		gap: 2px;
	}
	@media (max-width: 760px) {
		.cards {
			grid-template-columns: 1fr;
		}
	}
	@media (prefers-reduced-motion: reduce) {
		.card {
			transition: none;
		}
	}
</style>
