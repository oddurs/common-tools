// The Common Bar demo, in the app's default setup: a crowded menu bar, tidied
// with one click on the chevron, revealed by hover, and rearranged by ⌘-dragging an icon past the
// chevron. Sizes and glyphs are the app's own (Glyphs.swift, MenuBarController). The optional always-hidden section is off
// by default, so it isn't shown. The scene is a pure function of time, so the recorder can step
// through it.

import { direct, type BaseFrame } from '../film/director';
import { clamp, ramp, type Point } from '../film/motion';
import { extrasRight, menuBarHeight, screen, statusSlot, wide } from '../mac/geometry';
import type { SymbolName } from '../mac/symbols';

export type Section = 'hidden' | 'visible';

/** Left to right as they start out: other apps' menu bar icons. Hidden ones sit left of the chevron. */
const initial: [SymbolName, Section][] = [
	['cup.and.saucer.fill', 'hidden'],
	['gauge.with.dots.needle.33percent', 'hidden'],
	['timer', 'hidden'],
	['globe', 'hidden'],
	['headphones', 'hidden'],
	['calendar', 'hidden'],
	['keyboard', 'hidden'],
	['drop.fill', 'hidden'],
	['lock.fill', 'hidden'],
	['video.fill', 'hidden'],
	['shippingbox.fill', 'hidden'],
	['bolt.fill', 'hidden'],
	['eye', 'hidden'],
	['paperclip', 'hidden'],
	['music.note', 'visible'],
	['message.fill', 'visible'],
	['icloud.fill', 'visible']
];

export type Placed = { symbol: SymbolName; x: number; opacity: number; lifted?: boolean };
export type Frame = BaseFrame & {
	icons: Placed[];
	chevron: { x: number; open: boolean };
	/** The hairline marking where hidden icons begin, shown only while ⌘ is held. */
	line: { x: number; opacity: number };
};

export const metrics = {
	right: extrasRight,
	slot: statusSlot,
	/** The chevron item: 10 pt long (Glyphs.swift), 26 pt on screen with the menu bar's padding. */
	chevron: 26,
	/** The divider while arranging: a 4 pt marker item (DividerLayout), 20 pt on screen. */
	marker: 20
};

const dragged: SymbolName = 'music.note';

/** How far the hidden icons are revealed, 0 (pushed away) to 1 (in place), at time t. */
function reveal(t: number): number {
	const open = (from: number, to: number) => Math.min(ramp(t, from, 220), 1 - ramp(t, to, 220));
	return Math.max(
		1 - ramp(t, marks.collapse, 260),
		open(marks.hoverIn, marks.hoverOut),
		open(marks.command + 200, marks.commandUp)
	);
}

function order(t: number): [SymbolName, Section][] {
	if (t < marks.pickUp) return initial;
	const rest = initial.filter(([symbol]) => symbol !== dragged);
	if (t < marks.drop) return rest;
	// Dropped just left of the chevron: hidden from now on.
	const at = rest.findIndex(([, section]) => section === 'visible');
	return [...rest.slice(0, at), [dragged, 'hidden'], ...rest.slice(at)];
}

/** Lays the items out from the right edge, as the menu bar does. */
function layout(t: number, cursor: Point): Pick<Frame, 'icons' | 'chevron' | 'line'> {
	const r = reveal(t);
	const arranging = Math.min(ramp(t, marks.command + 200, 220), 1 - ramp(t, marks.commandUp, 220));
	const m = metrics;
	let x = m.right;
	const items = [...order(t)].reverse();
	const icons: Placed[] = [];
	for (const [symbol, section] of items) {
		if (section !== 'visible') continue;
		x -= m.slot;
		icons.push({ symbol, x, opacity: 1 });
	}
	x -= m.chevron;
	const chevron = { x, open: r > 0.5 };
	// The divider beside the chevron takes no room until ⌘ is held; then it opens to a marker.
	x -= m.marker * arranging;
	const line = { x, opacity: arranging };
	for (const [symbol, section] of items) {
		if (section !== 'hidden') continue;
		x -= m.slot;
		// Collapsing stretches that divider, pushing these off the screen.
		icons.push({ symbol, x: x - (1 - r) * 700, opacity: clamp(r * 1.4 - 0.2) });
	}
	if (t >= marks.pickUp && t < marks.drop) {
		icons.push({ symbol: dragged, x: cursor.x - m.slot / 2 - 6, opacity: 1, lifted: true });
	}
	return { icons, chevron, line };
}

const y = menuBarHeight / 2;
const chevronAt = (visible: number) => ({
	x: metrics.right - visible * metrics.slot - metrics.chevron / 2 + 2,
	y: y + 3
});
// The dragged icon starts as the leftmost visible one, and lands just left of the chevron.
const pickAt = { x: metrics.right - 2.5 * metrics.slot, y };
// Past the hairline, not just past the chevron: icons dropped between the two stay visible.
const dropAt = {
	x: metrics.right - 2 * metrics.slot - metrics.chevron - metrics.marker - metrics.slot / 2 - 4,
	y
};
const crowded = { x: screen.width, y: 0, zoom: 1.25 };
const close = { x: screen.width, y: 0, zoom: 2.0 };

/** In on the right of the menu bar, wide enough to show the crowd at first, closer for the details. */
export const film = direct((d) => {
	d.camera(wide);
	d.at(500).camera(crowded);
	d.at(600).caption('A full menu bar: every app wants a spot.');
	d.at(3000).point({ x: 1300, y: 300 });
	d.at(4100).point(chevronAt(3));
	d.at(4200).click().mark('collapse').caption('One click on the chevron tucks the extras away.');
	d.at(4700).camera(close);
	d.at(6000).point(chevronAt(3));
	d.at(6800).caption('Hover, scroll, or click again to bring them back.');
	d.at(6900).point({ x: 1100, y: y + 2 });
	d.at(7200).mark('hoverIn');
	d.at(8800).point({ x: 1100, y: y + 2 });
	d.at(9300).mark('hoverOut');
	d.at(9400).point({ x: 1150, y: 260 });
	d.at(10_100)
		.mark('command')
		.hold('command')
		.caption('Hold ⌘ and drag an icon past the chevron to hide it.');
	d.at(10_200).point({ x: 1300, y: 200 });
	d.at(10_800).point(pickAt);
	d.at(10_900).mark('pickUp');
	d.at(11_600).poster();
	d.at(12_100).point(dropAt);
	d.at(12_200).mark('drop');
	d.at(12_700).point(dropAt).mark('commandUp').release();
	d.at(13_600).point({ x: 1300, y: 280 });
	d.at(14_200).camera(wide);
	d.at(14_800).end(2600);
});

const marks = film.marks;

export function frameAt(time: number): Frame {
	const base = film.frame(time);
	return { ...base, ...layout(base.t, base.cursor!) };
}
