<script lang="ts">
	import { asset, resolve } from '$app/paths';
	import { page } from '$app/state';
	import { promise } from '#lib/promise.ts';
	import { tools } from '#lib/tools.ts';
	import type { LayoutProps } from './$types';

	let { children }: LayoutProps = $props();

	const current = $derived(tools.find((t) => page.url.pathname.includes(`/${t.slug}/`)));
</script>

<svelte:head>
	<link rel="icon" href={asset(current?.icon ?? 'icon.svg')} />
</svelte:head>

<nav>
	<div class="inner">
		<a class="home" href={resolve('/(site)')}
			><img src={asset('icon.svg')} alt="" width="22" height="22" />Common Tools</a
		>
		<span class="tools">
			{#each tools as t (t.slug)}
				<a href={resolve(`${t.slug}/`)} aria-current={current === t ? 'page' : undefined}>
					{t.name.replace('Common ', '')}
				</a>
			{/each}
		</span>
	</div>
</nav>

{@render children()}

<footer>
	<span>© 2026 Oddur Sigurdsson · MIT License · {promise.short}</span>
	<span class="links">
		<a href={resolve('design/')}>Design system</a>
		<a href="https://github.com/oddurs/common-tools">Source for this site</a>
	</span>
</footer>

<style>
	nav {
		position: sticky;
		top: 0;
		z-index: var(--layer-sticky);
		background: var(--surface-chrome);
		backdrop-filter: saturate(180%) blur(20px);
		border-bottom: 1px solid var(--color-border);
	}
	.inner {
		max-width: var(--layout-content);
		margin: 0 auto;
		padding: 0 var(--layout-gutter);
		height: 48px;
		display: flex;
		align-items: center;
		justify-content: space-between;
		font: var(--type-footnote);
		letter-spacing: var(--type-footnote-tracking);
	}
	.home {
		display: flex;
		align-items: center;
		gap: var(--space-xs);
		color: var(--text-primary);
		font-weight: var(--weight-semibold);
	}
	.home:hover {
		text-decoration: none;
	}
	.tools {
		display: flex;
		gap: var(--layout-gutter);
	}
	.tools a {
		color: var(--text-secondary);
	}
	.tools a:hover,
	.tools a[aria-current='page'] {
		color: var(--text-primary);
		text-decoration: none;
	}
	footer {
		max-width: var(--layout-content);
		margin: 0 auto;
		padding: var(--space-md) var(--layout-gutter) var(--space-xxl);
		border-top: 1px solid var(--color-border);
		font: var(--type-caption);
		letter-spacing: var(--type-caption-tracking);
		color: var(--text-secondary);
		display: flex;
		justify-content: space-between;
		gap: var(--space-sm);
	}
	.links {
		display: flex;
		gap: var(--space-md);
	}
	@media (max-width: 760px) {
		.inner {
			padding: 0 var(--layout-gutter-narrow);
		}
		.tools {
			gap: var(--space-md);
		}
		footer {
			margin: 0 var(--layout-gutter-narrow);
			padding: var(--space-md) 0 var(--space-xl);
			flex-direction: column;
		}
	}
</style>
