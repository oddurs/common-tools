<script lang="ts">
	import { asset, resolve } from '$app/paths';
	import DemoVideo from '#lib/DemoVideo.svelte';
	import Keys from '#lib/Keys.svelte';
	import Meta from '#lib/Meta.svelte';
	import { promise } from '#lib/promise.ts';
	import { megabytes, shortDate } from '#lib/releases.ts';
	import { download, showcase, tool } from '#lib/tools.ts';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();

	const apps = showcase.map(tool);
	/** Fans the family's icons out from the middle: a gentle arc, the middle ones on top. */
	const fan = (i: number) => {
		const c = i - (apps.length - 1) / 2;
		return {
			transform: `rotate(${c * 3.5}deg) translateY(${c * c * 1.6}px)`,
			z: 10 - Math.round(Math.abs(c))
		};
	};
</script>

<Meta
	title="Common Tools — small, native utilities for the Mac"
	description="Eight small, native macOS utilities: a launcher, screenshots to the clipboard, system stats, a tidy menu bar, keyboard layout fixes, a color picker, the battery, and your own menu bar images. Free forever, open source, and nothing you do is ever reported."
	path=""
	image="command/poster.jpg"
/>

<main>
	<header class="hero">
		<nav class="family" aria-label="The apps">
			{#each apps as t, i (t.slug)}
				{@const f = fan(i)}
				<a href="#{t.slug}" title={t.name} style:transform={f.transform} style:z-index={f.z}
					><img src={asset(t.icon)} alt={t.name} width="80" height="80" /></a
				>
			{/each}
		</nav>
		<h1>Common Tools</h1>
		<p class="lede">Small, native utilities for the Mac. Each does one thing and gets out of the way.</p>
		<p class="promise">{promise.line}</p>
		<p class="fine">macOS 14 or later · Apple silicon and Intel</p>
	</header>

	{#each apps as t, i (t.slug)}
		{@const release = data.releases[t.slug]}
		<section class="band app" class:tinted={i % 2 === 0} id={t.slug}>
			<div class="intro">
				<p class="eyebrow">
					<img src={asset(t.icon)} alt="" width="32" height="32" />{t.name}
				</p>
				<h2><a href={resolve(`${t.slug}/`)}>{t.tagline}</a></h2>
				<p class="summary"><Keys text={t.summary} /></p>
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
			<div class="stage">
				<DemoVideo tool={t} compact />
			</div>
		</section>
	{/each}

	<section class="principles ruled">
		{#each promise.parts as [title, text] (title)}
			<div>
				<h2>{title}</h2>
				<p class="muted">{text}</p>
			</div>
		{/each}
	</section>
</main>

<style>
	.hero {
		padding-bottom: var(--space-section);
		text-align: center;
	}
	.hero h1 {
		margin-top: var(--space-lg);
		font: var(--type-hero);
		letter-spacing: var(--type-hero-tracking);
	}
	.family {
		display: flex;
		justify-content: center;
	}
	.family a {
		position: relative;
		margin: 0 -9px;
		transition: translate var(--duration-fast) var(--easing-standard);
	}
	.family a:hover,
	.family a:focus-visible {
		translate: 0 -6px;
	}
	.family img {
		display: block;
		filter: drop-shadow(var(--shadow-icon));
	}
	.promise {
		margin: var(--space-md) auto 0;
		max-width: var(--layout-lede);
		font: var(--type-callout);
		letter-spacing: var(--type-callout-tracking);
		font-weight: var(--weight-semibold);
	}

	/* One app: its icon and name, the tagline as the headline, then its film. Only the icon has colour. */
	.app {
		scroll-margin-top: var(--space-xxl);
		text-align: center;
	}
	.intro {
		max-width: var(--layout-prose);
		margin: 0 auto;
	}
	.eyebrow {
		justify-content: center;
	}
	.app h2 {
		margin: var(--space-sm) 0 0;
		font: var(--type-display);
		letter-spacing: var(--type-display-tracking);
	}
	.app h2 a {
		color: var(--text-primary);
	}
	.app h2 a:hover {
		text-decoration: none;
	}
	.summary {
		margin: var(--space-md) auto 0;
		max-width: var(--layout-lede);
		font: var(--type-title3);
		letter-spacing: var(--type-title3-tracking);
		color: var(--text-secondary);
	}
	.actions {
		margin-top: var(--space-lg);
		display: flex;
		gap: var(--space-md);
		justify-content: center;
		align-items: center;
	}
	.intro .fine {
		margin-top: var(--space-sm);
	}
	.stage {
		margin-top: var(--space-xxxl);
	}

	.principles {
		display: grid;
		grid-template-columns: repeat(4, 1fr);
		gap: var(--space-xl);
	}
	.principles h2 {
		font: var(--type-headline);
		letter-spacing: var(--type-headline-tracking);
	}
	@media (max-width: 760px) {
		.hero h1 {
			font: var(--type-title);
			letter-spacing: var(--type-title-tracking);
		}
		.family a {
			margin: 0 -7px;
		}
		.family img {
			width: 44px;
			height: 44px;
		}
		.app h2 {
			font: var(--type-title2);
			letter-spacing: var(--type-title2-tracking);
		}
		.summary {
			font: var(--type-headline);
			font-weight: var(--weight-regular);
			letter-spacing: var(--type-headline-tracking);
		}
		.stage {
			margin-top: var(--space-xl);
		}
		.principles {
			grid-template-columns: 1fr 1fr;
			gap: var(--space-lg);
		}
	}
</style>
