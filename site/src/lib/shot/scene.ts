// Where everything in the Common Shot film sits, in screen points from the top left, and what the
// frozen screen looks like pixel by pixel for the loupe. Demo.svelte lays out to these numbers.

import { screen } from '../mac/geometry';
import type { Rect } from './size';

export const editor = { x: 130, y: 130, width: 800, height: 600 } as const;
export const chat = { x: 960, y: 420, width: 640, height: 400 } as const;
/** Windows front to back, as the window server lists them: what a hover lights. */
export const windows = { chat, editor } as const;
export type WindowID = keyof typeof windows;

const titleBar = 52;
export const sidebarWidth = 200;

/** The code pane, right of the sidebar. */
export const pane = {
	x: editor.x + sidebarWidth,
	y: editor.y + titleBar,
	width: editor.width - sidebarWidth,
	height: editor.height - titleBar
};
export const code = { left: 56, top: 14, line: 20, size: 12, advance: 7.2 };

/** ShotKit's own Geometry.selection, as it reads in the editor. */
export const lines = [
	'public enum Geometry {',
	'    /// A drag shorter than this on either side is a click.',
	'    public static let minimumDrag: CGFloat = 4',
	'',
	'    /// The rectangle a drag spans, kept inside `bounds`.',
	'    public static func selection(',
	'        from start: CGPoint, to end: CGPoint, within bounds: CGRect',
	'    ) -> CGRect {',
	'        let rect = CGRect(',
	'            x: min(start.x, end.x), y: min(start.y, end.y),',
	'            width: abs(end.x - start.x), height: abs(end.y - start.y))',
	'        let clipped = rect.intersection(bounds)',
	'        return clipped.isNull ? .zero : clipped',
	'    }',
	'}'
];

const lineTop = (i: number) => pane.y + code.top + i * code.line;

/** The drag: from just above and left of `selection(`, to just past the end of the function. */
export const dragFrom = { x: pane.x + code.left - 12, y: lineTop(5) - 2 };
const longest = Math.max(...lines.slice(5, 14).map((line) => line.length));
export const dragTo = { x: pane.x + code.left + longest * code.advance + 12, y: lineTop(14) + 2 };

export const composer = {
	x: chat.x + 20,
	y: chat.y + chat.height - 20 - 48,
	width: chat.width - 40,
	height: 48
};
export const typed = 'Here, in ShotKit:';
/** The thread so far, oldest first; the reply with the shot comes after it. */
export const thread = [
	{ name: 'Maya', time: '9:24 AM', text: 'Morning! Reviewing the overlay today.' },
	{ name: 'Alex', time: '9:31 AM', text: 'Pushed the change to how a drag snaps to edges.' },
	{ name: 'Maya', time: '9:38 AM', text: 'Where does a drag get clipped to the edge of the screen?' }
];

/** The preview's thumbnail: at most 180 points on its long side (`Toast.maximumSide`). */
export function thumbnailSize(rect: Rect) {
	const fit = Math.min(1, 180 / Math.max(rect.width, rect.height));
	return { width: Math.max(rect.width * fit, 40), height: Math.max(rect.height * fit, 24) };
}

/** The preview card: 12-point insets, the thumbnail, 8 points, the caption; 24 points from the corner. */
export function toastLayout(rect: Rect) {
	const thumb = thumbnailSize(rect);
	const labelWidth = 200;
	const width = Math.max(thumb.width, labelWidth) + 24;
	const height = 12 + thumb.height + 8 + 14 + 12;
	const x = screen.width - 24 - width;
	const y = screen.height - 24 - height;
	return {
		card: { x, y, width, height },
		thumb: { x: x + (width - thumb.width) / 2, y: y + 12, ...thumb }
	};
}

// The loupe: the frozen screen, one device pixel at a time. Text is drawn as ink in each character's
// cell, the way a magnified glyph breaks into pixels; everything else is its flat colour.

type RGB = [number, number, number];
type Palette = {
	wallpaper: RGB;
	window: RGB;
	rule: RGB;
	sidebar: RGB;
	code: RGB;
	ink: RGB;
	comment: RGB;
	keyword: RGB;
	field: RGB;
	fieldEdge: RGB;
};

const palettes: Record<'light' | 'dark', Palette> = {
	light: {
		wallpaper: [222, 220, 244],
		window: [255, 255, 255],
		rule: [235, 235, 235],
		sidebar: [244, 244, 246],
		code: [255, 255, 255],
		ink: [29, 29, 31],
		comment: [93, 108, 121],
		keyword: [155, 35, 147],
		field: [255, 255, 255],
		fieldEdge: [214, 214, 218]
	},
	dark: {
		wallpaper: [22, 30, 66],
		window: [30, 30, 32],
		rule: [44, 44, 46],
		sidebar: [38, 38, 40],
		code: [31, 31, 36],
		ink: [223, 223, 224],
		comment: [127, 140, 152],
		keyword: [252, 95, 163],
		field: [40, 40, 43],
		fieldEdge: [72, 72, 76]
	}
};

type Run = { x: number; baseline: number; size: number; advance: number; text: string };

/** How much of the device pixel [p, p + 1) the stroke [from, to) covers, all in device pixels. */
const cover = (p: number, from: number, to: number) => Math.max(0, Math.min(p + 1, to) - Math.max(p, from));

/**
 * Ink in device pixel (px, py): each character drawn as a few strokes, a stem or two and a bar or
 * two chosen by its code, about a point thick, so magnified text breaks into pixels the way a glyph
 * does without spelling anything.
 */
function inkAt(runs: Run[], px: number, py: number): number {
	const x = px / 2;
	const y = py / 2;
	for (const run of runs) {
		const index = Math.floor((x - run.x) / run.advance);
		if (index < 0 || index >= run.text.length || run.text[index] === ' ') continue;
		const char = run.text[index];
		const code = char.charCodeAt(0);
		const tall = /[A-Z0-9(){}`/]/.test(char);
		const height = run.size * (tall ? 0.72 : 0.52);
		const top = run.baseline - height;
		if (y < top - 0.5 || y > run.baseline + 0.5) continue;
		const left = run.x + index * run.advance + run.advance * 0.18;
		const width = run.advance * 0.64;
		const stroke = run.size / 12;
		let ink = 0;
		const stem = (at: number) => {
			const from = (left + width * at) * 2;
			ink = Math.max(ink, cover(px, from, from + stroke * 2) * cover(py, top * 2, run.baseline * 2));
		};
		const bar = (at: number) => {
			const from = (top + (height - stroke) * at) * 2;
			ink = Math.max(ink, cover(py, from, from + stroke * 2) * cover(px, left * 2, (left + width) * 2));
		};
		if (code % 3 !== 0) stem(0);
		if (code % 2 === 0) stem(0.84);
		if (code % 5 < 3) bar(0);
		if (code % 7 < 3) bar(0.5);
		if (code % 4 < 2) bar(1);
		if (code % 6 === 1) stem(0.42);
		return ink;
	}
	return 0;
}

const codeRuns: Run[] = lines.map((text, i) => ({
	x: pane.x + code.left,
	baseline: lineTop(i) + 14,
	size: code.size,
	advance: code.advance,
	text
}));
const chatRuns: Run[] = [
	{ x: composer.x + 14, baseline: composer.y + 29, size: 13, advance: 6.9, text: typed },
	// Bottom up from the field: each message a name line and a text line, 14 points apart.
	...[...thread].reverse().flatMap((message, i) => [
		{ x: chat.x + 64, baseline: composer.y - 41 - i * 54, size: 13, advance: 7.4, text: message.name },
		{ x: chat.x + 64, baseline: composer.y - 21 - i * 54, size: 13, advance: 6.6, text: message.text }
	])
];

const inside = (r: { x: number; y: number; width: number; height: number }, x: number, y: number) =>
	x >= r.x && x < r.x + r.width && y >= r.y && y < r.y + r.height;

const mix = (a: RGB, b: RGB, k: number): RGB => [
	a[0] + (b[0] - a[0]) * k,
	a[1] + (b[1] - a[1]) * k,
	a[2] + (b[2] - a[2]) * k
];

/** The colour of device pixel (px, py) on a 2× screen. */
export function pixel(px: number, py: number, dark: boolean): RGB {
	const p = palettes[dark ? 'dark' : 'light'];
	const x = (px + 0.5) / 2;
	const y = (py + 0.5) / 2;
	if (inside(chat, x, y)) {
		if (y < chat.y + titleBar - 0.5) return p.window;
		if (y < chat.y + titleBar) return p.rule;
		if (inside(composer, x, y)) {
			const edge =
				x < composer.x + 0.5 ||
				x >= composer.x + composer.width - 0.5 ||
				y < composer.y + 0.5 ||
				y >= composer.y + composer.height - 0.5;
			if (edge) return p.fieldEdge;
			return mix(p.field, p.ink, inkAt(chatRuns.slice(0, 1), px, py));
		}
		return mix(p.window, p.ink, inkAt(chatRuns.slice(1), px, py));
	}
	if (inside(editor, x, y)) {
		if (y < editor.y + titleBar - 0.5) return p.window;
		if (y < editor.y + titleBar) return p.rule;
		if (x < pane.x) return p.sidebar;
		const line = Math.floor((y - pane.y - code.top) / code.line);
		const colour = lines[line]?.trim().startsWith('///') ? p.comment : p.ink;
		return mix(p.code, colour, inkAt(codeRuns, px, py));
	}
	return p.wallpaper;
}
