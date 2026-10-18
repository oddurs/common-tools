type Slug = 'stats' | 'keys' | 'bar';

export type Tool = {
	slug: Slug;
	name: string;
	/** One line under the name. */
	tagline: string;
	/** What it does, in a sentence, for the home page and meta description. */
	summary: string;
	/** The app's folder in the monorepo. */
	repo: string;
	/** Where the app lived before the monorepo; its releases serve the download until the first one here. */
	legacyRepo?: string;
	/** The release asset's name, the same in every release. */
	asset: string;
	requires: string;
	icon: `${Slug}/icon.png`;
	/** The demo video's accessible description. */
	demo: string;
	/** The privacy permission it can't work without, and why, finishing "needs … access …". */
	permission?: { name: 'Accessibility' | 'Screen Recording'; why: string };
	/** The last step of getting started, after downloading, opening, and allowing it. */
	firstRun: string;
};

/** Where the site is published; links shared elsewhere must be absolute. */
export const site = 'https://oddurs.github.io/common-tools/';

/** The monorepo every app lives in. */
export const github = 'https://github.com/oddurs/common-tools';
const legacy = 'https://github.com/oddurs';

/** The Homebrew tap, github.com/oddurs/homebrew-common-tools; scripts/cask writes a cask per release. */
export const tap = 'oddurs/common-tools';

/** The install script the site serves (static/install.sh). */
export const installScript = `${site}install.sh`;

export const tools: Tool[] = [
	{
		slug: 'stats',
		name: 'Common Stats',
		tagline: 'System stats for the menu bar. Small type, small graphs, nothing else.',
		summary:
			'CPU, GPU, memory, network, disk, storage, and battery in the menu bar, with a real menu of graphs under it.',
		repo: `${github}/tree/main/apps/stats`,
		legacyRepo: `${legacy}/common-stats`,
		asset: 'CommonStats.zip',
		requires: 'macOS 14 or later · Apple silicon and Intel',
		icon: 'stats/icon.png',
		firstRun: 'Pick what the menu bar shows in Settings, and turn on Open at login.',
		demo: 'Common Stats in the menu bar showing CPU, memory, and network. Its menu opens with live graphs for each, hovering a graph reads back a past value, and the item switches between values, graphs, and gauges.'
	},
	{
		slug: 'keys',
		name: 'Common Keys',
		tagline: "Typed it on the wrong keyboard? It's already fixed.",
		summary:
			'Fixes words typed on the wrong keyboard layout, for every keyboard macOS has, and keeps each app on the language you write there.',
		repo: `${github}/tree/main/apps/keys`,
		legacyRepo: `${legacy}/common-keys`,
		asset: 'CommonKeys.zip',
		requires: 'macOS 14.4 or later · Every keyboard macOS has',
		icon: 'keys/icon.png',
		permission: { name: 'Accessibility', why: 'to see what you type and fix it' },
		firstRun: 'Type a word on the wrong keyboard and press space. It’s fixed, and the layout switches.',
		demo: 'Typing þetta on the U.S. layout: Common Keys fixes it and switches to Icelandic. Then привет and 안녕하세요 typed on U.S. are fixed the same way, and each app keeps its own keyboard.'
	},
	{
		slug: 'bar',
		name: 'Common Bar',
		tagline: 'A tidy menu bar. The icons you rarely use wait in folders.',
		summary:
			'Keeps the menu bar icons you rarely use in folders, off the menu bar and clear of the notch. Click a folder and choose one, and it opens right there.',
		repo: `${github}/tree/main/apps/bar`,
		legacyRepo: `${legacy}/common-bar`,
		asset: 'CommonBar.zip',
		requires: 'macOS 14 or later · Apple silicon and Intel',
		icon: 'bar/icon.png',
		firstRun: 'Click the More folder and choose an icon to open it.',
		demo: 'A crowded menu bar. Common Bar moves the icons left of its More folder off the menu bar. Clicking More lists them by app, and choosing one opens it beside the folder; once its menu closes, it goes back.'
	}
];

/** Apps on their way: each has a page, so every app's Settings can link to it, but no release yet. */
export type Upcoming = {
	slug: 'glyph' | 'command' | 'shot' | 'battery' | 'color';
	name: string;
	tagline: string;
	summary: string;
	repo: string;
	icon: `${Upcoming['slug']}/icon.png`;
	/** What it will ask macOS for, or that it asks for nothing, and why. */
	access?: string;
};

export const upcoming: Upcoming[] = [
	{
		slug: 'glyph',
		name: 'Common Glyph',
		tagline: 'Your own images in the menu bar.',
		summary: 'A character, a tattoo design, a sticker, an emoji, or a word: as many as you like.',
		repo: `${github}/tree/main/apps/glyph`,
		icon: 'glyph/icon.png'
	},
	{
		slug: 'command',
		name: 'Common Command',
		tagline: 'A small, fast launcher.',
		summary:
			'Press ⌥Space, type a few letters, press Return: apps, System Settings panes, files, sums, and web searches in one quiet panel.',
		repo: `${github}/tree/main/apps/command`,
		icon: 'command/icon.png'
	},
	{
		slug: 'shot',
		name: 'Common Shot',
		tagline: 'Screenshots straight to the clipboard.',
		summary:
			'Press ⇧⌘2, drag over what you want, and paste it: into a chat, a terminal, a pull request, or a document.',
		repo: `${github}/tree/main/apps/shot`,
		icon: 'shot/icon.png'
	},
	{
		slug: 'battery',
		name: 'Common Battery',
		tagline: 'The battery in the menu bar, done properly.',
		summary:
			'The level, the time left, what the battery is doing, and alerts when it runs low or reaches your charge level.',
		repo: `${github}/tree/main/apps/battery`,
		icon: 'battery/icon.png'
	},
	{
		slug: 'color',
		name: 'Common Color',
		tagline: 'Pick a color from anywhere, paste it as code.',
		summary:
			'Press ⌃⇧⌘C, click any pixel on any screen, and the color is on the clipboard as hex, CSS, SwiftUI, or AppKit, converted correctly from the display’s color space.',
		repo: `${github}/tree/main/apps/color`,
		icon: 'color/icon.png',
		access: 'It needs no permission: macOS’s own color sampler reads the one pixel you click, so the app never sees your screen.'
	}
];

/** Every release of one app, on GitHub. */
export const releasesOf = (tool: { slug: string }) => `${github}/releases?q=${tool.slug}-v`;

/**
 * The app's download: the latest release's asset when the build found it, else the old repository's
 * latest release for apps released before the move, else the release list.
 */
export const download = (tool: Tool, release?: { download: string } | null) =>
	release?.download ??
	(tool.legacyRepo ? `${tool.legacyRepo}/releases/latest/download/${tool.asset}` : releasesOf(tool));

/** The app's Homebrew cask token: "Common Bar" is `common-bar`. */
export const cask = (tool: { name: string }) => tool.name.toLowerCase().replace(/ /g, '-');

/** The Homebrew install line. */
export const brewLine = (tool: Tool) => `brew install --cask ${tap}/${cask(tool)}`;

/** The one-line install. */
export const curlLine = (tool: Tool) => `curl -fsSL ${installScript} | sh -s -- ${tool.slug}`;

export function tool(slug: string): Tool {
	const found = tools.find((t) => t.slug === slug);
	if (!found) throw new Error(`no tool '${slug}'`);
	return found;
}
