<script lang="ts">
	// GlyphEditor, the sheet over Settings: the preview, Name and Show in menu bar, the Source
	// (an image's drop zone or crop editor, or a text field and the suggestions), then the Look. The
	// blocks sit at the points measured from offscreen renders of the real sheet, 460 by 660 with its
	// buttons in the last 57. Styles live in Demo.svelte, under `.form`.
	import Symbol from '../mac/Symbol.svelte';
	import Mochi from './Mochi.svelte';
	import Preview from './Preview.svelte';
	import { editor, popupMenu, sheet, type Source } from './demo';

	type Image = {
		kind: 'image';
		/** 0 while it waits for a picture, 1 once the crop editor shows it. */
		picture: number;
		scroll: number;
		background: 'keep' | 'subject';
		popup: { opacity: number; hover: boolean };
	};
	type Text = { kind: 'text'; text: string };

	let {
		name,
		glyph,
		style,
		alone,
		source
	}: {
		name: string;
		glyph: Source;
		style: 'color' | 'silhouette';
		/** The only glyph: it can't be hidden or deleted, and says why. */
		alone: boolean;
		source: Image | Text;
	} = $props();

	const summaries = {
		color: "Drawn in the image's own colours.",
		silhouette: "The image's outline, tinted to match the menu bar like the system's own icons."
	};
	const suggestions = ['✦', '☾', '☯', '♞', '⚘', 'ᓚᘏᗢ', '(◕‿◕)', '( ˘ω˘ )', '👾', '🐈‍⬛', '🔥', '🌸'];
	/** The picture fitted into the crop editor: 4:3 in 400 by 260. */
	const fitted = { width: (260 * 4) / 3, height: 260 };
	const backgrounds = { keep: 'Keep', solid: 'Remove solid colour', subject: 'Lift subject' };

	// Where the blocks sit, from the top of the sheet.
	const y = $derived(
		source.kind === 'image'
			? { source: 242, section: 269, look: 668, lookSection: 691, foot: 816 }
			: { source: 217, section: 244, look: 450, lookSection: 477, foot: 565 }
	);
	const scroll = $derived(source.kind === 'image' ? source.scroll : 0);
	const awaiting = $derived(source.kind === 'image' && source.picture === 0);
</script>

<div class="f-sheet" style:height="{sheet.height}px">
	<div class="f-scroll" style:height="{sheet.height - sheet.footer}px">
		<div class="f-content" style:transform="translateY({-scroll}px)">
			<div class="at" style:top="20px"><Preview glyphs={[glyph]} /></div>

			<div class="at f-section" style:top="114px">
				<div class="f-row short">
					<span class="f-grow">Name</span><span>{name}</span>
				</div>
				<div class="f-row short">
					<span class="f-grow">Show in menu bar</span><i class="f-switch on" class:disabled={alone}
					></i>
				</div>
			</div>
			{#if alone}
				<p class="at f-foot" style:top="196px">
					One glyph always stays in the menu bar, so its menu stays in reach.
				</p>
			{/if}

			<h3 class="at f-header" style:top="{y.source}px">Source</h3>
			<div class="at f-section" style:top="{y.section}px">
				<div class="f-row">
					<span class="f-grow">Source</span>
					<span class="f-seg" style:width="193px"
						><span class:on={source.kind === 'image'}>Image</span><span
							class:on={source.kind === 'text'}>Emoji or text</span
						></span
					>
				</div>
				{#if source.kind === 'image'}
					<div class="f-rule well">
						{#if source.picture < 1}
							<div class="f-drop" style:opacity={1 - source.picture}>
								<svg width="400" height="260" aria-hidden="true"
									><rect
										x="0.75"
										y="0.75"
										width="398.5"
										height="258.5"
										rx="12"
										fill="none"
										stroke="currentColor"
										stroke-width="1.5"
										stroke-dasharray="5 4"
									/></svg
								>
								<Symbol name="photo.badge.plus" />
								<span>Drop an image here, or onto the glyph in the menu bar</span>
								<small>A character, a tattoo design, a sticker, an animated GIF</small>
							</div>
						{/if}
						{#if source.picture > 0}
							<div
								class="f-crop"
								style:opacity={source.picture}
								style:left="{(400 - fitted.width) / 2}px"
								style:width="{fitted.width}px"
								style:height="{fitted.height}px"
							>
								<Mochi mode="photo" width={fitted.width} height={fitted.height} />
								<i class="box"></i>
								{#each ['tl', 'tr', 'bl', 'br'] as corner (corner)}<b class="handle {corner}"
									></b>{/each}
							</div>
						{/if}
					</div>
					<div class="f-row f-rule buttons">
						<span class="f-btn">Choose…</span><span class="f-btn">Paste</span>
						<span class="f-grow"></span>
						{#if !awaiting}
							<span class="f-btn icon"><Symbol name="rotate.right" /></span>
							<span class="f-btn icon"
								><Symbol
									name="arrow.left.and.right.righttriangle.left.righttriangle.right"
								/></span
							>
							<span class="f-btn off">Reset</span>
						{/if}
					</div>
				{:else}
					<div class="f-row f-rule tall">
						<span class="f-grow title3">Text</span><span class="title3">{source.text}</span>
						<span class="f-btn icon"><Symbol name="face.smiling" /></span>
					</div>
					<div class="f-grid">
						{#each suggestions as suggestion (suggestion)}<span class="f-btn">{suggestion}</span
							>{/each}
					</div>
				{/if}
			</div>

			{#if !awaiting}
				<h3 class="at f-header" style:top="{y.look}px">Look</h3>
				<div class="at f-section" style:top="{y.lookSection}px">
					<div class="f-row">
						<span class="f-grow">Style</span>
						<span class="f-seg" style:width="247px"
							><span class:on={style === 'color'}>Colour</span><span
								class:on={style === 'silhouette'}>Silhouette</span
							><span>Ink</span></span
						>
					</div>
					{#if source.kind === 'image'}
						<div class="f-row short2">
							<span class="f-grow">Background</span>
							<span class="f-popup"
								>{backgrounds[source.background]}<i
									><Symbol name="chevron.up.chevron.down" /></i
								></span
							>
						</div>
					{/if}
					<div class="f-row short3">
						<span class="f-grow">Size</span>
						<span class="f-slider"><i style:width="70%"></i><b style:left="70%"></b></span>
					</div>
				</div>
				<p class="at f-foot" style:top="{y.foot}px">{summaries[style]}</p>
			{/if}
		</div>
	</div>

	{#if source.kind === 'image' && source.popup.opacity > 0}
		<div
			class="f-menu"
			style:left="{popupMenu.x}px"
			style:top="{editor.background.y - scroll - popupMenu.pad - popupMenu.row / 2}px"
			style:width="{popupMenu.width}px"
			style:opacity={source.popup.opacity}
		>
			{#each ['keep', 'solid', 'subject'] as const as option (option)}
				<span class:hover={option === 'subject' && source.popup.hover}
					><i
						>{#if option === 'keep'}<Symbol name="checkmark" />{/if}</i
					>{backgrounds[option]}</span
				>
			{/each}
		</div>
	{/if}

	<footer class="f-footer">
		<span class="f-btn" class:off={alone}>Delete Glyph…</span>
		<span class="grow"></span>
		<span class="f-btn">Duplicate</span>
		<span class="f-btn default">Done</span>
	</footer>
</div>

<style>
	.at {
		position: absolute;
		left: 0;
		right: 0;
		margin-top: 0;
		margin-bottom: 0;
	}
	.grow {
		flex: 1;
	}
</style>
