<script lang="ts">
	import { asset, resolve } from '$app/paths';
	import { tools, upcoming } from './tools';

	/** The page's own app, left out of the list. */
	let { slug }: { slug: string } = $props();

	const others = $derived(
		[...tools.map((t) => ({ ...t, soon: false })), ...upcoming.map((u) => ({ ...u, soon: true }))].filter(
			(t) => t.slug !== slug
		)
	);
</script>

<section class="ruled">
	<h2>More Common Tools.</h2>
	<div class="cards">
		{#each others as t (t.slug)}
			<a class="card" href={resolve(`${t.slug}/`)}>
				<img src={asset(t.icon)} alt="" width="56" height="56" />
				<span>
					<b
						>{t.name}{#if t.soon}<em class="badge">Soon</em>{/if}</b
					>
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
		gap: var(--space-md);
		margin-top: var(--space-md);
	}
	.card {
		display: flex;
		gap: var(--space-md);
		align-items: center;
		/* The duration is 0 under prefers-reduced-motion, so the lift just doesn't happen. */
		transition: transform var(--duration-fast) var(--easing-standard);
	}
	.card:hover {
		transform: translateY(-2px);
	}
	.badge {
		margin-left: var(--space-xs);
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
</style>
