<script lang="ts">
	// The film's picture: Mochi, a cat drawn for the film, sitting in a room. The whole picture is
	// what the user drops in; with the subject lifted, Common Glyph keeps the cat and trims to it
	// (Vision's lift of this very drawing leaves the cat and drops its shadow); as a silhouette, the
	// cat's shape is drawn in the menu bar's ink, the way a template image is.
	let { mode, width, height }: { mode: 'photo' | 'subject' | 'silhouette'; width: number; height: number } =
		$props();

	const id = $props.id();
	/** The cat's own box: ear tips to paws, body to tail tip. */
	const viewBox = $derived(mode === 'photo' ? '0 0 800 600' : '268 118 336 456');
	const ink = $derived(mode === 'silhouette');
	const fur = $derived(ink ? 'currentColor' : `url(#${id}-fur)`);
	const fill = (color: string) => (ink ? 'currentColor' : color);
</script>

<svg {width} {height} {viewBox} aria-hidden="true">
	<defs>
		<linearGradient id="{id}-wall" x1="0" y1="0" x2="0" y2="1">
			<stop offset="0" stop-color="#cfe8e1" />
			<stop offset="1" stop-color="#a9d3c9" />
		</linearGradient>
		<linearGradient id="{id}-sky" x1="0" y1="0" x2="0" y2="1">
			<stop offset="0" stop-color="#8fc6f2" />
			<stop offset="1" stop-color="#d9eefc" />
		</linearGradient>
		<linearGradient id="{id}-floor" x1="0" y1="0" x2="0" y2="1">
			<stop offset="0" stop-color="#d9a877" />
			<stop offset="1" stop-color="#b98455" />
		</linearGradient>
		<radialGradient id="{id}-fur" cx="0.4" cy="0.35" r="0.75">
			<stop offset="0" stop-color="#ffc37f" />
			<stop offset="1" stop-color="#ec9446" />
		</radialGradient>
	</defs>
	{#if mode === 'photo'}
		<rect width="800" height="600" fill="url(#{id}-wall)" />
		<rect x="470" y="40" width="270" height="300" rx="10" fill="#f7f3ea" />
		<rect x="488" y="58" width="234" height="264" rx="4" fill="url(#{id}-sky)" />
		<circle cx="660" cy="118" r="28" fill="#fff4c9" />
		<path d="M488 260 q50 -40 100 -8 q40 -30 90 -6 q30 -10 44 4 v72 h-234z" fill="#cde7c0" />
		<rect x="601" y="58" width="8" height="264" fill="#f7f3ea" />
		<rect x="488" y="186" width="234" height="8" fill="#f7f3ea" />
		<rect x="0" y="500" width="800" height="100" fill="url(#{id}-floor)" />
		<rect x="0" y="500" width="800" height="6" fill="#c58f5d" />
		<path d="M96 500 l14 -92 h88 l14 92z" fill="#d7775a" />
		<rect x="104" y="396" width="100" height="18" rx="4" fill="#c4664b" />
		<path d="M154 398 c-10 -60 -60 -90 -92 -96 c22 30 40 66 86 96z" fill="#5f9e62" />
		<path d="M154 398 c4 -80 40 -130 70 -146 c-6 46 -22 104 -64 146z" fill="#6fb06f" />
		<path d="M154 398 c-30 -50 -26 -120 -10 -160 c18 40 28 110 14 160z" fill="#7cbd78" />
		<ellipse cx="410" cy="560" rx="150" ry="16" fill="#9b6a40" opacity="0.45" />
	{/if}
	<path
		d="M512 520 c70 -6 92 -60 78 -104 c-8 -26 -30 -34 -40 -22 c-8 10 4 18 12 30 c12 22 -2 60 -56 64z"
		fill={fill('#ec9446')}
	/>
	<path
		d="M400 300 c-80 0 -130 70 -130 150 c0 60 30 106 80 112 h100 c50 -6 80 -52 80 -112 c0 -80 -50 -150 -130 -150z"
		fill={fur}
	/>
	{#if !ink}
		<path
			d="M400 380 c-40 0 -62 40 -62 84 c0 44 24 88 62 88 c38 0 62 -44 62 -88 c0 -44 -22 -84 -62 -84z"
			fill="#fde7cc"
		/>
	{/if}
	<ellipse cx="362" cy="556" rx="30" ry="18" fill={fill('#ffd2a3')} />
	<ellipse cx="438" cy="556" rx="30" ry="18" fill={fill('#ffd2a3')} />
	<path d="M300 222 l18 -98 c2 -10 12 -12 18 -4 l62 74z" fill={fill('#ec9446')} />
	<path d="M500 222 l-18 -98 c-2 -10 -12 -12 -18 -4 l-62 74z" fill={fill('#ec9446')} />
	{#if !ink}
		<path d="M318 196 l10 -56 l38 46z" fill="#ffb3a7" />
		<path d="M482 196 l-10 -56 l-38 46z" fill="#ffb3a7" />
	{/if}
	<ellipse cx="400" cy="262" rx="118" ry="100" fill={fur} />
	{#if !ink}
		<path d="M372 166 q28 18 56 0 q-6 24 -28 28 q-22 -4 -28 -28z" fill="#d97c34" />
		<path
			d="M286 250 h30 M286 270 h26 M514 250 h-30 M514 270 h-26"
			stroke="#d97c34"
			stroke-width="8"
			stroke-linecap="round"
		/>
		<ellipse cx="354" cy="262" rx="17" ry="21" fill="#2a2320" />
		<ellipse cx="446" cy="262" rx="17" ry="21" fill="#2a2320" />
		<circle cx="360" cy="254" r="6" fill="#fff" />
		<circle cx="452" cy="254" r="6" fill="#fff" />
		<ellipse cx="330" cy="300" rx="18" ry="10" fill="#ff9c8f" opacity="0.6" />
		<ellipse cx="470" cy="300" rx="18" ry="10" fill="#ff9c8f" opacity="0.6" />
		<path d="M392 290 h16 l-8 9z" fill="#e8706a" />
		<path
			d="M400 299 q-8 12 -18 6 M400 299 q8 12 18 6"
			stroke="#2a2320"
			stroke-width="4"
			fill="none"
			stroke-linecap="round"
		/>
	{/if}
</svg>

<style>
	svg {
		display: block;
		flex: none;
	}
</style>
