// The Common Glyph demo: a picture dropped into a glyph's editor, its subject lifted and drawn as a
// silhouette, landing in the menu bar; then an emoji and a kaomoji added from the editor's
// suggestions; then one glyph's menu. Common Glyph has no snapshot command, so every view is drawn
// from its SwiftUI code (GlyphEditor, CropEditor, SettingsView, MenuBarPreview, Dropdown.swift and
// MenuBarController's menu) and measured against offscreen renders of those views. The scene is a
// pure function of time, so the recorder can step through it frame by frame.

import { direct, type BaseFrame } from '../film/director';
import { ramp } from '../film/motion';
import { extrasRight, menuBarHeight, statusPadding, wide } from '../mac/geometry';

/** What a glyph in the menu bar is showing. */
export type Source = 'star' | 'photo' | 'subject' | 'silhouette' | 'flower' | 'kaomoji';
export type GlyphID = 'mochi' | 'glyph' | 'glyph2';

/** The three glyphs, by the names Common Glyph gives them: Mochi was named by hand. */
export const names: Record<GlyphID, string> = { mochi: 'Mochi', glyph: 'Glyph', glyph2: 'Glyph 2' };

/**
 * Each source's size in the menu bar, in points. A glyph is trimmed to its visible pixels and drawn
 * 85% of the bar's 24 points tall (`Edit.scale`, `GlyphSize`), so its width follows its shape: the
 * 4:3 picture, the lifted cat, and the text glyphs as Common Glyph's own renderer trims them.
 */
export const glyphSize: Record<Source, { width: number; height: number }> = {
	star: { width: 20, height: 20 },
	photo: { width: 27, height: 20 },
	subject: { width: 15, height: 20 },
	silhouette: { width: 15, height: 20 },
	flower: { width: 20, height: 20 },
	kaomoji: { width: 59, height: 20 }
};

export type Glyph = { id: GlyphID; source: Source; entrance: number };
export type Sheet = { id: GlyphID; open: number };

export type Frame = BaseFrame & {
	/** Left to right in the menu bar. */
	glyphs: Glyph[];
	/** The editor over Settings, and how far it has come in. */
	sheet: Sheet | null;
	/** The dragged file's ghost under the pointer, and whether it is over the drop zone. */
	drag: { x: number; y: number; over: boolean } | null;
	/** 0 to 1 as the picture replaces the drop zone. */
	picture: number;
	/** How far Mochi's editor has scrolled, in points. */
	scroll: number;
	/** The Background pop-up's menu, and whether the pointer is on Lift subject. */
	popup: { opacity: number; hover: boolean };
	background: 'keep' | 'subject';
	style: 'color' | 'silhouette';
	/** The rows in Settings' Glyphs section. */
	rows: GlyphID[];
	/** The text in each text glyph's editor. */
	text: Record<'glyph' | 'glyph2', string>;
	/** Mochi's menu. */
	menu: number;
	/** The Settings window, 1 until it is closed. */
	settings: number;
};

// Where things sit on the screen, in points; Demo.svelte lays out to the same numbers.
/** The Settings window: 460 wide, as every Common Tools Settings is, with a plain title bar. */
export const win = { x: 860, y: 60, width: 460, titleBar: 32, height: 992 };
const top = win.y + win.titleBar;
/** The sheet over Settings is GlyphEditor's fixed 460 by 660; its buttons take the last 57. */
export const sheet = { height: 660, footer: 57 };

/** Mochi's editor, in the sheet's points. One glyph alone carries the "One glyph always stays" note. */
export const editor = {
	drop: { x: 30, y: 319, width: 400, height: 260 },
	/** Far enough to bring the Look section up under the source. */
	scroll: 250,
	style: { y: 711, x: 183, width: 247 },
	background: { y: 750 },
	done: { x: 416, y: 632 }
};
/** The popup's menu: three rows, the checked one over the button. */
export const popupMenu = { x: 334, width: 184, row: 24, pad: 6 };
const popupTop = editor.background.y - editor.scroll - popupMenu.pad - popupMenu.row / 2;

/** A text glyph's editor: the suggestions grid's sixth column, rows one and two. */
export const suggestions = { column: 398, row1: 356, row2: 393 };

/** Settings: the Add Glyph button under n rows. */
const addGlyph = (rows: number) => ({ x: win.x + 73, y: top + 240 + 52 * (rows - 1) });
export const desktopFile = { x: 600, y: 380 };

const at = (x: number, y: number) => ({ x: win.x + x, y: top + y });

/** A status item's width: the glyph and the system's padding either side. */
export const itemWidth = (source: Source) => glyphSize[source].width + 2 * statusPadding;

/** Mochi's item once all three glyphs are in: the leftmost, the other two right of it. */
const mochiLeft = extrasRight - itemWidth('kaomoji') - itemWidth('flower') - itemWidth('silhouette');
const mochiItem = { x: mochiLeft + itemWidth('silhouette') / 2, y: menuBarHeight / 2 };
/** Where Mochi's menu opens: under its item's left edge. */
export const menuOrigin = { x: mochiLeft, y: menuBarHeight + 5 };

export const film = direct((d) => {
	const edit = { x: 930, y: 420, zoom: 1.15 };
	d.camera(wide);
	d.at(300).camera(edit);
	d.at(600).caption('Drop a picture into Common Glyph.');
	d.at(900).point({ x: 470, y: 600 });
	// The pointer arrives, rests a beat, then clicks.
	d.at(1300).point(desktopFile);
	d.at(1500).stay().mark('grab').click();
	d.at(2800).point(at(editor.drop.x + 200, editor.drop.y + 130));
	d.at(2900).stay().mark('drop');
	d.at(3300).camera({ x: 1120, y: 560, zoom: 1.55 });
	d.at(3400).point(at(250, 420));
	d.at(3500).stay().mark('scroll');
	d.at(4300).caption('Lift the subject, and draw it like a system icon.');
	d.at(4300).point(at(398, editor.background.y - editor.scroll));
	d.at(4500).stay().mark('popup').click();
	d.at(5100).point(at(popupMenu.x + 64, popupTop + popupMenu.pad + popupMenu.row * 2.5));
	d.at(5400).stay().mark('lift').click();
	// The middle of Colour, Silhouette, Ink.
	d.at(5900).point(at(editor.style.x + editor.style.width / 2, editor.style.y - editor.scroll));
	d.at(6100).stay().mark('silhouette').click();
	d.at(6700).camera({ x: 1500, y: 0, zoom: 2.6 });
	d.at(8700).camera({ x: 1088, y: 400, zoom: 1 });
	d.at(9000).stay().caption('');
	d.at(9300).point(at(editor.done.x, editor.done.y));
	d.at(9500).stay().mark('done1').click();
	d.at(10_100).point(addGlyph(1));
	d.at(10_300).stay().mark('add1').click().caption('Add as many as you like: an emoji, a kaomoji, a word.');
	d.at(10_900).point(at(suggestions.column, suggestions.row2));
	d.at(11_200).stay().mark('flower').click();
	d.at(11_700).point(at(editor.done.x, editor.done.y));
	d.at(12_000).stay().mark('done2').click();
	d.at(12_500).point(addGlyph(2));
	d.at(12_700).stay().mark('add2').click();
	d.at(13_200).point(at(suggestions.column, suggestions.row1));
	d.at(13_500).stay().mark('kaomoji').click();
	d.at(14_000).point(at(editor.done.x, editor.done.y));
	d.at(14_300).stay().mark('done3').click();
	// Settings closes; the glyphs stay in the menu bar.
	d.at(14_800).point({ x: win.x + 20, y: win.y + 16 });
	d.at(15_000).stay().mark('closeSettings').click();
	d.at(15_100).camera({ x: 1450, y: 0, zoom: 1.9 });
	d.at(15_500).caption('Each glyph has its own menu.');
	d.at(15_900).point(mochiItem);
	d.at(16_200).stay().mark('open').click();
	d.at(16_800).point({ x: 1665, y: 210 });
	d.at(17_600).poster();
	d.at(18_100).stay();
	d.at(18_500).point({ x: 1180, y: 460 });
	d.at(18_600).stay().mark('close').click();
	d.at(18_900).camera(wide);
	d.at(19_500).end(2200);
});

const m = film.marks;

/** What each glyph shows at t. Rendering runs off the main thread, so the bar catches up a beat late. */
function glyphsAt(t: number): Glyph[] {
	const lag = 120;
	const mochi: Source =
		t < m.drop + lag
			? 'star'
			: t < m.lift + lag
				? 'photo'
				: t < m.silhouette + lag
					? 'subject'
					: 'silhouette';
	const glyphs: Glyph[] = [{ id: 'mochi', source: mochi, entrance: 1 }];
	if (t >= m.add1)
		glyphs.push({
			id: 'glyph',
			source: t < m.flower + lag ? 'star' : 'flower',
			entrance: ramp(t, m.add1 + lag, 220)
		});
	if (t >= m.add2)
		glyphs.push({
			id: 'glyph2',
			source: t < m.kaomoji + lag ? 'star' : 'kaomoji',
			entrance: ramp(t, m.add2 + lag, 220)
		});
	return glyphs;
}

function sheetAt(t: number): Sheet | null {
	const enter = 220;
	const exit = 180;
	const spans: [GlyphID, number, number][] = [
		['mochi', -Infinity, m.done1],
		['glyph', m.add1, m.done2],
		['glyph2', m.add2, m.done3]
	];
	for (const [id, from, to] of spans) {
		if (t >= from && t < to + exit) {
			const open =
				from === -Infinity
					? 1 - ramp(t, to, exit)
					: Math.min(ramp(t, from, enter), 1 - ramp(t, to, exit));
			return { id, open };
		}
	}
	return null;
}

export function frameAt(time: number): Frame {
	const base = film.frame(time);
	const { t } = base;
	const cursor = base.cursor!;
	const dragging = t >= m.grab + 120 && t < m.drop;
	const dropZone = {
		x: win.x + editor.drop.x,
		y: top + editor.drop.y,
		width: editor.drop.width,
		height: editor.drop.height
	};
	const over =
		cursor.x > dropZone.x &&
		cursor.x < dropZone.x + dropZone.width &&
		cursor.y > dropZone.y &&
		cursor.y < dropZone.y + dropZone.height;
	const liftRow = popupTop + popupMenu.pad + popupMenu.row * 2;
	const hover =
		cursor.x > win.x + popupMenu.x &&
		cursor.x < win.x + popupMenu.x + popupMenu.width &&
		cursor.y > top + liftRow &&
		cursor.y < top + liftRow + popupMenu.row;
	const rows: GlyphID[] = ['mochi'];
	if (t >= m.add1) rows.push('glyph');
	if (t >= m.add2) rows.push('glyph2');
	return {
		...base,
		glyphs: glyphsAt(t),
		sheet: sheetAt(t),
		drag: dragging ? { x: cursor.x, y: cursor.y, over } : null,
		picture: ramp(t, m.drop + 60, 200),
		scroll: editor.scroll * ramp(t, m.scroll, 500),
		popup: { opacity: Math.min(ramp(t, m.popup, 120), 1 - ramp(t, m.lift, 150)), hover },
		background: t < m.lift ? 'keep' : 'subject',
		style: t < m.silhouette ? 'color' : 'silhouette',
		rows,
		text: { glyph: t < m.flower ? '✦' : '🌸', glyph2: t < m.kaomoji ? '✦' : 'ᓚᘏᗢ' },
		menu: Math.min(ramp(t, m.open, 160), 1 - ramp(t, m.close, 140)),
		settings: 1 - ramp(t, m.closeSettings, 200)
	};
}
