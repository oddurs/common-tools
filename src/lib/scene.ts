// Helpers for the scripted demo scenes. A scene is a pure function of time, so the recorder can
// step through it frame by frame and get the same video every run.

export const fadeFor = 600;

export const clamp = (x: number, lo = 0, hi = 1) => Math.min(hi, Math.max(lo, x));

export const ease = (x: number) => {
	const t = clamp(x);
	return t < 0.5 ? 4 * t * t * t : 1 - (-2 * t + 2) ** 3 / 2;
};

/** 0 before `from`, 1 after `from + over`, eased between. */
export const ramp = (t: number, from: number, over: number) => ease((t - from) / over);

/** Fades in at `from` and out at `to`. */
export const during = (t: number, from: number, to: number, over = 250) =>
	Math.min(ramp(t, from, over), 1 - ramp(t, to - over, over));

/** A stable pseudo-random number in [0, 1) for an integer, so "live" data is identical every run. */
export function noise(n: number, seed = 0): number {
	let x = (Math.imul(n | 0, 0x9e3779b1) ^ Math.imul(seed + 1, 0x85ebca6b)) >>> 0;
	x = Math.imul(x ^ (x >>> 16), 0x7feb352d) >>> 0;
	x = Math.imul(x ^ (x >>> 15), 0x846ca68b) >>> 0;
	return ((x ^ (x >>> 16)) >>> 0) / 4294967296;
}

export type Point = { x: number; y: number };
export type Waypoint = Point & { at: number };

/** Where a pointer following `path` is at time t: it rests at each waypoint and glides between them. */
export function along(path: Waypoint[], t: number): Point {
	if (t <= path[0].at) return path[0];
	for (let i = 1; i < path.length; i++) {
		const [a, b] = [path[i - 1], path[i]];
		if (t <= b.at) {
			const k = ease((t - a.at) / (b.at - a.at));
			return { x: a.x + (b.x - a.x) * k, y: a.y + (b.y - a.y) * k };
		}
	}
	return path[path.length - 1];
}

/** The caption showing at time t, from [start, text] pairs in order. */
export function captionAt(captions: [number, string][], t: number): string {
	let text = '';
	for (const [at, caption] of captions) if (t >= at) text = caption;
	return text;
}

/** Whole-loop opacity: fade in from black at the start, out at the end. */
export const loopOpacity = (t: number, duration: number) =>
	clamp(Math.min(t / fadeFor, (duration - t) / fadeFor));

/** How far into a click's pulse t is, 0..1, or 0 when no click is in progress. */
export function clickPulse(clicks: number[], t: number, over = 260): number {
	for (const at of clicks) if (t >= at && t < at + over) return 1 - (t - at) / over;
	return 0;
}
