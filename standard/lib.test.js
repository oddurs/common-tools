import { describe, expect, it } from 'vitest';
import { adopt, compare, merge, owned, regions, render, settings } from './lib.js';

const app = {
	NAME: 'Common Bar',
	REPO: 'common-bar',
	ASSET: 'CommonBar',
	TARGET: 'Reasonal',
	KIT: 'BarKit',
	BUNDLE: 'com.oddurs.reasonal',
	MIN_MACOS: '14.0',
	slug: 'bar',
	description: 'Hides icons.',
	topics: ['menu-bar-manager']
};

const template = `# Title
<!-- standard:begin about -->
default about
<!-- standard:end about -->
shared middle
# standard:begin code
# standard:end code
end`;

describe('render', () => {
	it('fills placeholders and refuses unknown ones', () => {
		expect(render('{{NAME}} ({{REPO}})', app)).toBe('Common Bar (common-bar)');
		expect(() => render('{{NOPE}}', app)).toThrow(/NOPE/);
	});
});

describe('regions', () => {
	it('splits shared text from named regions, markers staying shared', () => {
		const parts = regions(template);
		expect(parts.filter((p) => 'region' in p)).toEqual([
			{ region: 'about', body: 'default about' },
			{ region: 'code', body: '' }
		]);
	});
	it('refuses unbalanced markers', () => {
		expect(() => regions('# standard:begin a\nx')).toThrow(/never closes/);
		expect(() => regions('# standard:end a')).toThrow(/without opening/);
	});
});

describe('merge', () => {
	it("keeps the app's own regions and takes everything else from the template", () => {
		const current = template
			.replace('default about', 'Our app.')
			.replace('shared middle', 'drifted middle')
			.replace('# standard:begin code\n', '# standard:begin code\nour code\n');
		expect(merge(template, current)).toBe(
			template
				.replace('default about', 'Our app.')
				.replace('# standard:begin code\n', '# standard:begin code\nour code\n')
		);
	});
	it('seeds regions a file does not have yet', () => {
		expect(merge(template, '', { code: 'seeded' })).toContain(
			'# standard:begin code\nseeded\n# standard:end code'
		);
	});
});

describe('compare', () => {
	it('ignores region contents but reports the first shared line that drifted', () => {
		const ok = template.replace('default about', 'Anything at all');
		expect(compare(template, ok)).toEqual([]);
		const [problem] = compare(template, ok.replace('shared middle', 'drifted'));
		expect(problem).toMatch(/line 5/);
		expect(problem).toMatch(/drifted/);
	});
});

describe('owned files', () => {
	it('checks the README for the shared sections in order and the latest download', () => {
		const readme = `# Common Bar\n\n[x](https://github.com/oddurs/common-bar/releases/latest/download/CommonBar.zip)\n## Install\n## Usage\n## Extra\n## Build from source\n## Development\n## Licence\n`;
		expect(owned['README.md'](readme, app)).toEqual([]);
		expect(owned['README.md'](readme.replace('## Usage\n', ''), app)[0]).toMatch(/in that order/);
		expect(
			owned['README.md'](readme, app, { 'README-development.md': '## Development\n\nshared' })[0]
		).toMatch(/standard block/);
	});
	it('checks the CHANGELOG starts with Unreleased and dates its versions', () => {
		const log =
			'# Changelog\n\n## [Unreleased]\n\n## [0.3.0] - 2026-10-16\n\n[Unreleased]: https://github.com/oddurs/common-bar/compare/v0.3.0...HEAD\n';
		expect(owned['CHANGELOG.md'](log, app)).toEqual([]);
		expect(owned['CHANGELOG.md'](log.replace(' - 2026-10-16', ''), app)[0]).toMatch(/YYYY-MM-DD/);
	});
	it('checks Package.swift agrees with Info.plist on the deployment target', () => {
		const pkg =
			'// swift-tools-version: 6.0\nlet package = Package(\n    name: "CommonBar",\n    platforms: [.macOS(.v14)],\n    targets: [.testTarget(name: "BarKitTests", dependencies: [])]\n)\n';
		expect(owned['Package.swift'](pkg, app)).toEqual([]);
		expect(owned['Package.swift'](pkg, { ...app, MIN_MACOS: '14.4' })[0]).toMatch(/14\.4/);
	});
});

it('gives every app the shared topics plus its own', () => {
	expect(settings(app).topics).toContain('common-tools');
	expect(settings(app).topics).toContain('menu-bar-manager');
	expect(settings(app).repo.homepage).toBe('https://oddurs.github.io/common-tools/bar/');
});

describe('adopt', () => {
	it("finds an app's own text in files from before the standard", () => {
		const claude =
			'# Working in this repository\n\nOur app does one thing.\n\n## The seam\n\nx\n\n## Code\n\n- Keep it small.\n';
		expect(adopt('CLAUDE.md', claude, '')).toEqual({
			about: 'Our app does one thing.',
			code: '- Keep it small.'
		});
		const contributing =
			'A bug fix comes with the test that would have caught it. Detector changes need numbers.\n\n## Review';
		expect(adopt('CONTRIBUTING.md', contributing, '').checks).toBe('Detector changes need numbers.');
		const pr = '- [ ] `scripts/task check` passes locally\n- [ ] Screenshots attached';
		expect(
			adopt('.github/PULL_REQUEST_TEMPLATE.md', pr, '- [ ] `scripts/task check` passes locally').checklist
		).toBe('- [ ] Screenshots attached');
		expect(adopt('SECURITY.md', 'Shared.\n\nIt reads the battery.\n', 'Shared.').surface).toBe(
			'It reads the battery.'
		);
	});
});
