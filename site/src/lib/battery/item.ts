// The menu bar item's geometry, ported from BatteryKit's BarRenderer so the film draws it where the
// app does: each part's fixed width, the 4-point gap, and the whole reading centred by its ink in the
// item, on whole points. Text is 12-point monospaced digits; the advances and ink extents below were
// measured with NSFont and CTLineGetImageBounds, as BarRenderer measures them.

export type Part = 'time' | 'percent' | 'battery';
export type ChargeState = 'charging' | 'discharging';

/** What the item draws from: the level, what the battery is doing, and the time it shows. */
export type Reading = {
	/** 0 to 1. */
	level: number;
	state: ChargeState;
	/** Minutes to full or to empty; null while macOS is still estimating, drawn as a dash. */
	minutes: number | null;
};

/** The film's arrangement, one a user picks in Settings: the time, the percentage, the icon. */
export const parts: Part[] = ['time', 'percent', 'battery'];

export const height = 24;
const gap = 4;

/** SF Pro at 12 points, monospaced digits: advance and the glyphs' own left and right extent. */
const text: Record<string, { advance: number; ink: [number, number] }> = {
	'88:88': { advance: 33.797, ink: [0.744, 33.053] },
	'100%': { advance: 33.779, ink: [1.67, 32.988] },
	'0:52': { advance: 26.238, ink: [0.791, 25.195] },
	'0:50': { advance: 26.238, ink: [0.791, 25.447] },
	'6:18': { advance: 26.238, ink: [0.738, 25.494] },
	'–': { advance: 7.002, ink: [0.475, 6.527] },
	'79%': { advance: 26.221, ink: [0.838, 25.43] },
	'80%': { advance: 26.221, ink: [0.744, 25.43] }
};
export const font = { size: 12, capHeight: 8.455 };
/** Where the text's baseline sits: BarRenderer's (height + capHeight) / 2. */
export const baseline = (height + font.capHeight) / 2;

/** The plain icon: a 23 × 11.5 body, a 1-point gap, and a 1.5 × 4.5 nub. */
export const icon = {
	body: { width: 23, height: 11.5 },
	nubGap: 1,
	nub: { width: 1.5, height: 4.5 },
	/** The outline and nub's share of the ink. */
	outline: 0.45
};
const iconWidth = icon.body.width + icon.nubGap + icon.nub.width;

function measure(s: string) {
	const m = text[s];
	if (!m) throw new Error(`'${s}' hasn't been measured; add it to item.ts`);
	return m;
}

/** The item's image width: the widest each part can be, whatever the reading. */
export const width = Math.ceil(
	measure('88:88').advance + measure('100%').advance + iconWidth + gap * (parts.length - 1)
);

/** "0:52", as Format.duration writes it; a dash while there's no estimate. */
export const duration = (minutes: number | null) =>
	minutes === null ? '–' : `${Math.floor(minutes / 60)}:${String(minutes % 60).padStart(2, '0')}`;

export const percent = (level: number) => `${Math.round(level * 100)}%`;

export type Piece = { part: Part; x: number; text?: string };

/** Each part's x in the item, as BarRenderer.positions places them. */
export function layout(reading: Reading): Piece[] {
	const pieces = parts.map((part) => {
		if (part === 'battery') return { part, advance: iconWidth, ink: [0, iconWidth] as const };
		const s = part === 'time' ? duration(reading.minutes) : percent(reading.level);
		const m = measure(s);
		return { part, text: s, advance: m.advance, ink: m.ink };
	});
	const xs = [0];
	for (const piece of pieces.slice(0, -1)) xs.push(Math.round(xs[xs.length - 1] + piece.advance + gap));
	const lo = pieces[0].ink[0];
	const hi = xs[xs.length - 1] + pieces[pieces.length - 1].ink[1];
	// Swift's .rounded() rounds half away from zero; offsets here are positive, so Math.round agrees.
	const offset = Math.round((width - (hi - lo)) / 2 - lo);
	return pieces.map((piece, i) => ({ part: piece.part, x: xs[i] + offset, text: piece.text }));
}

/** BarRenderer's bolt, in a unit square, y down; drawn 0.62 times as wide as it is tall. */
export const bolt: [number, number][] = [
	[0.64, 0],
	[0.06, 0.58],
	[0.44, 0.58],
	[0.34, 1],
	[0.94, 0.4],
	[0.56, 0.4]
];
export const boltAspect = 0.62;
