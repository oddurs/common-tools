// The Common Stats demo: the menu bar item, its menu of live graphs, hover read-back, and the
// item's styles. Readings are synthetic but shaped like the real thing: a quiet machine with one
// busy moment. The scene is a pure function of time, so the recorder can step through it.

import { along, captionAt, clamp, clickPulse, loopOpacity, noise, ramp, during, type Point } from '../scene';

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
	cursor: Point;
	pulse: number;
	/** 0 closed, 1 open, for the menu's entrance and exit. */
	menu: number;
	/** The sample under the pointer in the CPU graph, counted back from now, or null when not hovering. */
	hover: number | null;
	/** The magnified view of the bar, and which layout it shows. */
	lens: number;
	layout: number;
	readings: Readings;
};

const sampleEvery = 500;
export const historyLength = 64;
const spike = { from: 11_200, to: 14_600 };

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

// Where things sit on the 1280 × 800 stage; Demo.svelte lays out to the same numbers.
export const stage = {
	itemCenter: { x: 1094, y: 15 },
	menu: { x: 850, y: 36, width: 320 },
	graph: { x: 870, y: 92, width: 280, height: 64 }
};

const clicks = [5000, 15_400];
const path = [
	{ at: 3900, x: 700, y: 560 },
	{ at: 4900, ...stage.itemCenter },
	{ at: 7000, ...stage.itemCenter },
	{ at: 7800, x: 1120, y: 124 },
	{ at: 10_200, x: 960, y: 128 },
	{ at: 11_000, x: 1210, y: 300 },
	{ at: 14_700, x: 1210, y: 300 },
	{ at: 15_400, x: 620, y: 480 },
	{ at: 22_000, x: 620, y: 480 }
];

const captions: [number, string][] = [
	[600, 'System stats in the menu bar.'],
	[5000, 'Click for live graphs of everything.'],
	[7800, 'Hover a graph to read back any moment.'],
	[11_200, 'Something busy? You see it at once.'],
	[15_600, 'Each one a value, a graph, or a gauge.']
];

export const duration = 21_600;

/** The menu open, the graph under the pointer. */
export const posterTime = 9000;

export function frameAt(time: number): Frame {
	const t = ((time % duration) + duration) % duration;
	const cursor = along(path, t);
	const hovering = t >= 7800 && t < 10_700;
	const graphX = (cursor.x - stage.graph.x) / stage.graph.width;
	return {
		opacity: loopOpacity(t, duration),
		caption: captionAt(captions, t),
		cursor,
		pulse: clickPulse(clicks, t),
		menu: Math.min(ramp(t, clicks[0], 160), 1 - ramp(t, clicks[1], 160)),
		hover: hovering ? Math.round((1 - clamp(graphX)) * (historyLength - 1)) : null,
		lens: Math.max(during(t, 700, 4200, 300), during(t, 15_800, duration - 500, 300)),
		layout: t < 17_600 ? 0 : t < 19_400 ? 1 : 2,
		readings: readingsAt(t)
	};
}
