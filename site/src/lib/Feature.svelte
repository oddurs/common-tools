<script lang="ts">
	// One feature on an app's page: a headline and a sentence beside a still from the app's film, in the
	// viewer's appearance. Rows alternate sides; on a phone the still comes first.
	import { asset } from '$app/paths';
	import Keys from './Keys.svelte';
	import type { Feature } from './pages';
	import type { AppSlug } from './tools';

	let { slug, feature, index }: { slug: AppSlug; feature: Feature; index: number } = $props();

	const light = $derived(asset(`${slug}/features/${index + 1}.jpg` as Parameters<typeof asset>[0]));
	const dark = $derived(asset(`${slug}/features/${index + 1}-dark.jpg` as Parameters<typeof asset>[0]));
</script>

<section class="feature" class:flip={index % 2 === 1}>
	<div class="words">
		<h2>{feature.title}</h2>
		<p><Keys text={feature.text} /></p>
	</div>
	<picture>
		<source srcset={dark} media="(prefers-color-scheme: dark)" />
		<img src={light} alt="" loading="lazy" decoding="async" />
	</picture>
</section>

<style>
	.feature {
		display: grid;
		grid-template-columns: 5fr 7fr;
		gap: var(--space-xxxl);
		align-items: center;
		margin-top: var(--space-section);
	}
	.feature.flip {
		grid-template-columns: 7fr 5fr;
	}
	.feature.flip .words {
		order: 2;
	}
	h2 {
		margin: 0;
		font: var(--type-title);
		letter-spacing: var(--type-title-tracking);
	}
	p {
		margin: var(--space-sm) 0 0;
		font: var(--type-headline);
		font-weight: var(--weight-regular);
		line-height: 1.4;
		letter-spacing: var(--type-headline-tracking);
		color: var(--text-secondary);
	}
	img {
		display: block;
		width: 100%;
		height: auto;
		aspect-ratio: 16 / 10;
		object-fit: cover;
		border-radius: var(--radius-lg);
		box-shadow: var(--shadow-media-compact);
		background: var(--surface-media);
	}
	@media (max-width: 760px) {
		.feature,
		.feature.flip {
			grid-template-columns: 1fr;
			gap: var(--space-md);
			margin-top: var(--space-xxl);
		}
		.feature .words,
		.feature.flip .words {
			order: 2;
		}
		h2 {
			font: var(--type-title2);
			letter-spacing: var(--type-title2-tracking);
		}
	}
</style>
