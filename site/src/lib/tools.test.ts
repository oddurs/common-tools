import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { download, tool, tools, upcoming } from './tools';

describe('tools', () => {
	it('links each download to a stable latest-release asset', () => {
		expect(tools.map(download)).toEqual([
			'https://github.com/oddurs/common-stats/releases/latest/download/CommonStats.zip',
			'https://github.com/oddurs/common-keys/releases/latest/download/CommonKeys.zip',
			'https://github.com/oddurs/common-bar/releases/latest/download/CommonBar.zip'
		]);
	});
	it('names every app in the family exactly once', () => {
		const slugs = [...tools, ...upcoming].map((t) => t.slug);
		expect(slugs).toEqual(['stats', 'keys', 'bar', 'glyph', 'command', 'shot', 'battery']);
	});
	it('has a page for every app the apps list in their Settings, in the same order', () => {
		// Each app's "Get…" button opens common-tools/<id>/, so a missing page is a broken button.
		const swift = readFileSync('standard/app/Sources/{{TARGET}}/CommonTools.swift', 'utf8');
		const ids = [...swift.matchAll(/id: "(\w+)"/g)].map((m) => m[1]);
		expect(ids).toEqual([...tools, ...upcoming].map((t) => t.slug));
	});
	it('looks tools up by slug and refuses unknown ones', () => {
		expect(tool('keys').name).toBe('Common Keys');
		expect(() => tool('nope')).toThrow();
	});
});
