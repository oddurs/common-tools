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
/** The advance is what Chrome measures for 12-point `ui-monospace` here, so the loupe's glyphs line up. */
export const code = { left: 56, top: 14, line: 20, size: 12, advance: 7.2246875, baseline: 13.2 };

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

/**
 * The drag: the two lines that answer the question, where the rectangle is clipped to the screen.
 * It ends tight on the last glyph, so the loupe at the corner shows the pixels of the `d`.
 */
const answer = { first: 11, last: 12, indent: 8 };
const longest = Math.max(...lines.slice(answer.first, answer.last + 1).map((line) => line.length));
export const dragFrom = {
	x: pane.x + code.left + answer.indent * code.advance - 3,
	y: lineTop(answer.first) + 2
};
export const dragTo = {
	x: pane.x + code.left + longest * code.advance + 1.5,
	y: lineTop(answer.last) + code.baseline + 3.5
};

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
export function toastLayout(rect: Rect, label: string) {
	const thumb = thumbnailSize(rect);
	// The caption at 11-point medium, about 5.9 points a character.
	const labelWidth = Math.ceil(label.length * 5.9);
	const width = Math.max(thumb.width, labelWidth) + 24;
	const height = 12 + thumb.height + 8 + 14 + 12;
	const x = screen.width - 24 - width;
	const y = screen.height - 24 - height;
	return {
		card: { x, y, width, height },
		thumb: { x: x + (width - thumb.width) / 2, y: y + 12, ...thumb }
	};
}

// The editor's colours, light and dark (Xcode's defaults). Code.svelte paints with them and the loupe
// draws its text in them, so the two agree.

export type Kind = 'plain' | 'keyword' | 'type' | 'number' | 'comment';
export const codeColours = {
	light: {
		background: '#ffffff',
		gutter: '#a3a3aa',
		plain: '#1d1d1f',
		keyword: '#9b2393',
		type: '#3900a0',
		number: '#1c00cf',
		comment: '#5d6c79'
	},
	dark: {
		background: '#1f1f24',
		gutter: '#66666e',
		plain: '#dfdfe0',
		keyword: '#fc5fa3',
		type: '#d0a8ff',
		number: '#d0bf69',
		comment: '#7f8c98'
	}
} as const;

const keywords = new Set(['public', 'static', 'let', 'func', 'enum', 'return']);
const types = new Set(['CGFloat', 'CGPoint', 'CGRect', 'Geometry']);

/** A line of Swift as the editor colours it. */
export function tokenize(line: string): { text: string; kind: Kind }[] {
	const comment = line.indexOf('///');
	if (comment >= 0)
		return [
			{ text: line.slice(0, comment), kind: 'plain' },
			{ text: line.slice(comment), kind: 'comment' }
		];
	return line.split(/(\b\w+\b)/).map((text) => ({
		text,
		kind: keywords.has(text)
			? 'keyword'
			: types.has(text)
				? 'type'
				: /^\d+$/.test(text)
					? 'number'
					: 'plain'
	}));
}

export const codeFont = (bold = false) =>
	`${bold ? '600 ' : ''}${code.size}px ui-monospace, 'SF Mono', Menlo, monospace`;
const chatFont = (size: number, bold = false) =>
	`${bold ? '600 ' : ''}${size}px -apple-system, BlinkMacSystemFont, sans-serif`;

/** A line of text on the frozen screen: pieces drawn one after another from `x`. */
export type TextRun = {
	x: number;
	baseline: number;
	pieces: { text: string; font: string; colour: string; gap?: number }[];
	/** Right-aligned at `x`, as the gutter's numbers are. */
	right?: boolean;
};

/** Every line of text the overlay freezes, in screen points, for the loupe to draw. */
export function textRuns(dark: boolean): TextRun[] {
	const c = codeColours[dark ? 'dark' : 'light'];
	const ink = dark ? '#f2f2f7' : '#1d1d1f';
	const muted = dark ? '#8e8e93' : '#86868b';
	const runs: TextRun[] = lines.flatMap((line, i) => [
		{
			x: pane.x + 36,
			baseline: lineTop(i) + code.baseline,
			right: true,
			pieces: [{ text: String(i + 1), font: codeFont(), colour: c.gutter }]
		},
		{
			x: pane.x + code.left,
			baseline: lineTop(i) + code.baseline,
			pieces: tokenize(line).map(({ text, kind }) => ({
				text,
				font: codeFont(kind === 'keyword'),
				colour: c[kind]
			}))
		}
	]);
	runs.push({
		x: composer.x + 14,
		baseline: composer.y + 28.6,
		pieces: [{ text: typed, font: chatFont(13), colour: ink }]
	});
	// Bottom up from the field: each message a name line and a text line, 14 points apart.
	[...thread].reverse().forEach((message, i) => {
		const top = composer.y - 16 - 40 - i * 54;
		runs.push(
			{
				x: chat.x + 64,
				baseline: top + 14.6,
				pieces: [
					{ text: message.name, font: chatFont(13, true), colour: ink },
					{ text: message.time, font: chatFont(11), colour: muted, gap: 8 }
				]
			},
			{
				x: chat.x + 64,
				baseline: top + 34.6,
				pieces: [{ text: message.text, font: chatFont(13), colour: ink }]
			}
		);
	});
	return runs;
}

// The loupe's backdrop: the frozen screen's flat colours, one device pixel at a time, before text.

type RGB = [number, number, number];
const palettes: Record<'light' | 'dark', Record<string, RGB>> = {
	light: {
		wallpaper: [222, 220, 244],
		window: [255, 255, 255],
		rule: [235, 235, 235],
		sidebar: [244, 244, 246],
		code: [255, 255, 255],
		field: [255, 255, 255],
		fieldEdge: [214, 214, 218]
	},
	dark: {
		wallpaper: [22, 30, 66],
		window: [30, 30, 32],
		rule: [44, 44, 46],
		sidebar: [38, 38, 40],
		code: [31, 31, 36],
		field: [40, 40, 43],
		fieldEdge: [72, 72, 76]
	}
};

const inside = (r: { x: number; y: number; width: number; height: number }, x: number, y: number) =>
	x >= r.x && x < r.x + r.width && y >= r.y && y < r.y + r.height;

/** The colour under device pixel (px, py) on a 2× screen, text aside. */
export function backdrop(px: number, py: number, dark: boolean): RGB {
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
			return edge ? p.fieldEdge : p.field;
		}
		return p.window;
	}
	if (inside(editor, x, y)) {
		if (y < editor.y + titleBar - 0.5) return p.window;
		if (y < editor.y + titleBar) return p.rule;
		return x < pane.x ? p.sidebar : p.code;
	}
	return p.wallpaper;
}
