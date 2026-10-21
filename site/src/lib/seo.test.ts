// What search engines and link previews see: titles and descriptions that aren't cut off, a card for
// every page at the size the tags declare, structured data, and a sitemap of the pages people read.
import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { pages } from './pages';
import {
	appSchema,
	card,
	description,
	docsDescription,
	homeDescription,
	homeTitle,
	sitemap,
	title
} from './seo';
import { site, tool, tools } from './tools';

/** A JPEG's pixel size, from its start-of-frame marker. */
function jpegSize(path: string) {
	const bytes = readFileSync(path);
	for (let at = 2; at < bytes.length; at += 2 + bytes.readUInt16BE(at + 2))
		if (bytes[at + 1] >= 0xc0 && bytes[at + 1] <= 0xc2)
			return { width: bytes.readUInt16BE(at + 7), height: bytes.readUInt16BE(at + 5) };
	throw new Error(`${path} has no frame`);
}

describe('search results', () => {
	it('keeps every title to 60 characters and every description to 160, where Google cuts them', () => {
		expect(homeTitle.length).toBeLessThanOrEqual(60);
		expect(homeDescription.length).toBeLessThanOrEqual(160);
		for (const t of tools) {
			expect(title(t).length, t.slug).toBeLessThanOrEqual(60);
			expect(description(t).length, t.slug).toBeLessThanOrEqual(160);
			expect(docsDescription(t).length, t.slug).toBeLessThanOrEqual(160);
		}
	});
	it('says what each app is and that it is for the Mac', () => {
		for (const t of tools) expect(title(t), t.slug).toMatch(/Mac/);
		expect(docsDescription(tool('stats'))).toBe(
			'How to install, set up, and use Common Stats, the system monitor in the Mac menu bar.'
		);
	});
});

describe('cards', () => {
	it('exist for the home page and every app at the size the tags declare; run `pnpm film cards`', () => {
		for (const c of [card(), ...tools.map(card)])
			expect(jpegSize(`static/${c.image}`), c.image).toEqual({ width: c.width, height: c.height });
	});
	it('pick one of the app’s own stills', () => {
		for (const [slug, page] of Object.entries(pages))
			expect(page!.card ?? 1, slug).toBeLessThanOrEqual(page!.features.length);
	});
});

describe('structured data', () => {
	it('describes an app as a free macOS utility, with its release when the build found one', () => {
		const keys = appSchema(tool('keys'), {
			version: '0.3.0',
			date: '2026-10-20',
			size: 1,
			download: 'https://example.com/CommonKeys.zip',
			url: '',
			notes: []
		});
		expect(keys).toMatchObject({
			'@type': 'SoftwareApplication',
			url: `${site}keys/`,
			operatingSystem: 'macOS 14.4 or later',
			applicationCategory: 'UtilitiesApplication',
			offers: { price: '0' },
			softwareVersion: '0.3.0',
			downloadUrl: 'https://example.com/CommonKeys.zip'
		});
		expect(appSchema(tool('keys'))).not.toHaveProperty('softwareVersion');
	});
});

describe('sitemap', () => {
	it('lists the home page, every app, its docs, and nothing made for the site’s own use', () => {
		expect(sitemap[0]).toBe(site);
		for (const t of tools) expect(sitemap).toContain(`${site}${t.slug}/`);
		expect(sitemap).toContain(`${site}stats/docs/`);
		expect(sitemap.filter((url) => /\/(demo|card)\//.test(url))).toEqual([]);
	});
});
