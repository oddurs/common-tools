type Slug = 'stats' | 'keys' | 'bar' | 'glyph' | 'command' | 'shot' | 'battery' | 'color';

export type Tool = {
	slug: Slug;
	name: string;
	/** One line under the name. */
	tagline: string;
	/** What it is, in the words someone searching for it would use: the page's title. */
	kind: string;
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
	/** It has its own docs pages, at `<slug>/docs/`. */
	docs?: true;
};

/** Where the site is published; links shared elsewhere must be absolute. */
export const site = 'https://oddurs.github.io/common-tools/';

/** The monorepo every app lives in. */
export const github = 'https://github.com/oddurs/common-tools';
const legacy = 'https://github.com/oddurs';

/** The Homebrew tap, github.com/oddurs/homebrew-common-tools; scripts/cask writes a cask per release. */
export const tap = 'oddurs/common-tools';

/** Every way to install an app, step by step with checksums, for apps without docs pages of their own. */
export const installGuide = `${github}/blob/main/docs/install.md`;

/** The install script the site serves (static/install.sh). */
export const installScript = `${site}install.sh`;

const anyMac = 'macOS 14 or later · Apple silicon and Intel';

/** The family, in the order every app's Settings lists it (CommonKit's `CommonTool.all`). */
export const tools: Tool[] = [
	{
		slug: 'stats',
		name: 'Common Stats',
		tagline: 'Small type. Small graphs. Nothing else.',
		kind: 'System monitor in the Mac menu bar',
		summary:
			'CPU, GPU, memory, network, disk, storage, and battery in the menu bar, with a real menu of graphs under it.',
		repo: `${github}/tree/main/apps/stats`,
		legacyRepo: `${legacy}/common-stats`,
		asset: 'CommonStats.zip',
		requires: 'macOS 14 or later · Apple silicon and Intel',
		icon: 'stats/icon.png',
		docs: true,
		firstRun: 'Pick what the menu bar shows in Settings, and turn on Open at login.',
		demo: 'Common Stats in the menu bar showing CPU, memory, and network. Its menu opens with live graphs for each, hovering a graph reads back a past value, and the item switches between values, graphs, and gauges.'
	},
	{
		slug: 'keys',
		name: 'Common Keys',
		tagline: 'Typed on the wrong keyboard? Already fixed.',
		kind: 'Keyboard layout fixer for Mac',
		summary:
			'Fixes words typed on the wrong keyboard layout, for every keyboard macOS has, and keeps each app on the language you write there.',
		repo: `${github}/tree/main/apps/keys`,
		legacyRepo: `${legacy}/common-keys`,
		asset: 'CommonKeys.zip',
		requires: 'macOS 14.4 or later · Every keyboard macOS has',
		icon: 'keys/icon.png',
		docs: true,
		permission: { name: 'Accessibility', why: 'to see what you type and fix it' },
		firstRun: 'Type a word on the wrong keyboard and press space. It’s fixed, and the layout switches.',
		demo: 'Typing þetta on the U.S. layout: Common Keys fixes it and switches to Icelandic. Then привет and 안녕하세요 typed on U.S. are fixed the same way, and each app keeps its own keyboard.'
	},
	{
		slug: 'bar',
		name: 'Common Bar',
		tagline: 'A tidy menu bar.',
		kind: 'Menu bar organizer for Mac',
		summary:
			'Moves the menu bar icons you rarely use into folders, clear of the notch, and opens any one of them right where its folder is.',
		repo: `${github}/tree/main/apps/bar`,
		legacyRepo: `${legacy}/common-bar`,
		asset: 'CommonBar.zip',
		requires: 'macOS 14 or later · Apple silicon and Intel',
		icon: 'bar/icon.png',
		docs: true,
		firstRun: 'Click the More folder and choose an icon to open it.',
		demo: 'A crowded menu bar. Common Bar moves the icons left of its More folder off the menu bar. Clicking More lists them by app, and choosing one opens it beside the folder; once its menu closes, it goes back.'
	},
	{
		slug: 'glyph',
		name: 'Common Glyph',
		tagline: 'Your own images in the menu bar.',
		kind: 'Custom menu bar icons for Mac',
		summary:
			'A character, a sticker, an emoji, an animated GIF, or a word: as many as you like, each its own menu bar item.',
		repo: `${github}/tree/main/apps/glyph`,
		asset: 'CommonGlyph.zip',
		requires: anyMac,
		icon: 'glyph/icon.png',
		firstRun: 'Choose or paste an image in Settings, pick a style, and it appears beside the clock.',
		demo: 'Common Glyph puts your own images in the menu bar: a picture, an emoji, and a word, each its own menu bar item with a small menu.'
	},
	{
		slug: 'command',
		name: 'Common Command',
		tagline: 'A small, fast launcher.',
		kind: 'Keyboard launcher for Mac',
		summary:
			'Press ⌥Space, type a few letters, press Return: apps, System Settings panes, files, sums, and web searches in one quiet panel.',
		repo: `${github}/tree/main/apps/command`,
		asset: 'CommonCommand.zip',
		requires: anyMac,
		icon: 'command/icon.png',
		firstRun:
			'Press ⌥Space, type a few letters of an app’s name, and press Return. Change the shortcut in Settings.',
		demo: 'Pressing Option-Space opens Common Command over the app in front. Typing a few letters finds an app, a System Settings pane, and a conversion, and Return opens or copies each.'
	},
	{
		slug: 'shot',
		name: 'Common Shot',
		tagline: 'Screenshots straight to the clipboard.',
		kind: 'Screenshot to clipboard for Mac',
		summary:
			'Press ⇧⌘2, drag over what you want, and paste it: into a chat, a terminal, a pull request, or a document.',
		repo: `${github}/tree/main/apps/shot`,
		asset: 'CommonShot.zip',
		requires: anyMac,
		icon: 'shot/icon.png',
		permission: { name: 'Screen Recording', why: 'to capture what you pick' },
		firstRun:
			'Press ⇧⌘2, drag over part of the screen, and paste. Click a window instead to take only that window.',
		demo: 'Pressing Shift-Command-2 freezes the screen under Common Shot’s overlay. Dragging over part of it puts that area on the clipboard, a preview slides in, and the shot is pasted into a message.'
	},
	{
		slug: 'battery',
		name: 'Common Battery',
		tagline: 'The menu bar battery, done properly.',
		kind: 'Menu bar battery monitor for Mac',
		summary:
			'The level, the time left, what the battery is doing, and alerts when it runs low or reaches your charge level.',
		repo: `${github}/tree/main/apps/battery`,
		asset: 'CommonBattery.zip',
		requires: anyMac,
		icon: 'battery/icon.png',
		firstRun:
			'Pick what the menu bar shows in Settings, where a shortcut also hides the system’s own battery icon.',
		demo: 'Common Battery in the menu bar, showing the level and the time left. Its menu opens with a charge chart and the battery’s details.'
	},
	{
		slug: 'color',
		name: 'Common Color',
		tagline: 'Pick any color. Paste it as code.',
		kind: 'Color picker for Mac',
		summary:
			'Press ⌃⇧⌘C, click any pixel, and the color is on the clipboard as hex, CSS, SwiftUI, or AppKit, converted correctly from the display’s color space.',
		repo: `${github}/tree/main/apps/color`,
		asset: 'CommonColor.zip',
		requires: anyMac,
		icon: 'color/icon.png',
		firstRun: 'Press ⌃⇧⌘C, click any pixel, and paste. Choose the format it pastes in Settings.',
		demo: 'Pressing Control-Shift-Command-C brings up the color loupe. Clicking a pixel copies its color as code, a card says what was copied, and it is pasted into a stylesheet.'
	}
];

/** The home page's order: the apps people reach for most, and the most polished, first. */
export const showcase: Slug[] = ['command', 'shot', 'stats', 'bar', 'keys', 'color', 'battery', 'glyph'];

/** Any app in the family. */
export type AppSlug = Slug;

/** An app's name and icon: what a film's closing card shows. */
export const app = (slug: AppSlug): Pick<Tool, 'name' | 'icon'> => tool(slug);

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
