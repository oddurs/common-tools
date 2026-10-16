import { describe, expect, it } from 'vitest';
import { download, tool, tools } from './tools';

describe('tools', () => {
	it('links each download to a stable latest-release asset', () => {
		expect(tools.map(download)).toEqual([
			'https://github.com/oddurs/common-stats/releases/latest/download/CommonStats.zip',
			'https://github.com/oddurs/common-keys/releases/latest/download/CommonKeys.zip',
			'https://github.com/oddurs/common-bar/releases/latest/download/CommonBar.zip'
		]);
	});
	it('looks tools up by slug and refuses unknown ones', () => {
		expect(tool('keys').name).toBe('Common Keys');
		expect(() => tool('nope')).toThrow();
	});
});
