<script lang="ts">
	// What the menu bar item opens (ShotsPanel in CommonUI's MenuPanelHost): Take Screenshot with its
	// shortcut, the history in a card per day as a grid of thumbnails, then the folder, Settings and
	// Quit. Metrics are CommonUI's: a 320-point column with 8 points of padding, 12-point cards, tiles
	// at 16:10 with their time, the app's icon, and the size and token cost under them.
	import Symbol from '../mac/Symbol.svelte';
	import Picture from './Picture.svelte';
	import { selection } from './demo';
	import { subtitle } from './size';

	let {
		x,
		y,
		opacity,
		hover,
		dark
	}: { x: number; y: number; opacity: number; hover: number | null; dark: boolean } = $props();

	type Kind = 'code' | 'terminal' | 'chat' | 'screen' | 'log';
	type Tile = { kind: Kind; when: string; app: 'editor' | 'terminal' | 'chat'; size: [number, number] };
	const shotSize: [number, number] = [selection.width * 2, selection.height * 2];
	const groups: { title: string; tiles: Tile[] }[] = [
		{
			title: 'Today',
			tiles: [
				{ kind: 'code', when: '9:41 AM', app: 'editor', size: shotSize },
				{ kind: 'terminal', when: '9:26 AM', app: 'terminal', size: [1280, 800] },
				{ kind: 'chat', when: '8:52 AM', app: 'chat', size: [1360, 1320] }
			]
		},
		{
			title: 'Yesterday',
			tiles: [
				{ kind: 'screen', when: '5:14 PM', app: 'editor', size: [3456, 2160] },
				{ kind: 'log', when: '2:03 PM', app: 'terminal', size: [900, 300] }
			]
		}
	];
	// The code shot letterboxed in a 140-point tile, as `ThumbnailTile` fits it, never cropped.
	const codeThumb = { width: 140, height: (140 * selection.height) / selection.width };
	const offsets = groups.map((_, g) => groups.slice(0, g).reduce((n, group) => n + group.tiles.length, 0));
</script>

<div class="shot-panel" style:left="{x}px" style:top="{y}px" style:opacity>
	<div class="row">
		<span class="icon"><Symbol name="camera.viewfinder" scale={0.82} /></span><span>Take Screenshot</span
		><kbd>⇧⌘2</kbd>
	</div>
	{#each groups as group, g (group.title)}
		<section class="group">
			<header>
				<b>{group.title}</b><span>{group.tiles.length} shots</span>
			</header>
			<div class="grid">
				{#each group.tiles as tile, i (tile.when)}
					<figure class="tile" class:hover={hover === offsets[g] + i}>
						<div class="media {tile.kind}">
							{#if tile.kind === 'code'}
								<Picture
									{dark}
									rect={selection}
									width={codeThumb.width}
									height={codeThumb.height}
								/>
							{:else if tile.kind === 'terminal' || tile.kind === 'log'}
								<div class="term">
									{#each tile.kind === 'log' ? [9, 7, 12] : [14, 9, 11, 6, 15, 4] as w, l (l)}
										<i style:width="{w * 7}px"></i>
									{/each}
								</div>
							{:else if tile.kind === 'chat'}
								<div class="mini-chat">
									<i class="bubble"></i><i class="bubble mine"></i><i class="bubble"></i><i
										class="field"
									></i>
								</div>
							{:else}
								<div class="mini-screen">
									<i class="w1"></i><i class="w2"></i>
								</div>
							{/if}
						</div>
						<figcaption>
							<span class="title"><i class="app {tile.app}"></i>{tile.when}</span>
							<span class="sub">{subtitle(...tile.size)}</span>
						</figcaption>
					</figure>
				{/each}
			</div>
		</section>
	{/each}
	<hr />
	<div class="row"><span class="icon"><Symbol name="folder" /></span><span>Open History Folder</span></div>
	<div class="row">
		<span class="icon"><Symbol name="gearshape" /></span><span>Settings…</span><kbd>⌘,</kbd>
	</div>
	<div class="row">
		<span class="icon"><Symbol name="power" /></span><span>Quit Common Shot</span><kbd>⌘Q</kbd>
	</div>
</div>
