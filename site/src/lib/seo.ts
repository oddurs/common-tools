// What search engines and link previews read about each page: titles in the words people search
// with, descriptions short enough not to be cut, the card shown when a page is shared, the
// structured data that says an app page is a free Mac app, and the sitemap.

import type { Release } from './releases';
import { github, site, tools, type Tool } from './tools';

/** Where a result's description is cut off. */
const descriptionLimit = 160;

export const homeTitle = 'Common Tools — small, native utilities for the Mac';
export const homeDescription =
	'Eight small, native Mac apps: a launcher, a screenshot tool, a system monitor, a menu bar organizer, a color picker, and more. Free and open source.';

export const title = (tool: Tool) => `${tool.name} — ${tool.kind}`;

/** The summary, and that it's free when that still fits. */
export function description(tool: Tool) {
	const free = `${tool.summary} Free and open source.`;
	return free.length <= descriptionLimit ? free : tool.summary;
}

export const docsDescription = (tool: Tool) =>
	`How to install, set up, and use ${tool.name}, the ${tool.kind[0].toLowerCase()}${tool.kind.slice(1)}.`;

/** The card `pnpm film cards` draws: the home page's, or an app's. */
export const card = (tool?: Tool) => ({
	image: tool ? `${tool.slug}/card.jpg` : 'card.jpg',
	alt: tool ? `${tool.name}: ${tool.tagline}` : `${homeTitle}.`,
	width: 2400,
	height: 1260
});

const author = { '@type': 'Person', name: 'Oddur Sigurdsson', url: 'https://github.com/oddurs' };

export const siteSchema = {
	'@context': 'https://schema.org',
	'@type': 'WebSite',
	name: 'Common Tools',
	url: site,
	description: homeDescription,
	author
};

/** An app page's schema.org description: a free macOS utility, and its latest release when built. */
export const appSchema = (tool: Tool, release?: Release) => ({
	'@context': 'https://schema.org',
	'@type': 'SoftwareApplication',
	name: tool.name,
	description: tool.summary,
	url: new URL(`${tool.slug}/`, site).href,
	image: new URL(tool.icon, site).href,
	screenshot: new URL(card(tool).image, site).href,
	applicationCategory: 'UtilitiesApplication',
	operatingSystem: tool.requires.split(' · ')[0],
	offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
	isAccessibleForFree: true,
	license: `${github}/blob/main/LICENSE`,
	author,
	...(release && { softwareVersion: release.version, downloadUrl: release.download })
});

/** Every page worth finding, for sitemap.xml; the films and cards are for the site's own use. */
export const sitemap = [
	'',
	...tools.flatMap((t) => [`${t.slug}/`, ...(t.docs ? [`${t.slug}/docs/`] : [])]),
	'design/'
].map((path) => new URL(path, site).href);
