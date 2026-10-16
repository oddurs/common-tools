// The Common Stats demo: the menu bar item up close, its menu of live graphs, hover read-back, a
// busy moment, and the item's styles. Readings are synthetic but shaped like the real thing: a
// quiet machine with one busy stretch. The scene is a pure function of time, so the recorder can
// step through it frame by frame.

import { extrasRight, menuBarHeight, screen, viewport, wide } from '../mac/geometry';
import {
	along,
	cameraAt,
	captionAt,
	clamp,
	clampCamera,
	clickPulse,
	loopOpacity,
	noise,
	ramp,
	type Camera,
	type Point
} from '../scene';

export type Metric = 'cpu' | 'gpu' | 'memory' | 'network' | 'disk' | 'storage' | 'battery';
export type Style = 'value' | 'graph' | 'graphValue' | 'gauge' | 'gaugeValue';
export type BarItem = { metric: Metric; style: Style };

/** Three arrangements a user might pick in Settings; the first is what the demo machine uses. */
export const layouts: BarItem[][] = [
	[
		{ metric: 'cpu', style: 'graphValue' },
		{ metric: 'memory', style: 'gaugeValue' },
		{ metric: 'network', style: 'value' }
	],
	[
		{ metric: 'cpu', style: 'gaugeValue' },
		{ metric: 'gpu', style: 'gaugeValue' },
		{ metric: 'memory', style: 'gaugeValue' },
		{ metric: 'disk', style: 'graphValue' },
		{ metric: 'battery', style: 'gaugeValue' }
	],
	[
		{ metric: 'cpu', style: 'graph' },
		{ metric: 'gpu', style: 'graph' },
		{ metric: 'memory', style: 'value' },
		{ metric: 'network', style: 'graph' }
	]
];

export type Readings = {
	cpu: number;
	user: number;
	system: number;
	gpu: number;
	memory: number;
	down: number;
	up: number;
	read: number;
	write: number;
	cores: number[];
	/** Oldest first, one per sample. */
	cpuHistory: number[];
	netHistory: number[];
	diskHistory: number[];
};

export type Frame = {
	opacity: number;
	caption: string;
	camera: Camera;
	cursor: Point;
	pulse: number;
	/** 0 closed, 1 open, for the menu's entrance and exit. */
	menu: number;
	/** The sample under the pointer in the CPU graph, counted back from now, or null when not hovering. */
	hover: number | null;
	layout: number;
	/** 0 to 1 as the closing card comes up. */
	end: number;
	readings: Readings;
};

const sampleEvery = 500;
export const historyLength = 64;
const spike = { from: 10_600, to: 13_400 };

/** CPU load for sample n: quiet, with one busy stretch. */
function cpuSample(n: number): number {
	const t = (n - historyLength) * sampleEvery;
	const quiet = 14 + 10 * noise(n, 1) + 5 * Math.sin(n / 6);
	const busy = 78 + 16 * noise(n, 2);
	const k = clamp(Math.min((t - spike.from) / 900, (spike.to - t) / 1200));
	return quiet + (busy - quiet) * k;
}
const netSample = (n: number) => (noise(n, 3) > 0.82 ? 1.5 + 4 * noise(n, 4) : 0.05 + 0.4 * noise(n, 5));
const diskSample = (n: number) => (noise(n, 6) > 0.7 ? 20 + 120 * noise(n, 7) : 2 * noise(n, 8));

function readingsAt(t: number): Readings {
	// Start the clock well into the history, so the graphs open full.
	const now = Math.floor(t / sampleEvery) + historyLength;
	const history = (sample: (n: number) => number) =>
		Array.from({ length: historyLength }, (_, i) => sample(now - historyLength + 1 + i));
	const cpu = cpuSample(now);
	return {
		cpu,
		user: cpu * 0.36,
		system: cpu * 0.64,
		gpu: 6 + 8 * noise(now, 9) + (cpu > 50 ? 30 : 0),
		memory: 0.81 + 0.02 * noise(Math.floor(now / 8), 10),
		down: netSample(now),
		up: 0.02 + 0.2 * noise(now, 11),
		read: diskSample(now),
		write: diskSample(now + 1000) * 0.4,
		cores: Array.from({ length: 14 }, (_, i) => clamp((cpu / 100) * (0.6 + 0.8 * noise(now * 14 + i, 12)))),
		cpuHistory: history(cpuSample),
		netHistory: history(netSample),
		diskHistory: history(diskSample)
	};
}

// Where things sit on the screen, in points; Demo.svelte lays out to the same numbers.
const menuWidth = 320;
export const stage = {
	/** The item's right edge, against the system's own extras. */
	itemRight: extrasRight,
	itemCenter: { x: extrasRight - 76, y: menuBarHeight / 2 },
	menu: { x: extrasRight - menuWidth, y: menuBarHeight + 5, width: menuWidth },
	// Menu padding 7, card padding 12, header 26 + 8.
	graph: { x: extrasRight - menuWidth + 19, y: menuBarHeight + 5 + 53, width: 282, height: 64 }
};

const times = { open: 4200, hover: 6400, hoverOff: 9400, close: 13_700, styles: 14_400, end: 19_600 };
export const duration = 21_800;

const clicks = [times.open, times.close];
const g = stage.graph;
const path = [
	{ at: 2700, x: 1270, y: 250 },
	{ at: 4000, ...stage.itemCenter },
	{ at: 5600, ...stage.itemCenter },
	{ at: 6400, x: g.x + g.width - 30, y: g.y + 34 },
	{ at: 9000, x: g.x + 80, y: g.y + 38 },
	{ at: 9800, x: stage.menu.x + menuWidth + 60, y: 260 },
	{ at: 13_200, x: stage.menu.x + menuWidth + 60, y: 260 },
	{ at: 13_700, x: 1250, y: 300 },
	{ at: duration, x: 1250, y: 300 }
];

/** Close on the bar, back out for the menu, in again for the styles. */
const bar = { x: screen.width, y: 0, zoom: 2.3 };
const menuShot = { x: stage.menu.x + menuWidth / 2, y: 0, zoom: 1.08 };
const styles = { x: screen.width, y: 0, zoom: 1.85 };
const shots = [
	{ at: 0, ...wide },
	{ at: 700, ...bar },
	{ at: times.open - 300, ...menuShot },
	{ at: times.close - 100, ...styles },
	{ at: times.end - 600, ...wide }
];

const captions: [number, string][] = [
	[700, 'System stats, right in the menu bar.'],
	[times.open, 'Click for live graphs of everything.'],
	[times.hover, 'Hover a graph to read back any moment.'],
	[spike.from + 300, 'Something busy? You see it at once.'],
	[times.styles, 'Each one a value, a graph, or a gauge.']
];

/** The menu open, the graph under the pointer. */
export const posterTime = 8200;

export function frameAt(time: number): Frame {
	const t = ((time % duration) + duration) % duration;
	const cursor = along(path, t);
	const hovering = t >= times.hover && t < times.hoverOff;
	const graphX = (cursor.x - g.x) / g.width;
	return {
		opacity: loopOpacity(t, duration),
		caption: captionAt(captions, t),
		camera: clampCamera(cameraAt(shots, t), screen, viewport),
		cursor,
		pulse: clickPulse(clicks, t),
		menu: Math.min(ramp(t, times.open, 160), 1 - ramp(t, times.close, 160)),
		hover: hovering ? Math.round((1 - clamp(graphX)) * (historyLength - 1)) : null,
		layout: t < times.styles + 1200 ? 0 : t < times.styles + 3000 ? 1 : 2,
		end: ramp(t, times.end, 500),
		readings: readingsAt(t)
	};
}
