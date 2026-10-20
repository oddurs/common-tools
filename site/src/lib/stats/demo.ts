// The Common Stats demo: the menu bar item up close, its menu of live graphs, hover read-back, a
// busy moment, and the item's styles. Readings are synthetic but shaped like the real thing: a
// quiet machine with one busy stretch. The scene is a pure function of time, so the recorder can
// step through it frame by frame.

import { direct, type BaseFrame } from '../film/director';
import { clamp, noise, ramp } from '../film/motion';
import { extrasRight, menuBarHeight, screen, statusPadding, wide } from '../mac/geometry';

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

export type Frame = BaseFrame & {
	/** 0 closed, 1 open, for the menu's entrance and exit. */
	menu: number;
	/** The sample under the pointer in the CPU graph, counted back from now, or null when not hovering. */
	hover: number | null;
	layout: number;
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
		cores: Array.from({ length: 14 }, (_, i) =>
			clamp((cpu / 100) * (0.6 + 0.8 * noise(now * 14 + i, 12)))
		),
		cpuHistory: history(cpuSample),
		netHistory: history(netSample),
		diskHistory: history(diskSample)
	};
}

// Where things sit on the screen, in points; Demo.svelte lays out to the same numbers.
const menuWidth = 320;
/** The item: 163 points of cells (see Bar.svelte) and the status item's padding either side. */
const itemWidth = 163 + 2 * statusPadding;
const itemLeft = extrasRight - itemWidth;
export const stage = {
	/** The item's right edge, against the system's own extras. */
	itemRight: extrasRight,
	itemCenter: { x: itemLeft + itemWidth / 2, y: menuBarHeight / 2 },
	// A status item's menu opens under its left edge.
	menu: { x: itemLeft, y: menuBarHeight + 5, width: menuWidth },
	// Menu padding 7, card padding 12, header 26 + 8.
	graph: { x: itemLeft + 19, y: menuBarHeight + 5 + 53, width: 282, height: 64 }
};

const g = stage.graph;
const parked = { x: stage.menu.x + menuWidth + 60, y: 260 };
const out = { x: 1250, y: 300 };

/** Close on the bar, back out for the menu, in again for the styles. */
const bar = { x: screen.width, y: 0, zoom: 2.3 };
const menuShot = { x: stage.menu.x + menuWidth / 2, y: 0, zoom: 1.08 };
const styles = { x: screen.width, y: 0, zoom: 1.85 };

export const film = direct((d) => {
	d.camera(wide);
	d.at(700).camera(bar).caption('System stats, right in the menu bar.');
	d.at(2700).point({ x: 1270, y: 250 });
	d.at(3900).camera(menuShot);
	d.at(4000).point(stage.itemCenter);
	d.at(4200).click().mark('open').caption('Click for live graphs of everything.');
	d.at(5600).point(stage.itemCenter);
	d.at(6400)
		.point({ x: g.x + g.width - 30, y: g.y + 34 })
		.mark('hover');
	d.caption('Hover a graph to read back any moment.');
	d.at(8200).poster();
	d.at(9000).point({ x: g.x + 80, y: g.y + 38 });
	d.at(9400).mark('hoverOff');
	d.at(9800).point(parked);
	d.at(spike.from + 300).caption('Something busy? You see it at once.');
	d.at(13_200).point(parked);
	d.at(13_600).camera(styles);
	d.at(13_700).point(out).click().mark('close');
	d.at(14_400).mark('styles').caption('Each one a value, a graph, or a gauge.');
	d.at(19_000).camera(wide);
	d.at(19_600).end(2200);
});

const m = film.marks;

export function frameAt(time: number): Frame {
	const base = film.frame(time);
	const { t } = base;
	const hovering = t >= m.hover && t < m.hoverOff;
	const graphX = (base.cursor!.x - g.x) / g.width;
	return {
		...base,
		menu: Math.min(ramp(t, m.open, 160), 1 - ramp(t, m.close, 160)),
		hover: hovering ? Math.round((1 - clamp(graphX)) * (historyLength - 1)) : null,
		layout: t < m.styles + 1200 ? 0 : t < m.styles + 3000 ? 1 : 2,
		readings: readingsAt(t)
	};
}
