// What the design page shows, derived from packages/common-ui/tokens.json and the outputs build.mjs
// writes from it, so the page changes when the tokens do and can't say anything they don't.
import { colors, entries, type Tokens } from '../../../packages/common-ui/build.mjs';
import { contrast } from './common-ui/contrast.ts';

const camel = (name: string) => name.replace(/-(\w)/g, (_, c: string) => c.toUpperCase());
const title = (name: string) => name.charAt(0).toUpperCase() + camel(name.slice(1));

export type Pair = { fg: string; bg: string; light: number; dark: number };

export type Swatch = {
	/** `text.primary` */
	name: string;
	/** `--text-primary` */
	css: string;
	/** `Tokens.Text.primary` */
	swift: string;
	about: string;
	light: string;
	dark: string;
	/** The NSColor the apps use, or, where macOS has none, the values Tokens.swift defines. */
	macos: { system: string } | { light: string; dark: string };
	/** Every contrast pair the token is in, with its ratio in each appearance. */
	pairs: Pair[];
};

export function swatches(tokens: Tokens): Swatch[] {
	const all = colors(tokens);
	const ratio = (fg: string, bg: string): Pair => ({
		fg,
		bg,
		light: contrast(all[fg]?.light ?? '', all[bg]?.light ?? ''),
		dark: contrast(all[fg]?.dark ?? '', all[bg]?.dark ?? '')
	});
	return Object.entries(all).map(([name, token]) => {
		const [group = '', key = ''] = name.split('.');
		return {
			name,
			css: `--${group}-${key}`,
			swift: `Tokens.${title(group)}.${camel(key)}`,
			about: token.about,
			light: token.light,
			dark: token.dark,
			macos: token.macos
				? { system: token.macos }
				: { light: token.macosLight ?? token.light, dark: token.macosDark ?? token.dark },
			pairs: tokens.contrast.pairs
				.filter(([fg, bg]) => fg === name || bg === name)
				.map(([fg, bg]) => ratio(fg, bg))
		};
	});
}

export type Mapping = { token: string; about: string; apps: string; site: string };

/** CSS custom property prefixes for each non-colour group, where they differ from the group's name. */
const cssPrefixes: Record<string, string[]> = {
	elevation: ['shadow'],
	motion: ['duration', 'easing'],
	type: ['type']
};

/**
 * The README's "what is the system's and what is ours", one row per colour and text style and one
 * per scale. `swift` is the generated Tokens.swift, which says what the apps actually receive.
 */
export function mapping(tokens: Tokens, swift: string): Mapping[] {
	const pair = (light: string, dark: string) => (light === dark ? light : `${light} / ${dark}`);
	const colourRows = swatches(tokens).map((s) => ({
		token: s.name,
		about: s.about,
		apps: 'system' in s.macos ? s.macos.system : `ours: ${pair(s.macos.light, s.macos.dark)}`,
		site: pair(s.light, s.dark)
	}));
	const typeRows = entries(tokens.type).map(([name, step]) => ({
		token: `type.${name}`,
		about: '',
		apps: step.macos ? `.${step.macos} text style` : 'none: site only',
		site: `${step.size}px / ${step.line}`
	}));
	const groups = ['font', 'weight', 'space', 'radius', 'motion', 'elevation', 'layer', 'layout'] as const;
	const groupRows = groups.map((group) => {
		const about = (tokens[group] as { about?: string }).about ?? '';
		const prefixes = cssPrefixes[group] ?? [group];
		return {
			token: `${group}.*`,
			about,
			apps: swift.includes(`public enum ${title(group)} {`) ? `Tokens.${title(group)}` : 'none',
			site: prefixes.map((p) => `--${p}-*`).join(', ')
		};
	});
	return [...colourRows, ...typeRows, ...groupRows];
}
