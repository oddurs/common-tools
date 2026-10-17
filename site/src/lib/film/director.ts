// The film engine. A scene is written as a script of beats on a clock: where the camera goes, where
// the pointer goes, when it clicks, which keys are held, what the caption says, when the closing
// card comes up. `direct` turns the script into a Film, whose frame at any moment is a pure
// function of time, so the recorder can step through it and get the same video every run.
//
//   export const film = direct((d) => {
//     d.camera(wide);
//     d.at(700).camera(closeUp).caption('System stats, right in the menu bar.');
//     d.at(2700).point({ x: 1270, y: 250 });
//     d.at(4000).point(item).wait(200).click().mark('open');
//     d.at(19_600).end(2200);
//   });
//
// Scenes add their own state on top (menus, readings, typed text) by reading the film's marks.

import { screen, viewport } from '../mac/geometry';
import type { SymbolName } from '../mac/symbols';
import {
	along,
	cameraAt,
	captionAt,
	clampCamera,
	clickPulse,
	loopOpacity,
	ramp,
	type Camera,
	type Point,
	type Shot,
	type Waypoint
} from './motion';

/** What every film draws, whatever the scene: the parts the engine owns. */
export type BaseFrame = {
	/** Time into the loop, in ms. */
	t: number;
	opacity: number;
	camera: Camera;
	/** Null when the scene has no pointer. */
	cursor: Point | null;
	pulse: number;
	caption: string;
	/** Keys shown held down, as SF Symbol names or plain labels. */
	keys: (SymbolName | string)[];
	/** 0 to 1 as the closing card comes up. */
	end: number;
};

export type Film = {
	duration: number;
	/** The moment the poster is taken from. */
	poster: number;
	/** Named moments, for the scene's own state and for `pnpm shot <tool> <mark>`. */
	marks: Record<string, number>;
	frame(time: number): BaseFrame;
};

/** How long the closing card takes to come up. */
const endFade = 500;

export class Director {
	/** The script's clock, in ms. Beats happen at `now`. */
	now = 0;
	readonly shots: Shot[] = [];
	readonly path: Waypoint[] = [];
	readonly clicks: number[] = [];
	readonly captions: [number, string][] = [];
	readonly keys: { from: number; to: number; keys: (SymbolName | string)[] }[] = [];
	readonly marks: Record<string, number> = {};
	posterAt: number | null = null;
	endAt: number | null = null;
	duration: number | null = null;

	/** Moves the clock to an absolute time. */
	at(ms: number): this {
		this.now = ms;
		return this;
	}

	/** Moves the clock on. */
	wait(ms: number): this {
		this.now += ms;
		return this;
	}

	/** Names this moment. */
	mark(name: string): this {
		if (name in this.marks) throw new Error(`mark '${name}' is set twice`);
		this.marks[name] = this.now;
		return this;
	}

	/** Starts the camera moving to `shot`; the first one is where it begins. */
	camera(shot: Camera): this {
		this.shots.push({ at: this.now, ...shot });
		return this;
	}

	/** The pointer arrives at `p` now, gliding from wherever it was at its previous waypoint. */
	point(p: Point): this {
		const last = this.path[this.path.length - 1];
		if (last && last.at > this.now) throw new Error(`pointer waypoints out of order at ${this.now}`);
		this.path.push({ at: this.now, x: p.x, y: p.y });
		return this;
	}

	/** Holds the pointer where it is until now, so the next `point` glides from this moment. */
	stay(): this {
		const last = this.path[this.path.length - 1];
		if (!last) throw new Error('stay() before any point()');
		return this.point(last);
	}

	click(): this {
		this.clicks.push(this.now);
		return this;
	}

	/** Shows `text` from now until the next caption; an empty string clears it. */
	caption(text: string): this {
		this.captions.push([this.now, text]);
		return this;
	}

	/** Shows keys held down from now until `release`. */
	hold(...keys: (SymbolName | string)[]): this {
		this.keys.push({ from: this.now, to: Infinity, keys });
		return this;
	}

	release(): this {
		const held = this.keys[this.keys.length - 1];
		if (!held || held.to !== Infinity) throw new Error(`release() at ${this.now} with nothing held`);
		held.to = this.now;
		return this;
	}

	/** Takes the poster from this moment. */
	poster(): this {
		this.posterAt = this.now;
		return this;
	}

	/** Brings up the closing card now and holds it for `hold` ms; the film ends there. */
	end(hold: number): this {
		this.endAt = this.now;
		this.duration = this.now + hold;
		return this;
	}
}

export function direct(script: (d: Director) => void): Film {
	const d = new Director();
	script(d);
	const { duration, endAt, posterAt } = d;
	if (duration === null || endAt === null) throw new Error('a film needs an end()');
	if (posterAt === null) throw new Error('a film needs a poster()');
	if (d.shots.length === 0) throw new Error('a film needs a camera()');
	const shots = [...d.shots].sort((a, b) => a.at - b.at);
	const path = d.path;
	const clicks = d.clicks;
	const captions = [...d.captions].sort((a, b) => a[0] - b[0]);
	const keys = d.keys;

	return {
		duration,
		poster: posterAt,
		marks: { ...d.marks },
		frame(time: number): BaseFrame {
			const t = ((time % duration) + duration) % duration;
			return {
				t,
				opacity: loopOpacity(t, duration),
				camera: clampCamera(cameraAt(shots, t), screen, viewport),
				cursor: path.length ? along(path, t) : null,
				pulse: clickPulse(clicks, t),
				caption: captionAt(captions, t),
				keys: keys.find((held) => t >= held.from && t < held.to)?.keys ?? [],
				end: ramp(t, endAt, endFade)
			};
		}
	};
}
