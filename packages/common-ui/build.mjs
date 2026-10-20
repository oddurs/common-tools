// Renders tokens.json into what each surface consumes:
//
//   packages/CommonKit/Sources/CommonUI/Tokens.swift   the apps (AppKit and SwiftUI)
//   site/src/lib/common-ui/tokens.css                      the site (CSS custom properties)
//
//   node packages/common-ui/build.mjs          write both
//   node packages/common-ui/build.mjs --check  exit 1 if either is out of date
//   node packages/common-ui/build.mjs --brand <app>   the app's colours as JSON, for scripts/make-icon
//
// No dependencies: Node's standard library only, so it runs wherever the tests run. Tests on both
// surfaces fail when an output is older than the source (see README.md).

import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

export const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
export const sourcePath = join(root, 'packages/common-ui/tokens.json');
export const outputs = {
	swift: join(root, 'packages/CommonKit/Sources/CommonUI/Tokens.swift'),
	css: join(root, 'site/src/lib/common-ui/tokens.css')
};

/** The source text and its hash, which both outputs carry so a test can tell they match. */
export function source() {
	const text = readFileSync(sourcePath, 'utf8');
	return { text, hash: createHash('sha256').update(text).digest('hex'), tokens: JSON.parse(text) };
}

const header = (comment, hash) =>
	[
		`${comment} Generated from packages/common-ui/tokens.json by packages/common-ui/build.mjs. Do not edit;`,
		`${comment} change the source and run \`node packages/common-ui/build.mjs\`.`,
		`${comment} source sha256: ${hash}`
	].join('\n');

/** Token groups a surface consumes: all of them unless the group names its surfaces. */
function groupsFor(tokens, surface) {
	return Object.entries(tokens).filter(
		([name, group]) =>
			!name.startsWith('$') && typeof group === 'object' && (!group.surfaces || group.surfaces.includes(surface))
	);
}

/** Entries of a group, without its metadata. */
export const entries = (group) =>
	Object.entries(group).filter(([key]) => !['about', 'surfaces'].includes(key));

/** A palette name or a literal #rrggbb[aa], as the literal. */
export function resolveColor(tokens, value) {
	if (value.startsWith('#')) {
		if (!/^#[0-9a-f]{6}([0-9a-f]{2})?$/.test(value)) throw new Error(`not a colour: ${value}`);
		return value;
	}
	const hex = tokens.palette[value];
	if (!hex) throw new Error(`no palette colour named '${value}'`);
	return hex;
}

/** Every colour token, flattened to `group.name` with resolved light and dark values. */
export function colors(tokens) {
	const out = {};
	for (const group of ['text', 'surface', 'color'])
		for (const [name, token] of entries(tokens[group]))
			out[`${group}.${name}`] = {
				...token,
				light: resolveColor(tokens, token.light),
				dark: resolveColor(tokens, token.dark)
			};
	return out;
}

/** Text as comment lines no longer than swift-format's 120 columns. */
function wrap(text, prefix, width = 118) {
	const lines = [];
	let line = prefix;
	for (const word of text.split(' ')) {
		if (line.length + word.length > width && line !== prefix) {
			lines.push(line.trimEnd());
			line = prefix;
		}
		line += `${word} `;
	}
	lines.push(line.trimEnd());
	return lines;
}

// MARK: - Brand colours

/** OKLCH to an sRGB hex, lowering chroma until the colour fits sRGB rather than clipping its hue. */
export function oklch(l, c, h) {
	for (let chroma = c; chroma >= 0; chroma -= 0.002) {
		const a = chroma * Math.cos((h * Math.PI) / 180);
		const b = chroma * Math.sin((h * Math.PI) / 180);
		// Ottosson's OKLab to linear sRGB.
		const l_ = (l + 0.3963377774 * a + 0.2158037573 * b) ** 3;
		const m_ = (l - 0.1055613458 * a - 0.0638541728 * b) ** 3;
		const s_ = (l - 0.0894841775 * a - 1.291485548 * b) ** 3;
		const linear = [
			4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_,
			-1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_,
			-0.0041960863 * l_ - 0.7034186147 * m_ + 1.707614701 * s_
		];
		if (linear.every((v) => v >= -0.0005 && v <= 1.0005)) {
			const encode = (v) => {
				const x = Math.min(Math.max(v, 0), 1);
				return Math.round(255 * (x <= 0.0031308 ? 12.92 * x : 1.055 * x ** (1 / 2.4) - 0.055));
			};
			return `#${linear.map((v) => encode(v).toString(16).padStart(2, '0')).join('')}`;
		}
	}
	throw new Error(`no sRGB colour for oklch(${l} ${c} ${h})`);
}

/** An sRGB hex as OKLCH lightness, chroma, and hue in degrees. */
export function toOklch(hex) {
	const decode = (i) => {
		const v = parseInt(hex.slice(i, i + 2), 16) / 255;
		return v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
	};
	const [r, g, b] = [decode(1), decode(3), decode(5)];
	// Ottosson's linear sRGB to OKLab.
	const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
	const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
	const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
	const L = 0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s;
	const A = 1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s;
	const B = 0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s;
	return { l: L, c: Math.hypot(A, B), h: ((Math.atan2(B, A) * 180) / Math.PI + 360) % 360 };
}

/** The system colours Common Color's body runs through, round the wheel. */
const spectrum = ['red', 'orange', 'yellow', 'green', 'mint', 'teal', 'blue', 'indigo', 'purple', 'pink'];

/**
 * An app's colours: its system colour, and its icon body's stops top to bottom, the same steps from
 * the system colour for every app. Common Color's are the spectrum, with pink as the colour that
 * stands for it.
 */
export function brand(tokens, slug) {
	const { system, ramp, apps } = tokens.brand;
	const app = apps[slug];
	if (!app || typeof app !== 'object') throw new Error(`no brand colour for '${slug}'`);
	const name = app.spectrum ? 'pink' : app.system;
	const mid = system[name];
	if (!mid) throw new Error(`no system colour '${name}' for '${slug}'`);
	const { l, c, h } = toOklch(mid);
	const step = (s) => oklch(Math.min(l + s.l, 0.97), Math.max(c + s.c, 0), h);
	const colors = { top: step(ramp.top), mid, deep: step(ramp.deep) };
	return app.spectrum ? { ...colors, spectrum: spectrum.map((n) => system[n]) } : colors;
}

const camel = (name) => name.replace(/-(\w)/g, (_, c) => c.toUpperCase());
const cssName = (...parts) => `--${parts.join('-')}`;
const cubic = ([a, b, c, d]) => `cubic-bezier(${a}, ${b}, ${c}, ${d})`;

// MARK: - CSS

export function renderCSS({ tokens, hash }) {
	const light = [];
	// What changes with the appearance, in each one; `light` holds every token besides.
	const lightOnly = [];
	const dark = [];
	const still = [];
	const declare = (name, value) => light.push(`\t${name}: ${value};`);
	const appearance = (name, lightValue, darkValue) => {
		declare(name, lightValue);
		lightOnly.push(`\t${name}: ${lightValue};`);
		dark.push(`\t${name}: ${darkValue};`);
	};
	for (const [groupName, group] of groupsFor(tokens, 'site')) {
		switch (groupName) {
			case 'text':
			case 'surface':
			case 'color':
				for (const [name, token] of entries(group))
					appearance(
						cssName(groupName, name),
						resolveColor(tokens, token.light),
						resolveColor(tokens, token.dark)
					);
				break;
			case 'font':
				for (const [name, token] of entries(group)) declare(cssName('font', name), token.web);
				break;
			case 'weight':
				for (const [name, value] of entries(group)) declare(cssName('weight', name), value);
				break;
			case 'type':
				for (const [name, step] of entries(group)) {
					// A font shorthand, so a rule reads `font: var(--type-body)`.
					declare(
						cssName('type', name),
						`var(--weight-${step.weight}) ${step.size}px/${step.line} var(--font-${step.font})`
					);
					declare(cssName('type', name, 'tracking'), `${step.tracking}em`);
				}
				break;
			case 'space':
			case 'radius':
				for (const [name, value] of entries(group)) declare(cssName(groupName, name), `${value}px`);
				break;
			case 'elevation':
				for (const [name, token] of entries(group))
					appearance(cssName('shadow', name), token.light, token.dark);
				break;
			case 'motion':
				for (const [name, ms] of entries(group.duration)) {
					declare(cssName('duration', name), `${ms}ms`);
					still.push(`\t${cssName('duration', name)}: 0ms;`);
				}
				for (const [name, curve] of entries(group.easing)) declare(cssName('easing', name), cubic(curve));
				break;
			case 'layer':
				for (const [name, value] of entries(group)) declare(cssName('layer', name), value);
				break;
			case 'brand':
				// The same in both appearances: an icon's body doesn't change with the theme.
				for (const [slug] of entries(group.apps)) {
					const colors = brand(tokens, slug);
					declare(cssName('brand', slug), colors.mid);
					declare(cssName('brand', slug, 'top'), colors.top);
					declare(cssName('brand', slug, 'deep'), colors.deep);
					const stops = colors.spectrum ?? [colors.top, colors.mid, colors.deep];
					const args = ['170deg', ...stops];
					const flat = `linear-gradient(${args.join(', ')})`;
					const name = cssName('brand', slug, 'gradient');
					// Laid out as Prettier lays out a value too long for one line, so formatting the site
					// leaves the generated file as it is.
					declare(
						name,
						`\t${name}: ${flat};`.length <= 100
							? flat
							: `linear-gradient(\n${args.map((a) => `\t\t${a}`).join(',\n')}\n\t)`
					);
				}
				break;
			case 'layout':
				// Media queries can't read a custom property, so the breakpoint stays in each @media by
				// hand; a test holds those to the token.
				for (const [name, value] of entries(group))
					if (!name.startsWith('breakpoint')) declare(cssName('layout', name), `${value}px`);
				break;
			default:
				break;
		}
	}
	return [
		`/*\n${header(' *', hash)}\n */`,
		':root {',
		'\tcolor-scheme: light dark;',
		...light,
		'}',
		// The system's appearance, unless an element says otherwise with data-theme: the root, to
		// override it for the page, or any element, to show its subtree in one appearance.
		"[data-theme='light'] {",
		'\tcolor-scheme: light;',
		...lightOnly,
		'}',
		'@media (prefers-color-scheme: dark) {',
		"\t:root:not([data-theme='light']) {",
		...dark.map((line) => `\t${line}`),
		'\t}',
		'}',
		"[data-theme='dark'] {",
		'\tcolor-scheme: dark;',
		...dark,
		'}',
		'@media (prefers-reduced-motion: reduce) {',
		'\t:root {',
		...still.map((line) => `\t${line}`),
		'\t}',
		'}',
		''
	].join('\n');
}

// MARK: - Swift

const swiftHex = (hex) => {
	const rgb = `0x${hex.slice(1, 7)}`;
	const alpha = hex.length === 9 ? (parseInt(hex.slice(7, 9), 16) / 255).toFixed(3) : null;
	return alpha ? `${rgb}, alpha: ${alpha}` : rgb;
};

function swiftColor(tokens, name, token, indent) {
	const light = resolveColor(tokens, token.light);
	const dark = resolveColor(tokens, token.dark);
	const lines = [];
	const doc = [token.about];
	if (token.macos) doc.push(`macOS: \`${token.macos}\`.`);
	else if (token.macosLight) doc.push(`macOS: ${token.macosLight} / ${token.macosDark}, ours.`);
	else doc.push(`macOS has none: ${light} / ${dark}, ours.`);
	doc.push(light === dark ? `Site: ${light}.` : `Site: ${light} / ${dark}.`);
	lines.push(...wrap(doc.join(' '), `${indent}/// `));
	if (token.macos) {
		lines.push(`${indent}public static let ${camel(name)} = SemanticColor(system: .${token.macos})`);
	} else {
		const l = token.macosLight ?? light;
		const d = token.macosDark ?? dark;
		lines.push(
			`${indent}public static let ${camel(name)} = SemanticColor(light: ${swiftHex(l)}, dark: ${swiftHex(d)})`
		);
	}
	return lines;
}

export function renderSwift({ tokens, hash }) {
	const out = [header('//', hash), '', 'import AppKit', 'import SwiftUI', ''];
	out.push(
		'/// The design tokens, as the apps consume them: the semantic colours, the spacing and radius scales,',
		'/// motion, and the layout widths. Type comes from the system text styles, not from here.',
		'public enum Tokens {',
		'    /// SHA-256 of tokens.json when this file was generated. A test compares it to the file.',
		`    public static let sourceHash = "${hash}"`
	);
	for (const [groupName, group] of groupsFor(tokens, 'macos')) {
		const title = groupName[0].toUpperCase() + groupName.slice(1);
		switch (groupName) {
			case 'text':
			case 'surface':
			case 'color': {
				out.push('', `    public enum ${title} {`);
				const members = entries(group).flatMap(([name, token], i) => [
					...(i ? [''] : []),
					...swiftColor(tokens, name, token, '        ')
				]);
				out.push(...members, '    }');
				break;
			}
			case 'weight':
				out.push('', '    public enum Weight {');
				for (const [name] of entries(group))
					out.push(`        public static let ${camel(name)}: Font.Weight = .${name}`);
				out.push('    }');
				break;
			case 'space':
			case 'radius':
			case 'layout':
				out.push('', ...wrap(group.about ?? `${title}, in points.`, '    /// '), `    public enum ${title} {`);
				for (const [name, value] of entries(group))
					out.push(`        public static let ${camel(name)}: CGFloat = ${value}`);
				out.push('    }');
				break;
			case 'motion':
				out.push('', ...wrap(group.about, '    /// '), '    public enum Motion {');
				for (const [name, ms] of entries(group.duration))
					out.push(`        public static let ${camel(name)}: TimeInterval = ${ms / 1000}`);
				out.push('', '        public enum Easing {');
				for (const [name, curve] of entries(group.easing))
					out.push(`            public static let ${camel(name)} = Curve(${curve.join(', ')})`);
				out.push('        }', '    }');
				break;
			default:
				break;
		}
	}
	out.push('}', '');
	return out.join('\n');
}

export function render() {
	const src = source();
	return { swift: renderSwift(src), css: renderCSS(src) };
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1] && process.argv.includes('--brand')) {
	const slug = process.argv[process.argv.indexOf('--brand') + 1];
	console.log(JSON.stringify(brand(source().tokens, slug)));
} else if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
	const rendered = render();
	let stale = 0;
	for (const [name, path] of Object.entries(outputs)) {
		let current = '';
		try {
			current = readFileSync(path, 'utf8');
		} catch {
			current = '';
		}
		if (current === rendered[name]) continue;
		stale += 1;
		if (process.argv.includes('--check')) console.error(`out of date: ${path}`);
		else {
			writeFileSync(path, rendered[name]);
			console.log(`wrote ${path}`);
		}
	}
	if (process.argv.includes('--check')) process.exit(stale ? 1 : 0);
}
