// The Common Bar demo: a crowded menu bar on a notched display, tidied with one click, revealed by
// hover, rearranged with ⌘-drag, and its always-hidden section opened with ⌥-click. The scene is a
// pure function of time, so the recorder can step through it.

import { along, captionAt, clamp, clickPulse, loopOpacity, ramp, type Point } from '../scene';

export type Glyph =
	| 'drop'
	| 'lock'
	| 'video'
	| 'note'
	| 'bubble'
	| 'cloud'
	| 'box'
	| 'bolt'
	| 'eye'
	| 'clip'
	| 'cup'
	| 'gauge'
	| 'globe'
	| 'timer';
export type Section = 'always' | 'hidden' | 'visible';

/** Left to right as they start out. */
const initial: [Glyph, Section][] = [
	['cup', 'always'],
	['gauge', 'always'],
	['timer', 'always'],
	['globe', 'always'],
	['drop', 'hidden'],
	['lock', 'hidden'],
	['video', 'hidden'],
	['box', 'hidden'],
	['bolt', 'hidden'],
	['eye', 'hidden'],
	['clip', 'hidden'],
	['note', 'visible'],
	['bubble', 'visible'],
	['cloud', 'visible']
];

export type Placed = { glyph: Glyph; x: number; opacity: number; lifted?: boolean };
export type Frame = {
	opacity: number;
	caption: string;
	cursor: Point;
	pulse: number;
	icons: Placed[];
	/** x of each divider, and how visible it is. */
	divider: { x: number; opacity: number };
	always: { x: number; opacity: number };
	chevron: { x: number; open: boolean };
	keys: string;
};

export const metrics = {
	right: 1280 - 18 - 70 - 3 * 30 - 6,
	slot: 30,
	divider: 14,
	chevron: 26,
	/** The camera housing: icons left of its right edge can't be seen. */
	notch: { left: 560, right: 720 }
};

const dragged: Glyph = 'note';
const times = {
	collapse: 3800,
	hoverIn: 7000,
	hoverOut: 9100,
	command: 9900,
	pickUp: 10_700,
	drop: 12_000,
	commandUp: 12_500,
	optionClick: 13_600,
	optionClose: 16_000,
	end: 17_600
};

/** Each section's reveal, 0 (pushed away) to 1 (in place), at time t. */
function reveals(t: number): { hidden: number; always: number; divider: number } {
	const open = (from: number, to: number) => Math.min(ramp(t, from, 260), 1 - ramp(t, to, 260));
	const hidden = Math.max(
		1 - ramp(t, times.collapse, 300),
		open(times.hoverIn, times.hoverOut),
		open(times.command + 200, times.commandUp),
		open(times.optionClick, times.optionClose)
	);
	const always = Math.max(
		1 - ramp(t, times.collapse, 300),
		open(times.command + 200, times.commandUp),
		open(times.optionClick, times.optionClose)
	);
	return { hidden, always, divider: open(times.command + 200, times.commandUp) };
}

function order(t: number): [Glyph, Section][] {
	if (t < times.pickUp) return initial;
	const rest = initial.filter(([g]) => g !== dragged);
	if (t < times.drop) return rest;
	// Dropped just left of the divider: hidden from now on.
	const at = rest.findIndex(([, s]) => s === 'visible');
	return [...rest.slice(0, at), [dragged, 'hidden'], ...rest.slice(at)];
}

/** Lays the items out from the right edge, as the menu bar does. */
function layout(t: number, cursor: Point): Omit<Frame, 'opacity' | 'caption' | 'cursor' | 'pulse' | 'keys'> {
	const r = reveals(t);
	const m = metrics;
	let x = m.right - m.chevron;
	const chevron = { x, open: r.hidden > 0.5 };
	const items = order(t);
	const icons: Placed[] = [];
	const place = (section: Section) => {
		for (const [glyph, s] of [...items].reverse()) {
			if (s !== section) continue;
			x -= m.slot;
			icons.push({ glyph, x, opacity: 1 });
		}
	};
	place('visible');
	x -= m.divider * r.divider;
	const divider = { x, opacity: r.divider };
	const hiddenStart = icons.length;
	place('hidden');
	const hiddenEnd = icons.length;
	x -= m.divider * r.divider;
	const always = { x, opacity: r.divider };
	place('always');
	// Collapsing stretches the divider, pushing everything left of it away.
	icons.forEach((icon, i) => {
		const reveal = i < hiddenStart ? 1 : i < hiddenEnd ? r.hidden : Math.min(r.hidden, r.always);
		icon.x -= (1 - reveal) * 700;
		icon.opacity = clamp(reveal * 1.4 - 0.2);
	});
	if (t >= times.pickUp && t < times.drop)
		icons.push({ glyph: dragged, x: cursor.x - 26, opacity: 1, lifted: true });
	return { icons, divider, always, chevron };
}

const chevronAt = { x: metrics.right - metrics.chevron / 2 + 4, y: 21 };
// Where the dragged icon starts: the rightmost visible slot but two.
const pickAt = { x: metrics.right - metrics.chevron - 3 * metrics.slot + 14, y: 15 };
const clicks = [times.collapse, times.optionClick, times.optionClose];

const path = [
	{ at: 2800, x: 960, y: 330 },
	{ at: 3700, ...chevronAt },
	{ at: 5600, ...chevronAt },
	{ at: 6600, x: 820, y: 16 },
	{ at: 8300, x: 820, y: 16 },
	{ at: 8900, x: 900, y: 260 },
	{ at: 9900, x: 980, y: 200 },
	{ at: 10_600, ...pickAt },
	{ at: 11_900, x: pickAt.x - 2 * metrics.slot - 10, y: 15 },
	{ at: 12_500, x: pickAt.x - 2 * metrics.slot - 10, y: 15 },
	{ at: 13_400, ...chevronAt },
	{ at: 15_800, ...chevronAt },
	{ at: 16_800, x: 940, y: 300 }
];

const captions: [number, string][] = [
	[600, 'A full menu bar, and some icons are lost behind the notch.'],
	[times.collapse, 'One click tucks the extras away.'],
	[6400, 'Hover, scroll, or click again to bring them back.'],
	[times.command, 'Hold ⌘ and drag icons past the line to hide them.'],
	[times.optionClick - 200, '⌥-click for the few you almost never need.']
];

export const duration = times.end;

/** Everything shown, the always-hidden section included. */
export const posterTime = 14_800;

export function frameAt(time: number): Frame {
	const t = ((time % duration) + duration) % duration;
	const cursor = along(path, t);
	const held = (from: number, to: number) => t >= from && t < to;
	let keys = '';
	if (held(times.command, times.commandUp)) keys = '⌘';
	if (
		held(times.optionClick - 300, times.optionClick + 500) ||
		held(times.optionClose - 300, times.optionClose + 500)
	)
		keys = '⌥';
	return {
		opacity: loopOpacity(t, duration),
		caption: captionAt(captions, t),
		cursor,
		pulse: clickPulse(clicks, t),
		keys,
		...layout(t, cursor)
	};
}
