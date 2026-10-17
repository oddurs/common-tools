// The design tokens' contract, checked from the site because the site has the test runner and the
// values under test are the ones the site paints with. CommonKit has its own check that its
// generated Swift matches the source.
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import { colors, entries, outputs, render, source } from '../../../../packages/common-ui/build.mjs';

const { tokens } = source();
const rendered = render();
const css = readFileSync(outputs.css, 'utf8');

/** Every .svelte and .css file the site styles itself with; the films draw a Mac, with their own values. */
function styledFiles(dir = 'src'): string[] {
	return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
		const path = join(dir, entry.name);
		if (entry.isDirectory())
			return ['film', 'mac', 'common-ui', '(demo)'].includes(entry.name) ? [] : styledFiles(path);
		return /\.(svelte|css)$/.test(entry.name) && !entry.name.endsWith('Demo.svelte') ? [path] : [];
	});
}

/** The relative luminance of #rrggbb, per WCAG 2. */
function luminance(hex: string): number {
	const channel = (i: number) => {
		const c = parseInt(hex.slice(i, i + 2), 16) / 255;
		return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
	};
	return 0.2126 * channel(1) + 0.7152 * channel(3) + 0.0722 * channel(5);
}

function contrast(fg: string, bg: string): number {
	const [a, b] = [luminance(fg), luminance(bg)].sort((x, y) => y - x);
	return (a + 0.05) / (b + 0.05);
}

describe('generated outputs', () => {
	it('are what tokens.json renders to; run `pnpm tokens` after changing it', () => {
		expect(css).toBe(rendered.css);
		expect(readFileSync(outputs.swift, 'utf8')).toBe(rendered.swift);
	});
	it('carry the hash of the source they were made from', () => {
		const { hash } = source();
		expect(css).toContain(`source sha256: ${hash}`);
		expect(rendered.swift).toContain(`sourceHash = "${hash}"`);
	});
});

describe('colour', () => {
	const all = colors(tokens);
	it('resolves every semantic colour to a palette entry or a literal in both appearances', () => {
		for (const [name, token] of Object.entries(all)) {
			expect(token.light, name).toMatch(/^#[0-9a-f]{6}([0-9a-f]{2})?$/);
			expect(token.dark, name).toMatch(/^#[0-9a-f]{6}([0-9a-f]{2})?$/);
		}
	});
	it('meets WCAG AA for every text pair the source lists, light and dark', () => {
		expect(tokens.contrast.pairs.length).toBeGreaterThan(0);
		for (const [fg, bg] of tokens.contrast.pairs) {
			for (const mode of ['light', 'dark'] as const) {
				const f = all[fg]?.[mode] ?? '';
				const b = all[bg]?.[mode] ?? '';
				// A translucent background can't be checked without knowing what's under it.
				expect(f, fg).toHaveLength(7);
				expect(b, bg).toHaveLength(7);
				expect(contrast(f, b), `${fg} on ${bg}, ${mode}`).toBeGreaterThanOrEqual(4.5);
			}
		}
	});
	it('lists every opaque text colour against every opaque surface it could sit on', () => {
		const pairs = new Set(tokens.contrast.pairs.map(([f, b]) => `${f}|${b}`));
		for (const text of ['text.primary', 'text.secondary'])
			for (const [name, token] of Object.entries(all))
				if (
					name.startsWith('surface.') &&
					token.holdsText !== false &&
					token.light.length === 7 &&
					token.dark.length === 7
				)
					expect(pairs.has(`${text}|${name}`), `${text} on ${name} is unchecked`).toBe(true);
	});
	it('names a macOS semantic colour wherever the system has one', () => {
		// Text, the window, the accent, rules, and errors are the system's; ours are the gaps.
		const system = Object.entries(all)
			.filter(([, t]) => t.macos)
			.map(([name]) => name);
		expect(system).toEqual([
			'text.primary',
			'text.secondary',
			'text.inverse',
			'surface.base',
			'color.accent',
			'color.accent-fill',
			'color.border',
			'color.focus',
			'color.danger'
		]);
	});
});

describe('scales', () => {
	it('keeps space, radius, type, and motion in increasing order', () => {
		const ascending = (values: number[]) =>
			values.every((v, i) => i === 0 || v > (values[i - 1] as number));
		expect(ascending(entries(tokens.space).map(([, v]) => v))).toBe(true);
		expect(ascending(entries(tokens.radius).map(([, v]) => v))).toBe(true);
		expect(ascending(entries(tokens.motion.duration).map(([, v]) => v))).toBe(true);
		const sizes = entries(tokens.type).map(([, step]) => step.size);
		expect(ascending([...sizes].reverse())).toBe(true);
	});
	it('gives every type step a weight and a family the tokens define', () => {
		for (const [name, step] of entries(tokens.type)) {
			expect(tokens.weight[step.weight], name).toBeDefined();
			expect(tokens.font[step.font], name).toBeDefined();
		}
	});
});

describe('the site', () => {
	const defined = new Set([...css.matchAll(/^\t+(--[\w-]+):/gm)].map((m) => m[1]));
	const files = styledFiles().map((path) => [path, readFileSync(path, 'utf8')] as const);

	it('only reads custom properties the tokens define', () => {
		for (const [path, text] of files)
			for (const [, name] of text.matchAll(/var\((--[\w-]+)/g))
				expect(defined.has(name ?? ''), `${path} reads ${name}`).toBe(true);
	});
	it('has no colour literals outside the tokens', () => {
		for (const [path, text] of files) {
			const styles = [...text.matchAll(/<style>([\s\S]*?)<\/style>/g)].map((m) => m[1]);
			const scope = path.endsWith('.css') ? text : styles.join('\n');
			expect(scope, path).not.toMatch(/#[0-9a-f]{3,8}\b|rgba?\(/i);
		}
	});
	it('breaks at the width tokens.json names', () => {
		const narrow = tokens.layout['breakpoint-narrow'];
		for (const [path, text] of files)
			for (const [, width] of text.matchAll(/@media \(max-width: (\d+)px\)/g))
				expect(Number(width), `${path} breaks at ${width}`).toBe(narrow);
	});
	it("tells Safari the page's background in both appearances", () => {
		const layout = readFileSync('src/routes/+layout.svelte', 'utf8');
		const base = colors(tokens)['surface.base'];
		expect(layout).toContain(`content="${base?.light}" media="(prefers-color-scheme: light)"`);
		expect(layout).toContain(`content="${base?.dark}" media="(prefers-color-scheme: dark)"`);
	});
});
