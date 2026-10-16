<script lang="ts">
	import { asset, resolve } from '$app/paths';
	import { download, tools } from '#lib/tools.ts';
</script>

<svelte:head>
	<title>Common Tools — small, native utilities for the Mac menu bar</title>
	<meta
		name="description"
		content="Common Stats, Common Keys, and Common Bar: small, native macOS menu bar utilities. Free and open source, nothing leaves your Mac."
	/>
</svelte:head>

<main>
	<header>
		<h1>Common Tools</h1>
		<p class="lede">
			Small, native utilities for the Mac menu bar. Each does one thing and gets out of the way.
		</p>
		<p class="fine">Free and open source · No network, no analytics, no account</p>
	</header>

	{#each tools as t (t.slug)}
		<section class="tool ruled">
			<a class="poster" href={resolve(`${t.slug}/`)} tabindex="-1">
				<picture>
					<source srcset={asset(`${t.slug}/poster-dark.jpg`)} media="(prefers-color-scheme: dark)" />
					<img src={asset(`${t.slug}/poster.jpg`)} alt="" width="1280" height="800" loading="lazy" />
				</picture>
			</a>
			<div class="about">
				<img class="icon" src={asset(t.icon)} alt="" width="64" height="64" />
				<h2><a href={resolve(`${t.slug}/`)}>{t.name}</a></h2>
				<p class="muted">{t.summary}</p>
				<div class="actions">
					<a class="button" href={download(t)}>Download</a>
					<a class="link" href={resolve(`${t.slug}/`)}>Learn more ›</a>
				</div>
				<p class="fine">{t.requires}</p>
			</div>
		</section>
	{/each}
</main>

<style>
	header {
		text-align: center;
		margin-bottom: 16px;
	}
	.tool {
		display: grid;
		grid-template-columns: 1.35fr 1fr;
		gap: 40px;
		align-items: center;
	}
	.tool:nth-of-type(even) .poster {
		order: 2;
	}
	.poster {
		display: block;
		border-radius: 14px;
		overflow: hidden;
		box-shadow: 0 14px 40px rgba(0, 0, 0, 0.16);
		aspect-ratio: 16 / 10;
		background: var(--video);
	}
	.poster img {
		display: block;
		object-fit: cover;
		width: 100%;
		height: 100%;
	}
	.icon {
		display: block;
		margin-bottom: 10px;
	}
	h2 {
		font-size: 28px;
	}
	h2 a {
		color: var(--text);
	}
	.actions {
		margin-top: 18px;
		display: flex;
		gap: 14px;
		align-items: center;
	}
	@media (max-width: 760px) {
		.tool {
			grid-template-columns: 1fr;
			gap: 24px;
		}
		.tool:nth-of-type(even) .poster {
			order: 0;
		}
	}
</style>
