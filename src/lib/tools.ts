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
};

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
		demo: 'Common Stats in the menu bar showing CPU, memory, and network. Its menu opens with live graphs for each, and hovering a graph reads back a past value.'
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
		demo: 'Typing þetta on the U.S. layout: Common Keys fixes it and switches to Icelandic. Then привет and 안녕하세요 typed on U.S. are fixed the same way, and each app keeps its own keyboard.'
	},
	{
		slug: 'bar',
		name: 'Common Bar',
		tagline: 'A tidy menu bar. Hide what you rarely use behind one line.',
		summary:
			'Tucks menu bar icons behind an invisible divider. Click the chevron to show them, hold ⌘ to rearrange.',
		repo: `${github}/common-bar`,
		asset: 'CommonBar.zip',
		requires: 'macOS 14 or later · Apple silicon and Intel',
		icon: 'bar/icon.png',
		demo: 'A crowded menu bar. Clicking the Common Bar chevron hides the icons left of the divider; clicking again brings them back. Holding ⌘ shows the divider, and an icon is dragged past it to hide it.'
	}
];

export const download = (tool: Tool) => `${tool.repo}/releases/latest/download/${tool.asset}`;

export function tool(slug: string): Tool {
	const found = tools.find((t) => t.slug === slug);
	if (!found) throw new Error(`no tool '${slug}'`);
	return found;
}
