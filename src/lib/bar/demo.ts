// The Common Bar demo, in the app's default setup: a crowded menu bar on a notched display, tidied
// with one click on the chevron, revealed by hover, and rearranged by ⌘-dragging an icon past the
// chevron. Sizes and glyphs are the app's own (Glyphs.swift, MenuBarController). The optional always-hidden section is off
// by default, so it isn't shown. The scene is a pure function of time, so the recorder can step
// through it.

import { extrasRight, menuBarHeight, notch, screen, statusSlot, viewport, wide } from '../mac/geometry';
import type { SymbolName } from '../mac/symbols';
import {
	along,
	cameraAt,
	captionAt,
	clamp,
	clampCamera,
	clickPulse,
	loopOpacity,
	ramp,
	type Camera,
	type Point
} from '../scene';

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
export type Frame = {
	opacity: number;
	caption: string;
	camera: Camera;
	cursor: Point;
	pulse: number;
	icons: Placed[];
	chevron: { x: number; open: boolean };
	keys: SymbolName[];
	end: number;
};

export const metrics = {
	right: extrasRight,
	slot: statusSlot,
	/** The chevron item: 10 pt long (Glyphs.swift), 26 pt on screen with the menu bar's padding. */
	chevron: 26,
	notch
};

const dragged: SymbolName = 'music.note';
const times = {
	collapse: 4200,
	hoverIn: 7200,
	hoverOut: 9300,
	command: 10_100,
	pickUp: 10_900,
	drop: 12_200,
	commandUp: 12_700,
	end: 14_800
};
export const duration = 17_400;

/** How far the hidden icons are revealed, 0 (pushed away) to 1 (in place), at time t. */
function reveal(t: number): number {
	const open = (from: number, to: number) => Math.min(ramp(t, from, 220), 1 - ramp(t, to, 220));
	return Math.max(
		1 - ramp(t, times.collapse, 260),
		open(times.hoverIn, times.hoverOut),
		open(times.command + 200, times.commandUp)
	);
}

function order(t: number): [SymbolName, Section][] {
	if (t < times.pickUp) return initial;
	const rest = initial.filter(([symbol]) => symbol !== dragged);
	if (t < times.drop) return rest;
	// Dropped just left of the chevron: hidden from now on.
	const at = rest.findIndex(([, section]) => section === 'visible');
	return [...rest.slice(0, at), [dragged, 'hidden'], ...rest.slice(at)];
}

/** Lays the items out from the right edge, as the menu bar does. */
function layout(t: number, cursor: Point): Pick<Frame, 'icons' | 'chevron'> {
	const r = reveal(t);
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
	for (const [symbol, section] of items) {
		if (section !== 'hidden') continue;
		x -= m.slot;
		// Collapsing stretches an invisible divider beside the chevron, pushing these off the screen.
		icons.push({ symbol, x: x - (1 - r) * 700, opacity: clamp(r * 1.4 - 0.2) });
	}
	if (t >= times.pickUp && t < times.drop) {
		icons.push({ symbol: dragged, x: cursor.x - m.slot / 2 - 6, opacity: 1, lifted: true });
	}
	return { icons, chevron };
}

const y = menuBarHeight / 2;
const chevronAt = (visible: number) => ({
	x: metrics.right - visible * metrics.slot - metrics.chevron / 2 + 2,
	y: y + 3
});
// The dragged icon starts as the leftmost visible one, and lands just left of the chevron.
const pickAt = { x: metrics.right - 2.5 * metrics.slot, y };
const dropAt = { x: metrics.right - 2 * metrics.slot - metrics.chevron - metrics.slot / 2 - 4, y };
const clicks = [times.collapse];

const path = [
	{ at: 3000, x: 1300, y: 300 },
	{ at: 4100, ...chevronAt(3) },
	{ at: 6000, ...chevronAt(3) },
	{ at: 6900, x: 1100, y: y + 2 },
	{ at: 8800, x: 1100, y: y + 2 },
	{ at: 9400, x: 1150, y: 260 },
	{ at: 10_200, x: 1300, y: 200 },
	{ at: 10_800, ...pickAt },
	{ at: 12_100, ...dropAt },
	{ at: 12_700, ...dropAt },
	{ at: 13_600, x: 1300, y: 280 },
	{ at: duration, x: 1300, y: 280 }
];

/** In on the right of the menu bar, wide enough to show the notch at first, closer for the details. */
const crowded = { x: screen.width, y: 0, zoom: 1.25 };
const close = { x: screen.width, y: 0, zoom: 2.0 };
const shots = [
	{ at: 0, ...wide },
	{ at: 500, ...crowded },
	{ at: times.collapse + 500, ...close },
	{ at: times.end - 600, ...wide }
];

const captions: [number, string][] = [
	[600, 'A full menu bar, and some icons are lost behind the notch.'],
	[times.collapse, 'One click on the chevron tucks the extras away.'],
	[6800, 'Hover, scroll, or click again to bring them back.'],
	[times.command, 'Hold ⌘ and drag an icon past the chevron to hide it.']
];

/** Holding ⌘, mid-drag: everything showing, an icon on its way past the chevron. */
export const posterTime = 11_600;

export function frameAt(time: number): Frame {
	const t = ((time % duration) + duration) % duration;
	const cursor = along(path, t);
	return {
		opacity: loopOpacity(t, duration),
		caption: captionAt(captions, t),
		camera: clampCamera(cameraAt(shots, t), screen, viewport),
		cursor,
		pulse: clickPulse(clicks, t),
		keys: t >= times.command && t < times.commandUp ? ['command'] : [],
		end: ramp(t, times.end, 500),
		...layout(t, cursor)
	};
}
