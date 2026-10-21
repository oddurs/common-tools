<script lang="ts">
	import { asset, resolve } from '$app/paths';
	import Meta from '#lib/Meta.svelte';
	import { github } from '#lib/tools.ts';
	import type { Swatch } from '#lib/design.ts';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();

	const sections: [string, string][] = [
		['principles', 'Principles'],
		['colour', 'Colour'],
		['scales', 'Space, radius, motion'],
		['type', 'Type'],
		['site-primitives', 'Site primitives'],
		['app-primitives', 'App primitives'],
		['apps', 'The apps']
	];
	const appearances = ['light', 'dark'] as const;
	const themes = [
		['auto', 'System'],
		['light', 'Light'],
		['dark', 'Dark']
	] as const;

	/** A token by its parts or its dotted name, as `var(--…)`. */
	const v = (...parts: string[]) => `var(--${parts.join('-').replace('.', '-')})`;

	// The page follows the system like every page here, unless the reader picks an appearance; the
	// choice sets data-theme on the root, which tokens.css honours, and leaves with the page.
	let theme = $state<'auto' | 'light' | 'dark'>('auto');
	$effect(() => {
		const root = document.documentElement;
		if (theme === 'auto') delete root.dataset.theme;
		else root.dataset.theme = theme;
		return () => {
			delete root.dataset.theme;
		};
	});

	// Durations are 0ms under reduced motion, so the demos jump; say so rather than look broken.
	let reduced = $state(false);
	$effect(() => {
		const query = matchMedia('(prefers-reduced-motion: reduce)');
		reduced = query.matches;
		const update = () => (reduced = query.matches);
		query.addEventListener('change', update);
		return () => query.removeEventListener('change', update);
	});
	let moved = $state(false);

	// DesignRenderTests holds every render renders.json lists to a file in static/design.
	const render = (name: string, mode: string) =>
		`design/${name}-${mode}.png` as Parameters<typeof asset>[0];

	const ratio = (r: number) => `${r.toFixed(1)}:1`;
	const why = (s: Swatch) =>
		s.light.length === 9 || s.dark.length === 9
			? 'Translucent, so its contrast depends on what lies under it.'
			: s.name === 'surface.media'
				? 'Nothing is written on it.'
				: 'Not used for text.';

	const largest = $derived(Math.max(...data.layout.map((l: { value: number }) => l.value)));

	/** What each render shows, by the name DesignRender gives it. */
	const primitives: Record<string, { title: string; about: string }> = {
		card: {
			title: 'Card',
			about: 'A panel in a menu: a faint tint of the text colour inside a hairline, so it reads over either menu. Inset by Tokens.Layout.cardInset.'
		},
		'icon-badge': {
			title: 'IconBadge',
			about: 'A white symbol on a tinted, continuously rounded square, at 20 and 32 points.'
		},
		'labeled-row': {
			title: 'LabeledRow',
			about: 'Icon, title, subtitle and action; a title and a control; a dimmed title. VoiceOver reads each row as one element.'
		},
		'settings-footnote': {
			title: 'SettingsFootnote',
			about: 'A section footer: secondary, with a symbol, and in the danger colour.'
		},
		'menu-panel': {
			title: 'MenuPanelSurface, MenuRow, SectionHeader, ThumbnailTile',
			about: 'What a menu bar item opens when a menu can’t hold the job: MenuPanelHost floats MenuPanelSurface under the item on the menu’s material, takes the keyboard without activating the app, and closes on a click outside or Escape. MenuRow acts like a menu item; SectionHeader names a group; ThumbnailTile shows a picture whole with a caption, washed on hover and ringed in the accent when selected.'
		},
		confirmation: {
			title: 'ConfirmationHost, ConfirmationCard',
			about: 'Says what just happened, beside where it happened, for a moment: a picture of what was copied, what happened, and the text itself, on the popover material. ConfirmationHost floats it near a point without taking a click or the keyboard, announces it to VoiceOver, and fades it out after 1.4 s, at once under Reduce Motion.'
		},
		settings: {
			title: 'The Settings window',
			about: 'Drawn by the window, title bar included. The app’s own sections, then General with OpenAtLoginToggle and OpenAtLoginFootnote, then CommonToolsSection, in .settingsForm(). Rendered outside an app, so the version line is empty and the window is inactive.'
		}
	};

	// Every committed docs image of every app, found at build time; a new one shows up here unasked.
	const appImageUrls = import.meta.glob('../../../../../apps/*/docs/*.png', {
		eager: true,
		query: '?url',
		import: 'default'
	}) as Record<string, string>;
	const imageUrl = (path: string) => appImageUrls[`../../../../../${path}`];
	const imageTitle: Record<string, string> = {
		'menu.png': 'The menu',
		'bar-menu.png': 'The menu',
		'bar.png': 'The menu bar item'
	};
	const withImages = $derived(new Set(data.appImages.map((i) => i.slug)));
	const withoutImages = $derived(
		Object.entries(data.apps)
			.filter(([slug]) => !withImages.has(slug))
			.map(([, name]) => name)
	);
</script>

<Meta
	title="Common UI — the Common Tools design system"
	description="The tokens, scales, type, and primitives the Common Tools apps and this site share, drawn from the source they are made from."
	path="design/"
/>

<main>
	<p class="crumb"><a href={resolve('/(site)')}>Common Tools</a> › Design system</p>
	<h1>Common UI</h1>
	<p class="intro">
		The design system the apps and this site share: one set of tokens, a few primitives, and the rule that
		an app looks like macOS. Everything below is drawn from <code>tokens.json</code> and the Swift sources when
		the site is built, so it can't drift from them.
	</p>
	<div class="theme" role="group" aria-label="Appearance of this page">
		{#each themes as [option, label] (option)}
			<button type="button" aria-pressed={theme === option} onclick={() => (theme = option)}>
				{label}
			</button>
		{/each}
	</div>

	<div class="layout">
		<nav aria-label="On this page">
			<ul>
				{#each sections as [id, label] (id)}
					<li><a href="#{id}">{label}</a></li>
				{/each}
			</ul>
		</nav>

		<article>
			<h2 id="principles">Principles</h2>
			<p class="callout rule">
				In an app, never set a text size, never draw a shadow, never pick a blue. Use the text style,
				the system control, and the accent.
			</p>
			<p>
				The tokens exist for the gaps macOS leaves (cards in a menu, the Settings width) and for this
				site, which has no system to lean on and imitates one.
			</p>
			<h3>Four layers</h3>
			<ol>
				<li>
					<b>Palette</b>: {data.palette} raw colours, named for what they are. Nothing uses them directly.
				</li>
				<li>
					<b>Semantic tokens</b>: named for what they are for, such as <code>text.primary</code> or
					<code>space.md</code>. The only names a component may use; every colour has a light and a
					dark value.
				</li>
				<li>
					<b>Primitives</b>: the few reusable pieces built from tokens, in CommonUI for the apps and
					in
					<code>app.css</code> for the site.
				</li>
				<li><b>Pages and views</b> compose primitives and take every value from a token.</li>
			</ol>
			<h3>What is the system's and what is ours</h3>
			<p>
				Where macOS has a colour, an app uses it, so the user's accent, Increase Contrast and
				appearance apply. The site has to imitate one.
			</p>
			<div class="scroll">
				<table>
					<thead><tr><th>Token</th><th>In the apps</th><th>On the site</th></tr></thead>
					<tbody>
						{#each data.mapping as row (row.token)}
							<tr>
								<td><code>{row.token}</code></td>
								<td><code>{row.apps}</code></td>
								<td><code>{row.site}</code></td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>

			<h2 id="colour">Colour</h2>
			<p>
				Every semantic colour, as this site paints it in each appearance, with what the apps use
				instead. Ratios are WCAG 2 contrast for each pair <code>tokens.json</code> lists; a test holds every
				one to 4.5:1 in both appearances.
			</p>
			<div class="swatches">
				{#each data.swatches as s (s.name)}
					<section class="swatch">
						<div class="halves">
							{#each appearances as mode (mode)}
								<div class="half" data-theme={mode}>
									<span class="chip" style:background={v(s.name)}></span>
									<code class="value">{mode} {s[mode]}</code>
									{#each s.pairs as p (p.fg + p.bg)}
										<span class="pair">
											<span
												class="sample"
												style:color={v(p.fg)}
												style:background={v(p.bg)}>Aa</span
											>
											{ratio(p[mode])}
											<span class="against">{p.fg === s.name ? p.bg : p.fg}</span>
										</span>
									{/each}
								</div>
							{/each}
						</div>
						<h3><code>{s.name}</code></h3>
						<p class="about">{s.about}</p>
						<dl>
							<dt>Apps</dt>
							<dd>
								{#if 'system' in s.macos}
									<code>NSColor.{s.macos.system}</code>
								{:else}
									ours, <code>{s.macos.light}</code> / <code>{s.macos.dark}</code>
								{/if}
							</dd>
							<dt>Code</dt>
							<dd><code>{s.swift}</code> · <code>var({s.css})</code></dd>
							{#if !s.pairs.length}
								<dt>Contrast</dt>
								<dd>{why(s)}</dd>
							{/if}
						</dl>
					</section>
				{/each}
			</div>

			<h2 id="scales">Space, radius, motion and layout</h2>
			<h3>Space</h3>
			<p>{data.about.space} There is no step between 4 and 8, and that is the point.</p>
			<div class="scale">
				{#each data.space as step (step.name)}
					<code>{step.name}</code>
					<span class="bar" style:width={v('space', step.name)}></span>
					<span class="figure">{step.value}</span>
				{/each}
			</div>
			<h3>Radius</h3>
			<p>{data.about.radius}</p>
			<div class="radii">
				{#each data.radius as step (step.name)}
					<figure>
						<span class="corner" style:border-radius={v('radius', step.name)}></span>
						<figcaption><code>{step.name}</code> {step.value}</figcaption>
					</figure>
				{/each}
			</div>
			<h3>Motion</h3>
			<p>
				{data.about.motion} The apps get there through <code>Tokens.Motion.animation()</code> and
				<code>Tokens.Motion.duration()</code>; here every duration becomes 0ms under
				<code>prefers-reduced-motion</code>.
			</p>
			{#if reduced}
				<p class="callout">
					Your system asks for reduced motion, so these durations are 0ms and the dots jump. That is
					the tokens working.
				</p>
			{/if}
			<button type="button" class="button play" onclick={() => (moved = !moved)}>
				{moved ? 'Back' : 'Play'}
			</button>
			<div class="tracks" class:moved>
				{#each data.durations as d (d.name)}
					<code>{d.name} {d.value}ms</code>
					<span class="track"
						><span
							class="dot"
							style:transition-duration={v('duration', d.name)}
							style:transition-timing-function={v('easing', 'standard')}
						></span></span
					>
				{/each}
				{#each data.easings as e (e.name)}
					<code>{e.name}</code>
					<span class="track"
						><span
							class="dot"
							style:transition-duration={v('duration', 'slow')}
							style:transition-timing-function={v('easing', e.name)}
						></span></span
					>
				{/each}
			</div>
			<p class="fine">Durations on the standard easing; then each easing at the slow duration.</p>
			<h3>Layout</h3>
			<p>{data.about.layout} Widths are drawn to scale against the widest.</p>
			<div class="scale">
				{#each data.layout as l (l.name)}
					<code>{l.name}</code>
					<span class="bar layout-bar" style:width="{(l.value / largest) * 100}%"></span>
					<span class="figure">{l.value}</span>
				{/each}
			</div>
			<h3>Elevation and layers</h3>
			<p>
				The site's only. Windows, menus and popovers get the system's shadows and stack themselves, so
				the apps have neither.
			</p>
			<div class="shadows">
				{#each data.shadows as name (name)}
					<figure>
						<span class="lifted" style:box-shadow={v('shadow', name)}></span>
						<figcaption><code>--shadow-{name}</code></figcaption>
					</figure>
				{/each}
			</div>
			<p class="fine">
				Layers: {#each data.layers as l, i (l.name)}<code>{l.name}</code>
					{l.value}{i < data.layers.length - 1 ? ' · ' : ''}{/each}
			</p>

			<h2 id="type">Type</h2>
			<p>
				{data.about.type} In an app, write <code>.font(.body)</code>, never a size.
			</p>
			<div class="type-scale">
				{#each data.type as step (step.name)}
					<div class="step">
						<p
							class="specimen"
							style:font={v('type', step.name)}
							style:letter-spacing={v('type', step.name, 'tracking')}
						>
							Small, native utilities.
						</p>
						<p class="fine">
							<code>--type-{step.name}</code> · {step.size}/{Math.round(step.size * step.line)} ·
							{step.weight}
							· {step.font}
							{#if step.macos}· apps: <code>.{step.macos}</code>{:else}· site only{/if}
						</p>
					</div>
				{/each}
			</div>

			<h2 id="site-primitives">Site primitives</h2>
			<p>
				The pieces in <code>site/src/app.css</code>, live, in each appearance. A page lays them out
				and adds nothing but tokens.
			</p>
			{#snippet specimens()}
				<div class="specimen-row">
					<a class="button" href="#site-primitives">Download for Mac</a>
					<a class="link" href="#site-primitives">Read the docs ›</a>
				</div>
				<a class="card" href="#site-primitives">
					<b>Common Keys <em class="badge">Soon</em></b>
					<span class="muted">A <code>.card</code> with a <code>.badge</code> in its title.</span>
				</a>
				<p class="callout">A <code>.callout</code>: nothing leaves your Mac.</p>
				<section class="ruled">
					<h2>What's new.</h2>
					<p class="muted">A <code>section.ruled</code>: a band of the page under a rule.</p>
				</section>
				<table>
					<thead><tr><th>Metric</th><th>Source</th></tr></thead>
					<tbody>
						<tr><td>CPU</td><td><code>host_processor_info</code></td></tr>
						<tr><td>Memory</td><td><code>host_statistics64</code></td></tr>
					</tbody>
				</table>
				<pre><code>scripts/task check site kit</code></pre>
			{/snippet}
			<div class="panes">
				{#each appearances as mode (mode)}
					<div class="pane" data-theme={mode}>
						<p class="pane-label">{mode === 'light' ? 'Light' : 'Dark'}</p>
						{@render specimens()}
					</div>
				{/each}
			</div>
			<pre><code
					>{`<a class="button" href="…">Download for Mac</a>
<a class="link" href="…">Read the docs ›</a>
<a class="card" href="…">Common Keys <em class="badge">Soon</em></a>
<p class="callout">Nothing leaves your Mac.</p>
<section class="ruled"><h2>What's new.</h2>…</section>`}</code
				></pre>

			<h2 id="app-primitives">App primitives</h2>
			<p>
				CommonUI's pieces as AppKit and SwiftUI draw them, offscreen, from the current sources. The
				apps build Settings from these; a contract test in every app holds it to that.
			</p>
			{#each data.renders.renders as r (r.name)}
				{@const about = primitives[r.name]}
				<figure class="render">
					<figcaption>
						<b>{about?.title ?? r.name}</b>
						{#if about}<span class="muted">{about.about}</span>{/if}
					</figcaption>
					<div class="pair-images">
						{#each appearances as mode (mode)}
							<img
								src={asset(render(r.name, mode))}
								alt="{about?.title ?? r.name}, {mode}"
								width={r.width}
								height={r.height}
								loading="lazy"
							/>
						{/each}
					</div>
				</figure>
			{/each}

			<h2 id="apps">The apps</h2>
			<p>
				What each app draws with all this, from the images it keeps in <code
					>apps/&lt;slug&gt;/docs/</code
				>, light and dark side by side.
			</p>
			{#each data.appImages as image (image.path)}
				<figure class="render">
					<figcaption>
						<b>{data.apps[image.slug]}</b>
						<span class="muted">{imageTitle[image.file] ?? image.file}, light and dark</span>
					</figcaption>
					<img
						src={imageUrl(image.path)}
						alt="{data.apps[image.slug]}: {imageTitle[image.file] ??
							image.file}, in light and dark"
						width={image.width / 2}
						height={image.height / 2}
						loading="lazy"
					/>
				</figure>
			{/each}
			<p class="callout">
				No app keeps an image of its Settings yet; the Settings window under App primitives is built
				from the same pieces. {#if withoutImages.length}No docs images yet: {withoutImages.join(
						', '
					)}.{/if}
			</p>

			<footer class="sources">
				<p>
					Drawn from <code>packages/common-ui/tokens.json</code> and CommonKit's
					<code>CommonUI</code>
					when the site is built. After editing the tokens, run
					<code>node packages/common-ui/build.mjs</code>; after changing a primitive, run
					<code>{data.renders.command}</code> to draw its images again.
					<code>scripts/task test kit</code> fails while they are older than the Swift.
				</p>
				<p>
					<a href="{github}/blob/main/packages/common-ui/README.md">The Common UI README ›</a>
				</p>
			</footer>
		</article>
	</div>
</main>

<style>
	.crumb {
		margin: 0;
		font: var(--type-footnote);
		letter-spacing: var(--type-footnote-tracking);
		color: var(--text-secondary);
	}
	h1 {
		font: var(--type-title);
		letter-spacing: var(--type-title-tracking);
	}
	.intro {
		max-width: var(--layout-prose);
		margin: var(--space-xs) 0 var(--space-md);
		color: var(--text-secondary);
	}
	.theme {
		display: inline-flex;
		padding: var(--space-xxs);
		gap: var(--space-xxs);
		border-radius: var(--radius-full);
		background: var(--surface-card);
	}
	.theme button {
		padding: var(--space-xxs) var(--space-md);
		border: 0;
		border-radius: var(--radius-full);
		background: none;
		color: var(--text-secondary);
		font: var(--type-footnote);
		letter-spacing: var(--type-footnote-tracking);
		cursor: pointer;
		transition:
			background var(--duration-fast) var(--easing-standard),
			color var(--duration-fast) var(--easing-standard);
	}
	.theme button[aria-pressed='true'] {
		background: var(--surface-base);
		color: var(--text-primary);
		font-weight: var(--weight-semibold);
	}
	.layout {
		display: grid;
		grid-template-columns: 160px 1fr;
		gap: var(--space-xxl);
		margin-top: var(--space-xxl);
	}
	nav {
		position: sticky;
		top: var(--space-section);
		align-self: start;
		font: var(--type-footnote);
		letter-spacing: var(--type-footnote-tracking);
	}
	nav ul {
		margin: 0;
		padding: 0;
		list-style: none;
	}
	nav li {
		margin: 0 0 var(--space-xs);
	}
	nav a {
		color: var(--text-secondary);
	}
	nav a:hover {
		color: var(--text-primary);
		text-decoration: none;
	}
	article {
		min-width: 0;
	}
	article > h2 {
		margin: var(--space-section) 0 var(--space-xs);
		padding-top: var(--space-xxl);
		border-top: 1px solid var(--color-border);
		font: var(--type-title2);
		letter-spacing: var(--type-title2-tracking);
		scroll-margin-top: var(--space-xxl);
	}
	article > h2:first-child {
		margin-top: 0;
		padding-top: 0;
		border-top: 0;
	}
	article h3 {
		margin: var(--space-lg) 0 var(--space-xxs);
		font: var(--type-body);
		font-weight: var(--weight-semibold);
		letter-spacing: var(--type-body-tracking);
	}
	article > p,
	article li {
		max-width: var(--layout-prose);
		font: var(--type-callout);
		letter-spacing: var(--type-callout-tracking);
	}
	article > p {
		margin: 0 0 var(--space-sm);
	}
	ol {
		margin: 0 0 var(--space-sm);
		padding-left: var(--space-lg);
	}
	li {
		margin-bottom: var(--space-xxs);
	}
	.rule {
		font: var(--type-headline);
		letter-spacing: var(--type-headline-tracking);
	}
	.scroll {
		overflow-x: auto;
	}
	.scroll table {
		margin-top: var(--space-xs);
	}
	td code {
		font-size: 0.85em;
	}

	/* Colour */
	.swatches {
		display: grid;
		grid-template-columns: repeat(2, minmax(0, 1fr));
		gap: var(--space-lg);
		margin-top: var(--space-lg);
	}
	.swatch {
		display: flex;
		flex-direction: column;
	}
	.halves {
		display: grid;
		grid-template-columns: repeat(2, minmax(0, 1fr));
		border-radius: var(--radius-md);
		overflow: hidden;
		border: 1px solid var(--color-border);
	}
	.half {
		display: flex;
		flex-direction: column;
		gap: var(--space-xxs);
		min-width: 0;
		padding: var(--space-sm);
		background: var(--surface-base);
		color: var(--text-primary);
	}
	.chip {
		height: var(--space-xxxl);
		border-radius: var(--radius-sm);
		box-shadow: inset 0 0 0 1px var(--color-border);
	}
	.value {
		font-size: 0.75em;
		color: var(--text-secondary);
	}
	.pair {
		display: flex;
		align-items: center;
		gap: var(--space-xxs);
		font: var(--type-caption);
		letter-spacing: var(--type-caption-tracking);
		font-variant-numeric: tabular-nums;
	}
	.sample {
		padding: 0 var(--space-xxs);
		border-radius: var(--radius-xs);
		box-shadow: inset 0 0 0 1px var(--color-border);
		font-weight: var(--weight-semibold);
	}
	.against {
		color: var(--text-secondary);
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.swatch h3 {
		margin: var(--space-sm) 0 0;
		font: var(--type-callout);
		font-weight: var(--weight-semibold);
	}
	.about {
		margin: var(--space-xxs) 0;
		font: var(--type-footnote);
		letter-spacing: var(--type-footnote-tracking);
		color: var(--text-secondary);
	}
	dl {
		display: grid;
		grid-template-columns: auto 1fr;
		gap: var(--space-xxs) var(--space-sm);
		margin: 0;
		font: var(--type-caption);
		letter-spacing: var(--type-caption-tracking);
	}
	dt {
		color: var(--text-secondary);
	}
	dd {
		margin: 0;
		min-width: 0;
		overflow-wrap: anywhere;
	}

	/* Scales */
	.scale {
		display: grid;
		grid-template-columns: max-content 1fr max-content;
		align-items: center;
		gap: var(--space-xs) var(--space-md);
		max-width: var(--layout-prose);
		font: var(--type-footnote);
	}
	.bar {
		display: block;
		height: var(--space-sm);
		border-radius: var(--radius-xs);
		background: var(--color-accent);
	}
	.layout-bar {
		background: var(--text-secondary);
	}
	.figure {
		font-variant-numeric: tabular-nums;
		color: var(--text-secondary);
		text-align: right;
	}
	.radii,
	.shadows {
		display: flex;
		flex-wrap: wrap;
		gap: var(--space-lg);
	}
	figure {
		margin: 0;
	}
	.radii figure,
	.shadows figure {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: var(--space-xs);
		font: var(--type-caption);
		color: var(--text-secondary);
	}
	.corner {
		width: var(--space-section);
		height: var(--space-section);
		background: var(--surface-card);
		border: 1px solid var(--color-border);
	}
	.lifted {
		width: calc(var(--space-section) * 2);
		height: var(--space-section);
		margin: var(--space-md);
		border-radius: var(--radius-md);
		background: var(--surface-card);
	}
	.play {
		border: 0;
		font: inherit;
		cursor: pointer;
		margin-bottom: var(--space-md);
	}
	.tracks {
		display: grid;
		grid-template-columns: max-content 1fr;
		align-items: center;
		gap: var(--space-sm) var(--space-md);
		max-width: var(--layout-prose);
		font: var(--type-footnote);
	}
	.track {
		position: relative;
		height: var(--space-md);
		border-radius: var(--radius-full);
		background: var(--surface-card);
	}
	.dot {
		position: absolute;
		top: 0;
		left: 0;
		width: var(--space-md);
		height: var(--space-md);
		border-radius: var(--radius-full);
		background: var(--color-accent-fill);
		transition-property: left;
	}
	.moved .dot {
		left: calc(100% - var(--space-md));
	}

	/* Type */
	.type-scale .step {
		padding: var(--space-sm) 0;
		border-bottom: 1px solid var(--color-border);
	}
	.specimen {
		margin: 0;
		overflow-wrap: anywhere;
	}
	.type-scale .fine {
		margin: var(--space-xxs) 0 0;
	}

	/* Specimens */
	.panes {
		display: grid;
		grid-template-columns: repeat(2, minmax(0, 1fr));
		gap: var(--space-md);
		margin: var(--space-md) 0;
	}
	.pane {
		display: flex;
		flex-direction: column;
		gap: var(--space-md);
		padding: var(--space-lg);
		border-radius: var(--radius-lg);
		border: 1px solid var(--color-border);
		background: var(--surface-base);
		color: var(--text-primary);
		min-width: 0;
	}
	.pane-label {
		margin: 0;
		font: var(--type-caption2);
		letter-spacing: var(--type-caption2-tracking);
		color: var(--text-secondary);
		text-transform: uppercase;
	}
	.specimen-row {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: var(--space-xs);
	}
	.pane .card {
		display: flex;
		flex-direction: column;
		gap: var(--space-xxs);
	}
	.pane .callout,
	.pane table {
		margin: 0;
	}
	.pane section.ruled {
		margin-top: 0;
		padding-top: var(--space-md);
	}
	.render {
		margin: var(--space-lg) 0;
	}
	.render figcaption {
		display: flex;
		flex-direction: column;
		gap: var(--space-xxs);
		max-width: var(--layout-prose);
		margin-bottom: var(--space-sm);
		font: var(--type-callout);
		letter-spacing: var(--type-callout-tracking);
	}
	.pair-images {
		display: flex;
		flex-wrap: wrap;
		align-items: flex-start;
		gap: var(--space-md);
	}
	.render img {
		display: block;
		max-width: 100%;
		height: auto;
		border-radius: var(--radius-md);
		border: 1px solid var(--color-border);
	}
	.pair-images img {
		max-width: calc(50% - var(--space-md) / 2);
	}
	.sources {
		margin-top: var(--space-section);
		padding-top: var(--space-lg);
		border-top: 1px solid var(--color-border);
		font: var(--type-footnote);
		letter-spacing: var(--type-footnote-tracking);
		color: var(--text-secondary);
	}
	.sources p {
		margin: 0 0 var(--space-xs);
		max-width: var(--layout-prose);
	}

	@media (max-width: 760px) {
		.layout {
			grid-template-columns: 1fr;
			gap: var(--space-lg);
			margin-top: var(--space-lg);
		}
		nav {
			position: static;
		}
		.swatches,
		.panes {
			grid-template-columns: 1fr;
		}
		.pair-images img {
			max-width: 100%;
		}
	}
</style>
