import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { brewLine, cask, curlLine, download, github, releasesOf, showcase, tool, tools } from './tools';

describe('tools', () => {
	it('links each download to the latest release, falling back to the old repository', () => {
		const stats = tool('stats');
		expect(
			download(stats, {
				download:
					'https://github.com/oddurs/common-tools/releases/download/stats-v0.4.0/CommonStats.zip'
			})
		).toBe('https://github.com/oddurs/common-tools/releases/download/stats-v0.4.0/CommonStats.zip');
		expect(download(stats)).toBe(
			'https://github.com/oddurs/common-stats/releases/latest/download/CommonStats.zip'
		);
		expect(download({ ...stats, legacyRepo: undefined })).toBe(releasesOf(stats));
		expect(releasesOf(stats)).toBe(`${github}/releases?q=stats-v`);
	});
	it('names every app in the family exactly once, where it lives in the monorepo', () => {
		expect(tools.map((t) => t.slug)).toEqual([
			'stats',
			'keys',
			'bar',
			'glyph',
			'command',
			'shot',
			'battery',
			'color'
		]);
		for (const t of tools) expect(t.repo).toBe(`${github}/tree/main/apps/${t.slug}`);
	});
	it('has a page for every app the apps list in their Settings, in the same order', () => {
		// Each app's "Get…" button opens common-tools/<id>/, so a missing page is a broken button.
		const swift = readFileSync('../packages/CommonKit/Sources/CommonKit/CommonTool.swift', 'utf8');
		const ids = [...swift.matchAll(/id: "(\w+)"/g)].map((m) => m[1]);
		expect(ids).toEqual(tools.map((t) => t.slug));
	});
	it('agrees with apps.json on names and assets', () => {
		const apps = JSON.parse(readFileSync('../apps.json', 'utf8')) as Record<
			string,
			{ NAME: string; ASSET: string }
		>;
		for (const t of tools) {
			expect(apps[t.slug].NAME).toBe(t.name);
			expect(apps[t.slug].ASSET).toBe(t.asset.replace(/\.zip$/, ''));
		}
	});
	it('writes the terminal install lines', () => {
		const bar = tool('bar');
		expect(cask(bar)).toBe('common-bar');
		expect(brewLine(bar)).toBe('brew install --cask oddurs/common-tools/common-bar');
		expect(curlLine(bar)).toBe(
			'curl -fsSL https://oddurs.github.io/common-tools/install.sh | sh -s -- bar'
		);
	});
	it('agrees with the install script on every released app', () => {
		// static/install.sh carries its own table: slug | name | asset | old repository | permission.
		const script = readFileSync('static/install.sh', 'utf8');
		const table =
			script
				.match(/^apps='([^']*)'/m)?.[1]
				.trim()
				.split('\n') ?? [];
		expect(table).toEqual(
			tools.map((t) =>
				[
					t.slug,
					t.name,
					t.asset.replace(/\.zip$/, ''),
					t.legacyRepo?.replace('https://github.com/oddurs/', '') ?? '',
					t.permission?.name ?? ''
				].join('|')
			)
		);
	});
	it('shows every app on the home page exactly once', () => {
		expect([...showcase].sort()).toEqual(tools.map((t) => t.slug).sort());
	});
	it('says which apps have docs pages, so no page links to one that is missing', () => {
		expect(tools.filter((t) => t.docs).map((t) => t.slug)).toEqual(['stats', 'keys', 'bar']);
	});
	it('looks tools up by slug and refuses unknown ones', () => {
		expect(tool('keys').name).toBe('Common Keys');
		expect(() => tool('nope')).toThrow();
	});
});
