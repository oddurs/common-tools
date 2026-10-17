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
			{ heading: 'Changed', items: ['Settings follows the shared layout: **Items**, then **General**.'] },
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
		({ ok, status: ok ? 200 : 403, json: async () => body, text: async () => body }) as unknown as Response;

	it('combines the release and its changelog section', async () => {
		const fake = (async (url: string) =>
			url.includes('/releases/latest')
				? respond({
						tag_name: 'v0.3.0',
						published_at: '2026-10-16T07:51:46Z',
						assets: [{ name: 'CommonStats.zip', size: 1_688_975 }]
					})
				: respond(changelog)) as typeof fetch;
		const release = await latestRelease(stats, fake);
		expect(release).toMatchObject({ version: '0.3.0', date: '2026-10-16', size: 1_688_975 });
		expect(release?.notes.map((n) => n.heading)).toEqual(['Changed', 'Added']);
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
