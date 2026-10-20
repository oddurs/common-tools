// Types for build.mjs, so the site's tests read tokens.json through them.

export type Hex = `#${string}`;

export type ColorToken = {
	about: string;
	/** False for a surface no text is ever set on, so the contrast test leaves it out. */
	holdsText?: boolean;
	/** The NSColor the apps use, when macOS has a semantic colour for this. */
	macos?: string;
	/** A palette name or a literal #rrggbb[aa]. */
	light: string;
	dark: string;
	/** The apps' own values when macOS has no colour for this and the site's values don't suit a window. */
	macosLight?: Hex;
	macosDark?: Hex;
};

export type TypeStep = {
	size: number;
	line: number;
	tracking: number;
	weight: string;
	font: string;
	macos?: string;
};

export type Group<T> = { about?: string; surfaces?: string[] } & Record<string, T>;

export type Tokens = {
	palette: Record<string, Hex>;
	text: Group<ColorToken>;
	surface: Group<ColorToken>;
	color: Group<ColorToken>;
	contrast: { about: string; pairs: [string, string][] };
	font: Group<{ about: string; web: string }>;
	weight: Record<string, number>;
	type: Group<TypeStep>;
	space: Group<number>;
	radius: Group<number>;
	elevation: Group<{ light: string; dark: string }>;
	motion: { about: string; duration: Record<string, number>; easing: Record<string, number[]> };
	layer: Group<number>;
	layout: Group<number>;
	brand: {
		about: string;
		surfaces: string[];
		ramp: Record<'top' | 'mid' | 'deep', { l: number; c: number; turn: number }> & { about?: string };
		apps: Group<{ hue?: number; spectrum?: boolean }>;
	};
};

/** An app's colours: its icon body's stops, and Common Color's spectrum. */
export type BrandColors = { top: Hex; mid: Hex; deep: Hex; spectrum?: Hex[] };

export type ResolvedColor = ColorToken & { light: Hex; dark: Hex };

export const root: string;
export const sourcePath: string;
export const outputs: { swift: string; css: string };
export function source(): { text: string; hash: string; tokens: Tokens };
export function entries<T>(group: Group<T> | Record<string, T>): [string, T][];
export function resolveColor(tokens: Tokens, value: string): Hex;
export function colors(tokens: Tokens): Record<string, ResolvedColor>;
export function renderCSS(src: { tokens: Tokens; hash: string }): string;
export function renderSwift(src: { tokens: Tokens; hash: string }): string;
export function render(): { swift: string; css: string };
export function oklch(l: number, c: number, h: number): Hex;
export function brand(tokens: Tokens, slug: string): BrandColors;
