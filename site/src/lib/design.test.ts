import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { colors, entries, outputs, source } from '../../../packages/common-ui/build.mjs';
import { mapping, swatches } from './design.ts';

const { tokens } = source();
const swift = readFileSync(outputs.swift, 'utf8');

describe('the design page', () => {
	it('shows a swatch for every colour token, with every contrast pair it is in', () => {
		const shown = swatches(tokens);
		expect(shown.map((s) => s.name)).toEqual(Object.keys(colors(tokens)));
		const pairs = shown.flatMap((s) => s.pairs.map((p) => `${p.fg}|${p.bg}`));
		for (const [fg, bg] of tokens.contrast.pairs) expect(pairs).toContain(`${fg}|${bg}`);
	});
	it('names what the apps use: the system colour, or the values Tokens.swift defines', () => {
		const card = swatches(tokens).find((s) => s.name === 'surface.card');
		expect(card?.macos).toEqual({
			light: tokens.surface.card?.macosLight,
			dark: tokens.surface.card?.macosDark
		});
		expect(swatches(tokens).find((s) => s.name === 'text.primary')?.macos).toEqual({
			system: 'labelColor'
		});
		for (const s of swatches(tokens)) expect(swift, s.swift).toContain(s.swift.split('.').at(-1));
	});
	it('maps every colour, text style, and scale between the apps and the site', () => {
		const rows = mapping(tokens, swift).map((r) => r.token);
		for (const name of Object.keys(colors(tokens))) expect(rows).toContain(name);
		for (const [name] of entries(tokens.type)) expect(rows).toContain(`type.${name}`);
		const site = readFileSync(outputs.css, 'utf8');
		for (const row of mapping(tokens, swift))
			for (const prefix of row.site.matchAll(/--([\w-]+)-\*/g))
				expect(site, row.token).toContain(`--${prefix[1]}-`);
	});
	it('says the apps have no tokens for what only the site uses', () => {
		const rows = Object.fromEntries(mapping(tokens, swift).map((r) => [r.token, r.apps]));
		expect(rows['elevation.*']).toBe('none');
		expect(rows['layer.*']).toBe('none');
		expect(rows['space.*']).toBe('Tokens.Space');
	});
});
