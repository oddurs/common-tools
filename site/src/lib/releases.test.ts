import { describe, expect, it } from 'vitest';
import { changelogNotes, inlineMarkdown, latestRelease, megabytes, shortDate } from './releases';
import { tool } from './tools';

const changelog = `# Changelog

## [Unreleased]

### Added

- Not shipped yet.

## [0.3.0] - 2026-10-16

### Changed

- Settings follows the shared layout: **Items**, then
  **General**.

### Added

- A \`Common Tools\` section.

### Fixed

## [0.2.1] - 2026-10-16

### Changed

- New icon.
`;

describe('changelogNotes', () => {
	it('reads one version, joining wrapped bullets and dropping empty sections', () => {
		expect(changelogNotes(changelog, '0.3.0')).toEqual([
			{
				heading: 'Changed',
				items: ['Settings follows the shared layout: **Items**, then **General**.']
			},
			{ heading: 'Added', items: ['A `Common Tools` section.'] }
		]);
	});
	it('stops at the next version and finds nothing for a missing one', () => {
		expect(changelogNotes(changelog, '0.2.1')).toEqual([{ heading: 'Changed', items: ['New icon.'] }]);
		expect(changelogNotes(changelog, '9.9.9')).toEqual([]);
	});
});

describe('inlineMarkdown', () => {
	it('renders bold, code, and https links, and escapes everything else', () => {
		expect(inlineMarkdown('**Open** `at` [login](https://example.com) <script>')).toBe(
			'<b>Open</b> <code>at</code> <a href="https://example.com">login</a> &lt;script&gt;'
		);
	});
	it('leaves links that are not https as text', () => {
		expect(inlineMarkdown('[x](javascript:alert(1))')).toBe('[x](javascript:alert(1))');
	});
});

describe('latestRelease', () => {
	const stats = tool('stats');
	const respond = (body: unknown, ok = true) =>
		({
			ok,
			status: ok ? 200 : 403,
			json: async () => body,
			text: async () => body
		}) as unknown as Response;
	const release = (tag: string, name: string) => ({
		tag_name: tag,
		published_at: '2026-10-16T07:51:46Z',
		html_url: `https://github.com/x/releases/tag/${tag}`,
		draft: false,
		prerelease: false,
		assets: [
			{
				name,
				size: 1_688_975,
				browser_download_url: `https://github.com/x/releases/download/${tag}/${name}`
			}
		]
	});

	it('takes the newest monorepo release tagged for the app', async () => {
		const fake = (async (url: string) =>
			url.includes('common-tools/releases')
				? respond([
						release('bar-v0.4.0', 'CommonBar.zip'),
						release('stats-v0.4.0', 'CommonStats.zip'),
						release('stats-v0.3.5', 'CommonStats.zip')
					])
				: respond(changelog.replace('0.3.0', '0.4.0'))) as typeof fetch;
		const found = await latestRelease(stats, fake);
		expect(found).toMatchObject({ version: '0.4.0', date: '2026-10-16', size: 1_688_975 });
		expect(found?.download).toMatch(/stats-v0\.4\.0\/CommonStats\.zip$/);
		expect(found?.notes.map((n) => n.heading)).toEqual(['Changed', 'Added']);
	});

	it('falls back to the old repository before the first monorepo release', async () => {
		const fake = (async (url: string) =>
			url.includes('common-tools/releases')
				? respond([release('bar-v0.4.0', 'CommonBar.zip')])
				: url.includes('common-stats/releases')
					? respond([release('v0.3.0', 'CommonStats.zip')])
					: respond(changelog)) as typeof fetch;
		const found = await latestRelease(stats, fake);
		expect(found?.version).toBe('0.3.0');
		expect(found?.download).toMatch(/v0\.3\.0\/CommonStats\.zip$/);
	});

	it('gives null rather than failing the build when GitHub refuses', async () => {
		const refused = (async () => respond({}, false)) as typeof fetch;
		expect(await latestRelease(stats, refused)).toBeNull();
	});
});

it('formats sizes and dates for people', () => {
	expect(megabytes(1_688_975)).toBe('1.7 MB');
	expect(shortDate('2026-10-16')).toBe('Oct 16, 2026');
});
