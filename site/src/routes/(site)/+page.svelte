<script lang="ts">
	import { asset, resolve } from '$app/paths';
	import DemoVideo from '#lib/DemoVideo.svelte';
	import Meta from '#lib/Meta.svelte';
	import { megabytes, shortDate } from '#lib/releases.ts';
	import { download, tools, upcoming } from '#lib/tools.ts';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();

	const principles = [
		[
			'Native.',
			'AppKit and SwiftUI, drawn the way macOS draws its own. Real menus, System Settings layouts, VoiceOver.'
		],
		[
			'Private.',
			'No network access, no analytics, no account. What an app learns stays in one file on your Mac.'
		],
		['Small.', 'Each one does a single job, downloads in seconds, and stays out of the way.'],
		[
			'Open.',
			'MIT licensed and built in the open on GitHub, every change checked by its tests before it merges.'
		]
	];
</script>

<Meta
	title="Common Tools — small, native utilities for the Mac"
	description="Common Stats, Common Keys, Common Bar, and more on the way: small, native macOS utilities. Free and open source, and nothing leaves your Mac."
	path=""
	image="stats/poster.jpg"
/>

<main>
	<header>
		<div class="family" aria-hidden="true">
			{#each tools as t (t.slug)}
				<img src={asset(t.icon)} alt="" width="88" height="88" />
			{/each}
		</div>
		<h1>Common Tools</h1>
		<p class="lede">Small, native utilities for the Mac. Each does one thing and gets out of the way.</p>
		<p class="fine">Free and open source · macOS 14 or later · Apple silicon and Intel</p>
	</header>

	{#each tools as t, i (t.slug)}
		{@const release = data.releases[t.slug]}
		<section class="tool ruled" class:flip={i % 2 === 1}>
			<DemoVideo tool={t} compact />
			<div class="about">
				<img class="icon" src={asset(t.icon)} alt="" width="64" height="64" />
				<h2><a href={resolve(`${t.slug}/`)}>{t.name}</a></h2>
				<p class="tagline">{t.tagline}</p>
				<p class="muted">{t.summary}</p>
				<div class="actions">
					<a class="button" href={download(t, release)}>Download</a>
					<a class="link" href={resolve(`${t.slug}/`)}>Learn more ›</a>
				</div>
				<p class="fine">
					{#if release}
						Version {release.version} · {shortDate(release.date)} · {megabytes(release.size)}
					{:else}
						{t.requires}
					{/if}
				</p>
			</div>
		</section>
	{/each}

	<section class="soon ruled">
		<h2>Coming soon.</h2>
		<div class="cards">
			{#each upcoming as u (u.slug)}
				<a class="card" href={resolve(`${u.slug}/`)}>
					<img src={asset(u.icon)} alt="" width="64" height="64" />
					<b>{u.name}</b>
					<span class="muted">{u.tagline}</span>
				</a>
			{/each}
		</div>
	</section>

	<section class="principles ruled">
		{#each principles as [title, text] (title)}
			<div>
				<h2>{title}</h2>
				<p class="muted">{text}</p>
			</div>
		{/each}
	</section>
</main>

<style>
	header {
		text-align: center;
		margin-bottom: 16px;
	}
	.family {
		display: flex;
		justify-content: center;
		margin-bottom: 8px;
	}
	.family img {
		margin: 0 -6px;
		filter: drop-shadow(var(--shadow-icon));
	}
	.family img:nth-child(1) {
		transform: rotate(-8deg) translateY(6px);
	}
	.family img:nth-child(3) {
		transform: rotate(8deg) translateY(6px);
	}
	.family img:nth-child(2) {
		position: relative;
		z-index: 1;
		transform: scale(1.08);
	}
	.tool {
		display: grid;
		grid-template-columns: 1.35fr 1fr;
		gap: 40px;
		align-items: center;
	}
	.tool.flip :global(figure) {
		order: 2;
	}
	.icon {
		display: block;
		margin-bottom: 10px;
	}
	h2 {
		font-size: 28px;
	}
	h2 a {
		color: var(--text-primary);
	}
	.tagline {
		margin: 0 0 8px;
		font-size: 19px;
		line-height: 1.3;
	}
	.actions {
		margin-top: 18px;
		display: flex;
		gap: 14px;
		align-items: center;
	}
	.soon .cards {
		display: grid;
		grid-template-columns: repeat(4, 1fr);
		gap: 16px;
		margin-top: 16px;
	}
	.soon .card {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 6px;
		padding: 22px 14px;
		border-radius: 16px;
		background: var(--surface-card);
		color: var(--text-primary);
		text-align: center;
	}
	.soon .card:hover {
		text-decoration: none;
	}
	.soon .card .muted {
		font-size: 14px;
	}
	.principles {
		display: grid;
		grid-template-columns: repeat(4, 1fr);
		gap: 32px;
	}
	.principles h2 {
		font-size: 19px;
	}
	@media (max-width: 760px) {
		.family img {
			width: 64px;
			height: 64px;
		}
		.tool {
			grid-template-columns: 1fr;
			gap: 24px;
		}
		.tool.flip :global(figure) {
			order: 0;
		}
		.soon .cards {
			grid-template-columns: 1fr 1fr;
		}
		.principles {
			grid-template-columns: 1fr 1fr;
			gap: 24px;
		}
	}
</style>
