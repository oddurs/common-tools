// The Common Command demo: writing in Notes, ⌥Space opens the panel above it, floating over the
// desktop without taking Notes out of the front, three letters find Calendar, "dark mode" finds the Appearance pane, and a
// conversion's Return copies the answer, which ⌘V pastes into the note.
//
// Every list the panel shows is the app's own: `results.ts` holds what CommandKit's
// `Results.compose` returns for each prefix typed. The metrics are `PanelSize.medium`
// (CommandKit/Layout.swift), the place is PanelController's, a fifth of the way down the screen,
// centred, and the panel fades in over 120 ms and closes at once, as `show()` and `hide()` do.
//
// The scene is a pure function of time, so the recorder can step through it frame by frame.

import { direct, type BaseFrame } from '../film/director';
import { menuBarHeight, screen } from '../mac/geometry';
import { results, type Section } from './results';

/** PanelSize.medium. */
export const size = {
	width: 560,
	field: 50,
	fieldFont: 20,
	row: 34,
	rowFont: 14,
	header: 34 * 0.75,
	icon: 24,
	gap: 8,
	padding: 7,
	visibleRows: 8
};

/** The card's height for these sections, scrolling past eight rows, as `PanelSize.cardHeight`. */
export function cardHeight(sections: Section[]): number {
	const rows = sections.reduce((sum, s) => sum + s.rows.length, 0);
	if (rows === 0) return 0;
	const content = rows * size.row + sections.length * size.header;
	const cap = size.visibleRows * size.row + 2 * size.header;
	return Math.min(content, cap) + 2 * size.padding;
}

/** The screen without the menu bar: what `NSScreen.visibleFrame` gives with the Dock hidden. */
const visible = { top: menuBarHeight, height: screen.height - menuBarHeight };
export const panel = {
	x: Math.round(screen.width / 2 - size.width / 2),
	y: Math.round(visible.top + visible.height * 0.2)
};

/**
 * Notes sits low and to the left, so the panel floats over the desktop and covers only Notes' corner:
 * it reads as something above every app, not a part of Notes.
 */
export const notes = { x: 250, y: 410, width: 500, height: 480 };
/** The note as it starts, and what the end of the film adds to its last line. */
export const note = {
	title: 'Saturday hike',
	lines: ['Meet at the trailhead at 8:00.', 'Bring water, lunch, and a warm layer.'],
	last: 'The loop is 10 km, about ',
	pasted: '6.21371',
	typed: ' miles.'
};

const fadeIn = 120;

type Edit = { at: number; query: string; selectAll?: boolean };

/** A key every 150 ms or so, unevenly, the same every run, so it reads as a person typing. */
const jitter = [0, 30, -15, 20, -25, 10, 35, -10, 15, -20, 25];
const keyInterval = 150;

function typing(from: number, text: string, edits: Edit[]): number {
	let at = from;
	for (let i = 1; i <= text.length; i++) {
		edits.push({ at, query: text.slice(0, i) });
		at += keyInterval + jitter[i % jitter.length];
	}
	return at;
}

const edits: Edit[] = [];
const noteEdits: { at: number; text: string }[] = [];

/** The whole desk: the menu bar, Notes, and room for the panel over it. */
const desk = { x: 880, y: 440, zoom: 0.85 };
const medium = { x: 880, y: 400, zoom: 1 };
/** In on the panel, with wallpaper round it and Notes' corner behind its lower left. */
const onPanel = { x: 820, y: 430, zoom: 1.45 };
const onNote = { x: notes.x + 250, y: notes.y + 150, zoom: 1.6 };

export const film = direct((d) => {
	d.camera(desk);
	d.at(400).camera(medium);
	d.at(500).caption('⌥Space opens Command over any app.');
	d.at(1200).hold('option', 'Space');
	d.at(1350).mark('open');
	d.at(1700).release();
	d.at(1900).camera(onPanel);

	d.at(2300).caption('Three letters, and Calendar is the Top Hit.');
	d.at(2600).mark('cal');
	d.now = typing(d.now, 'cal', edits);
	d.mark('calTyped');
	// Calendar, Calculator, two Settings topics, and the web: every group at once.
	d.wait(700).poster();

	d.at(4900).caption('Settings by topic: “dark mode” finds Appearance.');
	d.at(5000).hold('command', 'A');
	d.at(5100).mark('selectDark');
	edits.push({ at: d.now, query: 'cal', selectAll: true });
	d.at(5300).release();
	d.at(5500).mark('dark');
	d.now = typing(d.now, 'dark mode', edits);
	d.mark('darkTyped');

	d.at(8600).caption('Sums and conversions: Return copies the answer.');
	d.at(8700).hold('command', 'A');
	d.at(8800).mark('selectSum');
	edits.push({ at: d.now, query: 'dark mode', selectAll: true });
	d.at(9000).release();
	d.at(9200).mark('sum');
	d.now = typing(d.now, '10 km to mi', edits);
	d.mark('sumTyped');

	d.wait(1100).hold('Return');
	d.wait(80).mark('close').camera(onNote);
	d.wait(250).release();

	d.wait(650).hold('command', 'V');
	d.wait(120).mark('paste');
	noteEdits.push({ at: d.now, text: note.pasted });
	d.wait(250).release();
	d.wait(350);
	for (const [i, char] of [...note.typed].entries()) {
		d.wait(keyInterval + jitter[(i + 3) % jitter.length]);
		noteEdits.push({ at: d.now, text: char });
	}
	d.mark('typed');
	d.wait(500).camera(desk);
	d.wait(1000).caption('');
	d.end(2600);
});

const marks = film.marks;

export type Frame = BaseFrame & {
	/** 0 hidden, 1 shown. */
	panel: number;
	query: string;
	/** ⌘A has selected the query, so the next key replaces it. */
	selectAll: boolean;
	sections: Section[];
	/** What has been added to the note's last line. */
	added: string;
	/** Whether the note's caret shows: only while Notes' window is key, and blinking when idle. */
	noteCaret: boolean;
	/** The field's caret, blinking when idle. */
	fieldCaret: boolean;
};

const blink = (t: number, since: number) => t - since < 500 || Math.floor((t - since) / 530) % 2 === 0;

export function frameAt(time: number): Frame {
	const base = film.frame(time);
	const { t } = base;
	const shown = t >= marks.open && t < marks.close;
	let query = '';
	let selectAll = false;
	let lastKey = marks.open;
	for (const edit of edits) {
		if (edit.at > t) break;
		query = edit.query;
		selectAll = !!edit.selectAll;
		lastKey = edit.at;
	}
	let added = '';
	let lastNoteKey = marks.close;
	for (const edit of noteEdits) {
		if (edit.at > t) break;
		added += edit.text;
		lastNoteKey = edit.at;
	}
	const sections = results[query] ?? [];
	return {
		...base,
		panel: shown ? Math.min(1, (t - marks.open) / fadeIn) : 0,
		query,
		selectAll,
		sections,
		added,
		noteCaret: !shown && blink(t, t < marks.open ? 0 : lastNoteKey),
		fieldCaret: !selectAll && blink(t, lastKey)
	};
}

/** Every query the film types, for the test that each has the app's results. */
export const typed = [...new Set(edits.map((edit) => edit.query))];
