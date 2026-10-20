// The Common Color demo: a poster in a browser and a stylesheet beside it. ⌃⇧⌘C brings up the
// system's loupe, which glides over the poster to the sun's edge; a click copies the pixel as hex
// and the app's card says so beside the pointer; ⌘V puts it in the stylesheet. Then the eyedropper's
// panel: the pick as its hero, the recent picks, and the contrast between the newest two, which
// is the very pair the stylesheet's `.hero` rule sets; All Formats, and one click copies OKLCH.
//
// Every string the app shows is what ColorKit writes for these colours (ColorFormat, Describe,
// Contrast), and the panel and card are laid out to the app's `--snapshot` renders (ColorPanel,
// CopyConfirmation, CommonUI's MenuPanelSurface and ConfirmationHost). The scene is a pure function
// of time, so the recorder can step through it frame by frame.

import { direct, type BaseFrame } from '../film/director';
import { clamp, ramp, type Point } from '../film/motion';
import { extrasRight, menuBarHeight, screen, statusSlot, wide } from '../mac/geometry';

// MARK: The colours

/** The poster's palette, as its stylesheet names them. */
export const palette = {
	ink: '#14213d',
	paper: '#f4efe6',
	sea: '#2a9d8f',
	sand: '#e9c46a',
	sun: '#ff7518'
} as const;

/** What ColorKit's `ColorFormat` writes for #ff7518, in the panel's order: key 1 to 7. */
export const formats = [
	{ title: 'Hex', text: '#ff7518' },
	{ title: 'RGB', text: 'rgb(255 117 24)' },
	{ title: 'HSL', text: 'hsl(24.2 100% 54.7%)' },
	{ title: 'OKLCH', text: 'oklch(71.64% 0.1906 47.14)' },
	{ title: 'Display P3', text: 'color(display-p3 0.9329 0.4903 0.2159)' },
	{ title: 'SwiftUI', text: 'Color(.sRGB, red: 1, green: 0.4588, blue: 0.0941)' },
	{ title: 'AppKit', text: 'NSColor(srgbRed: 1, green: 0.4588, blue: 0.0941, alpha: 1)' }
] as const;

/** The hero's second line: `Describe.family`, capitalised, and `gamutDescription`. */
export const family = 'Orange · sRGB';

/** The last 12 picks after the film's one, newest first: the poster's colours and earlier work. */
export const recent = [
	palette.sun,
	palette.ink,
	palette.paper,
	palette.sea,
	palette.sand,
	'#264653',
	'#e76f51',
	'#8ecae6',
	'#b8c0ff',
	'#6d597a',
	'#fafafa',
	'#dad7cd'
];

/** ColorKit's `Contrast` for the newest two: the sun as text on the ink. */
export const contrast = {
	text: '5.94:1',
	verdict: 'Passes AA',
	rows: [
		{ size: 'Normal', aa: true, aaa: false },
		{ size: 'Large', aa: true, aaa: true }
	]
};

// MARK: The poster

/** In screen points: a navy field, the sun setting behind a paper horizon, two bands of sea and sand. */
export const poster = { x: 150, y: 200, width: 440, height: 560 };
export const sun = { x: 370, y: 470, r: 150 };
export const horizon = 540;
export const bands = [
	{ y: 560, height: 18, color: palette.sea },
	{ y: 596, height: 18, color: palette.sand }
];

/** The poster's colour at a point, exactly as the scene's SVG paints it. */
export function paint(x: number, y: number): string {
	if (y >= horizon) {
		const band = bands.find((b) => y >= b.y && y < b.y + b.height);
		return band ? band.color : palette.paper;
	}
	return (x - sun.x) ** 2 + (y - sun.y) ** 2 < sun.r ** 2 ? palette.sun : palette.ink;
}

const rgb = (hex: string) => [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16));
const hex = (c: number[]) => '#' + c.map((v) => Math.round(v).toString(16).padStart(2, '0')).join('');

/** A device pixel of a 2x display, half a point square: the poster under it, edges anti-aliased. */
export function pixel(px: number, py: number): string {
	const n = 4;
	const sum = [0, 0, 0];
	for (let i = 0; i < n; i++)
		for (let j = 0; j < n; j++) {
			const c = rgb(paint((px + (i + 0.5) / n) / 2, (py + (j + 0.5) / n) / 2));
			for (let k = 0; k < 3; k++) sum[k] += c[k] / (n * n);
		}
	return hex(sum);
}

/** How many device pixels the loupe shows across, and how large it draws each. */
export const loupe = { cells: 15, cell: 8 };

/** The loupe's grid around a point, row by row: the pixel under the hot spot is the middle one. */
export function magnified(p: Point): string[][] {
	const half = (loupe.cells - 1) / 2;
	const [cx, cy] = [Math.floor(p.x * 2), Math.floor(p.y * 2)];
	return Array.from({ length: loupe.cells }, (_, j) =>
		Array.from({ length: loupe.cells }, (_, i) => pixel(cx + i - half, cy + j - half))
	);
}

// MARK: The windows and the panel

export const windows = {
	browser: { x: 70, y: 96, width: 960, height: 760 },
	editor: { x: 1040, y: 170, width: 620, height: 470 }
} as const;

/** The stylesheet, as it reads before the paste; the empty `--sun` is where it goes. */
export const css = [
	'/* Kiln Studio: colour tokens */',
	':root {',
	'  --ink: #14213d;',
	'  --paper: #f4efe6;',
	'  --sea: #2a9d8f;',
	'  --sand: #e9c46a;',
	'  --sun: ;',
	'}',
	'',
	'.hero {',
	'  background: var(--ink);',
	'  color: var(--sun);',
	'}'
];
export const sunLine = 6;
export const editorMetrics = { top: 18, line: 26, gutter: 52, char: 9.03 };

/** Common Color's item, rightmost of the extras; a squareLength item is one symbol's slot. */
const itemLeft = extrasRight - statusSlot;
/** MenuPanelSurface: the 320-point panel width and 8 either side. */
export const panelWidth = 336;
export const stage = {
	item: { left: itemLeft, center: { x: itemLeft + statusSlot / 2, y: menuBarHeight / 2 } },
	// MenuPanelHost: under the item's left edge, 4 points down, kept 8 points inside the screen.
	panel: { x: Math.min(itemLeft, screen.width - panelWidth - 8), y: menuBarHeight + 4 },
	// ConfirmationHost: 16 points right of and below the point it is shown near.
	cardOffset: 16
};

/** Rows that highlight under the pointer, as menu items do, by their top and height in the panel. */
const rows = {
	pick: { top: 8, height: 22 },
	copy: { top: 122.5, height: 26 },
	format: (i: number) => ({ top: 148.5 + 21 * i, height: 21 })
};
const allFormatsCenter = { x: stage.panel.x + 52, y: stage.panel.y + 162.5 };
/** OKLCH is the third of the six rows under the default one. */
export const chosenFormat = 3;
const formatCenter = { x: stage.panel.x + 160, y: stage.panel.y + 148.5 + 21 * 2 + 10.5 };

// MARK: The script

const start = { x: 560, y: 652 };
const overSea = { x: 548, y: 430 };
/** On the sun, three points inside its edge, so the loupe shows the edge's pixels in a corner. */
export const target = { x: 490.5, y: 385.5 };
const caret = {
	x: windows.editor.x + editorMetrics.gutter + 16 + editorMetrics.char * css[sunLine].indexOf(';') - 2,
	y: windows.editor.y + 52 + editorMetrics.top + editorMetrics.line * (sunLine + 0.5)
};

const onPoster = { x: 500, y: 480, zoom: 1.45 };
const onEditor = { x: 1300, y: 390, zoom: 1.6 };
const onPanel = { x: screen.width, y: 0, zoom: 1.25 };
const onFormats = { x: screen.width, y: 0, zoom: 1 };
const onCopied = { x: screen.width, y: 0, zoom: 1.8 };

export const film = direct((d) => {
	d.camera(wide).point(start);
	d.at(500).caption('Press ⌃⇧⌘C, and macOS’s own loupe follows the pointer.');
	d.at(1000).hold('⌃', '⇧', '⌘', 'C');
	d.at(1150).mark('sample');
	d.at(1200).camera(onPoster);
	d.at(1600).release().point(start);
	d.at(2600).point(overSea);
	d.at(3700).point(target);
	d.at(4300).mark('pick').caption('Click a pixel, and it’s copied as hex.');
	d.at(5400).camera(onEditor).point(target);
	d.at(6300).point(caret);
	d.at(6500).click().mark('focus');
	d.at(7000).hold('⌘', 'V').caption('Paste it straight into your code.');
	d.at(7100).mark('paste');
	d.at(7400).release();
	d.at(8200).point(caret);
	d.at(8800).camera(onPanel);
	d.at(9200).point(stage.item.center);
	d.at(9400)
		.point(stage.item.center)
		.click()
		.mark('open')
		.caption('The menu bar keeps your picks, every format, and the contrast.');
	d.at(10_000).point({ x: stage.panel.x + 262, y: stage.panel.y + 100 });
	d.at(10_600).poster();
	d.at(10_700).stay();
	d.at(11_300).point(allFormatsCenter);
	d.at(11_500).click().mark('formats').camera(onFormats);
	// Off the link at once, so no row slides in under a resting pointer.
	d.at(11_600).point(allFormatsCenter);
	d.at(12_400).point(formatCenter);
	d.at(13_300).click().mark('copy');
	d.at(13_400).camera(onCopied);
	d.at(14_000).point(formatCenter);
	d.at(14_800).point({ x: formatCenter.x + 40, y: formatCenter.y + 110 });
	d.at(15_200).caption('');
	d.at(15_500).camera(wide);
	d.at(16_000).end(2400);
});

const m = film.marks;

// MARK: The frame

export type Card = { x: number; y: number; format: number; opacity: number };

export type Frame = BaseFrame & {
	/** The loupe while the sampler is up, in place of the pointer. */
	loupe: { x: number; y: number; opacity: number } | null;
	/** The app in front: the browser, until the editor is clicked. */
	front: 'browser' | 'editor';
	pasted: boolean;
	caretOn: boolean;
	/** 0 closed, 1 open. */
	panel: number;
	/** How far All Formats has opened, 0 to 1. */
	formats: number;
	/** The row under the pointer: 'pick', 'copy', or a format's index. */
	hover: 'pick' | 'copy' | number | null;
	card: Card | null;
};

/** ConfirmationHost: in over Motion.fast, shown for 1.4 s, out over Motion.base. */
function card(t: number, at: number, p: Point, format: number): Card | null {
	const opacity = Math.min(ramp(t, at, 150), 1 - ramp(t, at + 150 + 1400, 250));
	if (t < at || opacity <= 0) return null;
	return { x: p.x + stage.cardOffset, y: p.y + stage.cardOffset, format, opacity };
}

function hovered(p: Point, formats: number): Frame['hover'] {
	const x = p.x - stage.panel.x;
	const y = p.y - stage.panel.y;
	const inside = (r: { top: number; height: number }, left: number, right: number) =>
		x >= left && x < right && y >= r.top && y < r.top + r.height;
	if (inside(rows.pick, 8, panelWidth - 8)) return 'pick';
	if (inside(rows.copy, 20, panelWidth - 20)) return 'copy';
	if (formats >= 1)
		for (let i = 0; i < 6; i++) if (inside(rows.format(i), 20, panelWidth - 20)) return i + 1;
	return null;
}

export function frameAt(time: number): Frame {
	const base = film.frame(time);
	const { t } = base;
	const sampling = t >= m.sample && t < m.pick;
	const pointer = base.cursor!;
	const panel = Math.min(ramp(t, m.open, 150), t >= m.copy ? 0 : 1);
	const formats = t >= m.copy ? 0 : ramp(t, m.formats, 150);
	const copied =
		card(t, m.pick, target, 0) ?? card(t, m.copy, { x: stage.item.left, y: menuBarHeight }, chosenFormat);
	return {
		...base,
		cursor: sampling ? null : pointer,
		loupe: sampling ? { ...pointer, opacity: clamp((t - m.sample) / 120) } : null,
		front: t >= m.focus ? 'editor' : 'browser',
		pasted: t >= m.paste,
		// Steady while typing, blinking when idle, as a text field's is.
		caretOn: t - m.paste < 500 && t >= m.paste ? true : Math.floor(t / 530) % 2 === 0,
		panel,
		formats,
		hover: panel > 0 ? hovered(pointer, formats) : null,
		card: copied
	};
}
