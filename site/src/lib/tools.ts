type Slug = 'stats' | 'keys' | 'bar';

export type Tool = {
	slug: Slug;
	name: string;
	/** One line under the name. */
	tagline: string;
	/** What it does, in a sentence, for the home page and meta description. */
	summary: string;
	repo: string;
	/** Release asset with a stable name, so this link always gets the newest build. */
	asset: string;
	requires: string;
	icon: `${Slug}/icon.png`;
	/** The demo video's accessible description. */
	demo: string;
	/** The last step of getting started, after downloading and opening it. */
	firstRun: string;
};

/** Where the site is published; links shared elsewhere must be absolute. */
export const site = 'https://oddurs.github.io/common-tools/';

const github = 'https://github.com/oddurs';

export const tools: Tool[] = [
	{
		slug: 'stats',
		name: 'Common Stats',
		tagline: 'System stats for the menu bar. Small type, small graphs, nothing else.',
		summary:
			'CPU, GPU, memory, network, disk, storage, and battery in the menu bar, with a real menu of graphs under it.',
		repo: `${github}/common-stats`,
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
		repo: `${github}/common-keys`,
		asset: 'CommonKeys.zip',
		requires: 'macOS 14.4 or later · Every keyboard macOS has',
		icon: 'keys/icon.png',
		firstRun: 'Allow Accessibility access when asked, so it can see and fix what you type.',
		demo: 'Typing þetta on the U.S. layout: Common Keys fixes it and switches to Icelandic. Then привет and 안녕하세요 typed on U.S. are fixed the same way, and each app keeps its own keyboard.'
	},
	{
		slug: 'bar',
		name: 'Common Bar',
		tagline: 'A tidy menu bar. The icons you rarely use wait behind the chevron.',
		summary:
			'Tucks away the menu bar icons you rarely use. Click the chevron to show them; ⌘-drag an icon past it to hide it.',
		repo: `${github}/common-bar`,
		asset: 'CommonBar.zip',
		requires: 'macOS 14 or later · Apple silicon and Intel',
		icon: 'bar/icon.png',
		firstRun: 'Hold ⌘ and drag the icons you rarely use past the chevron.',
		demo: 'A crowded menu bar. Clicking the Common Bar chevron hides the icons to its left; hovering brings them back. Holding ⌘ shows every icon, and one is dragged past the chevron to hide it.'
	}
];

/** Apps on their way: each has a page, so every app's Settings can link to it, but no release yet. */
export type Upcoming = {
	slug: 'glyph' | 'command' | 'shot' | 'battery';
	name: string;
	tagline: string;
	summary: string;
	repo: string;
	/** Whether the repository is public yet. */
	published: boolean;
	icon: `${Upcoming['slug']}/icon.png`;
};

export const upcoming: Upcoming[] = [
	{
		slug: 'glyph',
		name: 'Common Glyph',
		tagline: 'Your own images in the menu bar.',
		summary: 'A character, a tattoo design, a sticker, an emoji, or a word: as many as you like.',
		repo: `${github}/common-glyph`,
		published: false,
		icon: 'glyph/icon.png'
	},
	{
		slug: 'command',
		name: 'Common Command',
		tagline: 'A small, fast launcher.',
		summary:
			'Press ⌥Space, type a few letters, press Return: apps, System Settings panes, files, sums, and web searches in one quiet panel.',
		repo: `${github}/common-command`,
		published: true,
		icon: 'command/icon.png'
	},
	{
		slug: 'shot',
		name: 'Common Shot',
		tagline: 'Screenshots straight to the clipboard.',
		summary:
			'Press ⇧⌘2, drag over what you want, and paste it: into a chat, a terminal, a pull request, or a document.',
		repo: `${github}/common-shot`,
		published: false,
		icon: 'shot/icon.png'
	},
	{
		slug: 'battery',
		name: 'Common Battery',
		tagline: 'The battery in the menu bar, done properly.',
		summary:
			'The level, the time left, what the battery is doing, and alerts when it runs low or reaches your charge level.',
		repo: `${github}/common-battery`,
		published: false,
		icon: 'battery/icon.png'
	}
];

export const download = (tool: Tool) => `${tool.repo}/releases/latest/download/${tool.asset}`;

export function tool(slug: string): Tool {
	const found = tools.find((t) => t.slug === slug);
	if (!found) throw new Error(`no tool '${slug}'`);
	return found;
}
