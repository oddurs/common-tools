<script lang="ts">
	import { asset, resolve } from '$app/paths';
	import { page } from '$app/state';
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
		<a class="home" href={resolve('/(site)')}>Common Tools</a>
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
	<span>© 2026 Oddur Sigurdsson · MIT License</span>
	<a href="https://github.com/oddurs/common-tools">Source for this site</a>
</footer>

<style>
	nav {
		position: sticky;
		top: 0;
		z-index: 10;
		background: var(--nav);
		backdrop-filter: saturate(180%) blur(20px);
		border-bottom: 1px solid var(--rule);
	}
	.inner {
		max-width: 980px;
		margin: 0 auto;
		padding: 0 22px;
		height: 48px;
		display: flex;
		align-items: center;
		justify-content: space-between;
		font-size: 14px;
	}
	.home {
		color: var(--text);
		font-weight: 600;
	}
	.tools {
		display: flex;
		gap: 22px;
	}
	.tools a {
		color: var(--secondary);
	}
	.tools a:hover,
	.tools a[aria-current='page'] {
		color: var(--text);
		text-decoration: none;
	}
	footer {
		max-width: 980px;
		margin: 0 auto;
		padding: 18px 22px 40px;
		border-top: 1px solid var(--rule);
		font-size: 12px;
		color: var(--secondary);
		display: flex;
		justify-content: space-between;
		gap: 12px;
	}
	@media (max-width: 760px) {
		.inner {
			padding: 0 16px;
		}
		.tools {
			gap: 16px;
		}
		footer {
			margin: 0 16px;
			padding: 18px 0 32px;
			flex-direction: column;
		}
	}
</style>
