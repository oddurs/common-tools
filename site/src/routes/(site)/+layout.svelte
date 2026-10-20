<script lang="ts">
	import { asset, resolve } from '$app/paths';
	import { page } from '$app/state';
	import { promise } from '#lib/promise.ts';
	import { showcase, tool, tools } from '#lib/tools.ts';
	import type { LayoutProps } from './$types';

	let { children }: LayoutProps = $props();

	const current = $derived(tools.find((t) => page.url.pathname.includes(`/${t.slug}/`)));
</script>

<svelte:head>
	<link rel="icon" href={asset(current?.icon ?? 'icon.svg')} />
</svelte:head>

<!-- A glass capsule floating over the page, as macOS 26 floats its toolbars. -->
<header class="chrome">
	<nav aria-label="Common Tools">
		<a class="home" href={resolve('/(site)')}
			><img src={asset('icon.svg')} alt="" width="22" height="22" />Common Tools</a
		>
		<span class="tools">
			{#each showcase.map(tool) as t (t.slug)}
				<a href={resolve(`${t.slug}/`)} aria-current={current === t ? 'page' : undefined}>
					{t.name.replace('Common ', '')}
				</a>
			{/each}
		</span>
	</nav>
</header>

{@render children()}

<footer>
	<span>© 2026 Oddur Sigurdsson · MIT License · {promise.short}</span>
	<span class="links">
		<a href={resolve('design/')}>Design system</a>
		<a href="https://github.com/oddurs/common-tools">Source for this site</a>
	</span>
</footer>

<style>
	/* Fixed, so it takes no room: the page runs under the glass from the top. */
	.chrome {
		position: fixed;
		top: var(--space-sm);
		left: 0;
		right: 0;
		z-index: var(--layer-sticky);
		display: flex;
		justify-content: center;
		padding: 0 var(--layout-gutter);
		pointer-events: none;
	}
	nav {
		pointer-events: auto;
		width: 100%;
		max-width: var(--layout-content);
		height: 48px;
		padding: 0 var(--space-xxs) 0 var(--space-md);
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: var(--space-md);
		border-radius: var(--radius-full);
		background: var(--surface-chrome);
		backdrop-filter: saturate(180%) blur(24px);
		-webkit-backdrop-filter: saturate(180%) blur(24px);
		box-shadow: var(--shadow-chrome);
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
	.home {
		white-space: nowrap;
	}
	.tools {
		display: flex;
		gap: var(--space-xxs);
	}
	.tools a {
		padding: 6px var(--space-sm);
		border-radius: var(--radius-full);
		color: var(--text-secondary);
		transition:
			background var(--duration-fast) var(--easing-standard),
			color var(--duration-fast) var(--easing-standard);
	}
	.tools a:hover {
		color: var(--text-primary);
		text-decoration: none;
	}
	.tools a[aria-current='page'] {
		background: var(--surface-card);
		color: var(--text-primary);
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
		/* Eight names don't fit a phone; the home page's icons link to every app instead. */
		.tools {
			display: none;
		}
		.chrome {
			padding: 0 var(--layout-gutter-narrow);
		}
		footer {
			margin: 0 var(--layout-gutter-narrow);
			padding: var(--space-md) 0 var(--space-xl);
			flex-direction: column;
		}
	}
</style>
