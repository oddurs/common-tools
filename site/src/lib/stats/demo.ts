// The Common Stats demo: the menu bar item up close, its menu of the last three minutes, a busy
// stretch arriving live, the pointer reading back when it began, and the item's styles.
//
// Readings are synthetic but shaped like a real Mac (a 14-core M4 Pro with 24 GB, sampling once a
// second, the app's default): quiet, with one busy stretch. The menu shows a card for each metric
// in the menu bar, as StatusItemController builds it, so the bar here shows all seven. The scene is
// a pure function of time, so the recorder can step through it frame by frame.

import { direct, type BaseFrame } from '../film/director';
import { clamp, noise, ramp } from '../film/motion';
import { extrasRight, menuBarHeight, statusPadding } from '../mac/geometry';
import { barWidth, type BarItem } from './bar';

/** The demo Mac's menu bar, then three arrangements a user might pick in Settings. */
export const layouts: BarItem[][] = [
	[
		{ metric: 'cpu', style: 'graphValue' },
		{ metric: 'memory', style: 'gaugeValue' },
		{ metric: 'network', style: 'value' },
		{ metric: 'disk', style: 'value' },
		{ metric: 'gpu', style: 'value' },
		{ metric: 'storage', style: 'value' },
		{ metric: 'battery', style: 'value' }
	],
	[
		{ metric: 'cpu', style: 'value' },
		{ metric: 'gpu', style: 'value' },
		{ metric: 'memory', style: 'value' },
		{ metric: 'network', style: 'value' }
	],
	[
		{ metric: 'cpu', style: 'graph' },
		{ metric: 'gpu', style: 'graph' },
		{ metric: 'network', style: 'graph' },
		{ metric: 'disk', style: 'graph' }
	],
	[
		{ metric: 'cpu', style: 'gaugeValue' },
		{ metric: 'gpu', style: 'gaugeValue' },
		{ metric: 'memory', style: 'gaugeValue' },
		{ metric: 'battery', style: 'gaugeValue' }
	]
];

/** Readout.capacity: three minutes at one sample a second. */
export const historyLength = 180;
export const interval = 1000;
/** Four efficiency cores, then ten performance cores, as on an M4 Pro. */
export const clusters = { efficiency: 4, performance: 10 };
const gib = 1024 ** 3;
export const memoryTotal = 24 * gib;

export type Readings = {
	/** Fractions, oldest first, one per sample; the last is now. */
	cpu: number[];
	system: number[];
	gpu: number[];
	memory: number[];
	/** Bytes per second. */
	down: number[];
	up: number[];
	read: number[];
	write: number[];
	cores: number[];
	load: [number, number, number];
	memoryParts: { app: number; wired: number; compressed: number; cached: number; swap: number };
};

/** The busy stretch, in film time: the first busy sample, and the last. */
export const busy = { from: 6000, to: 16_000 };

/** How busy sample n is, 0 to 1. Sample 0 is the film's first second; earlier ones are history. */
function busyness(n: number): number {
	const t = n * interval;
	if (t < busy.from || t > busy.to + 2000) return 0;
	return clamp((busy.to + 2000 - t) / 2000);
}

/** A shorter stretch two minutes before the film starts, so the graph has a past worth reading. */
const earlier = (n: number) => (n >= -118 && n <= -96 ? 0.55 + 0.1 * noise(n, 20) : 0);

function cpuAt(n: number): number {
	const quiet = 0.09 + 0.06 * noise(n, 1) + 0.025 * Math.sin(n / 5);
	const loaded = 0.86 + 0.08 * noise(n, 2);
	const k = Math.max(busyness(n), earlier(n));
	return quiet + (loaded - quiet) * k;
}
const systemAt = (n: number) => cpuAt(n) * (0.36 - 0.12 * busyness(n)) * (0.85 + 0.3 * noise(n, 3));
const gpuAt = (n: number) => 0.1 + 0.06 * noise(n, 4) + 0.06 * Math.sin(n / 7);
const memoryAt = (n: number) => 0.826 + 0.006 * noise(Math.floor(n / 9), 5) + 0.035 * busyness(n - 3);
function downAt(n: number): number {
	if (noise(n, 6) > 0.93) return 1.2e6 + 2.4e6 * noise(n, 7);
	return 28e3 + 120e3 * noise(n, 8) ** 2;
}
const upAt = (n: number) => (noise(n, 9) > 0.95 ? 2.6e5 * noise(n, 10) : 14e3 + 40e3 * noise(n, 11));
function readAt(n: number): number {
	const k = Math.max(busyness(n), earlier(n) ? 0.6 : 0);
	const quiet = noise(n, 12) > 0.85 ? 8e6 + 30e6 * noise(n, 13) : 0.4e6 * noise(n, 14);
	return quiet + k * (60e6 + 160e6 * noise(n, 15));
}
const writeAt = (n: number) =>
	(noise(n, 16) > 0.8 ? 3e6 * noise(n, 17) : 0.2e6 * noise(n, 18)) +
	busyness(n) * (18e6 + 30e6 * noise(n, 19));

function readingsAt(t: number): Readings {
	const now = Math.floor(t / interval);
	const history = (sample: (n: number) => number) =>
		Array.from({ length: historyLength }, (_, i) => sample(now - historyLength + 1 + i));
	const cpu = history(cpuAt);
	const memory = history(memoryAt);
	// Load averages: one-, five- and fifteen-minute decaying means of runnable threads, run on from
	// well before the history starts.
	const load: [number, number, number] = [2.1, 2.3, 2.4];
	for (let n = now - 600; n <= now; n++) {
		const runnable = 14 * cpuAt(n) + 0.6;
		[60, 300, 900].forEach((span, i) => (load[i] += (runnable - load[i]) * (1 - Math.exp(-1 / span))));
	}
	const k = busyness(now);
	const used = memory[memory.length - 1] * memoryTotal;
	const wired = 4.2 * gib;
	const compressed = 7.4 * gib;
	return {
		cpu,
		system: history(systemAt),
		gpu: history(gpuAt),
		memory,
		down: history(downAt),
		up: history(upAt),
		read: history(readAt),
		write: history(writeAt),
		cores: Array.from({ length: clusters.efficiency + clusters.performance }, (_, i) => {
			const e = i < clusters.efficiency;
			const quiet = e
				? 0.22 + 0.25 * noise(now * 16 + i, 21)
				: 0.02 + 0.1 * noise(now * 16 + i, 22) ** 2;
			return quiet + (0.84 + 0.16 * noise(now * 16 + i, 23) - quiet) * k;
		}),
		load,
		memoryParts: { app: used - wired - compressed, wired, compressed, cached: 3.3 * gib, swap: 1.2 * gib }
	};
}

// Where things sit on the screen, in points; the scene lays out to the same numbers.

/** The item: its cells, as BarRenderer lays them out, and the status item's padding either side. */
export const itemWidth = (layout: number) => barWidth(layouts[layout]) + 2 * statusPadding;
const itemLeft = extrasRight - itemWidth(0);

/**
 * NSMenu's metrics on macOS 26, measured with NSMenu.size: 5 points above and below the items, 24
 * a standard item, 11 a separator. The panels are 320 wide (Tokens.Layout.menuPanelWidth), each
 * inset 8 across and 4 down and up; cards inset their content by 12.
 */
export const menu = {
	x: itemLeft,
	y: menuBarHeight + 5,
	width: 320,
	padding: 5,
	itemHeight: 24,
	separator: 11,
	/** Each panel's height with its insets, in menu order: CPU, Memory, Network, Disk, tiles. */
	panels: [190, 174, 104, 104, 123]
};
export const menuHeight =
	2 * menu.padding + menu.panels.reduce((a, b) => a + b, 0) + menu.separator + 3 * menu.itemHeight;

/** The CPU card's history graph: below the card's 12-point inset, its 19-point header and 8 of space. */
export const cpuChart = {
	x: menu.x + 8 + 12,
	y: menu.y + menu.padding + 4 + 12 + 19 + 8,
	width: 280,
	height: 48
};
/** One sample's width in the menu's graphs: the full history always spans the graph. */
export const step = cpuChart.width / (historyLength - 1);

const item = { x: itemLeft + itemWidth(0) / 2, y: menuBarHeight / 2 };
/** The pointer comes to rest on the first busy sample, a few seconds after it arrived. */
const hoverAt = 10_400;
const onSpike = {
	x: cpuChart.x + cpuChart.width - ((hoverAt - busy.from) / interval) * step,
	y: cpuChart.y + 30
};

/**
 * In on the item, back for the whole menu, in on the CPU card, back to the item for its styles.
 * Each shot's edges fall in gaps between menu bar items, never through one, and the caption
 * (about 705–762 of the frame's 800 pixels down) sits over wallpaper or a card's padding, never
 * over text: the whole menu ends above it, and the CPU card shot ends in the Memory card's top
 * padding, with the caption over the gap between the cards.
 */
const establishing = { x: 1088, y: 400, zoom: 1 };
/** From the empty bar left of the other extras to the gap between Wi-Fi and Spotlight. */
const closeUp = { x: 1219, y: 0, zoom: 2.2 };
/** From the gap between Edit and View to the clock. */
const wholeMenu = { x: 957, y: 0, zoom: 0.83 };
/** From between the iCloud and Music icons to between the item's FREE and BAT cells. */
const cpuCard = { x: 1187, y: 0, zoom: 3.35 };
const wide = { x: 864, y: 540, zoom: 1280 / 1728 };

export const film = direct((d) => {
	d.camera(establishing);
	d.at(200).camera(closeUp);
	d.at(300).caption('CPU, memory, network and more, live in the menu bar.');
	d.at(0).point({ x: 1250, y: 420 });
	d.at(2000).point({ x: 1250, y: 420 });
	d.at(2900).point(item);
	d.at(3100).click().mark('open').caption('Click for graphs of the last three minutes.');
	d.at(3200).camera(wholeMenu);
	d.at(4700).camera(cpuCard);
	d.at(busy.from).mark('busy');
	d.at(6400).caption('Something busy? Hover to see when it started.');
	d.at(9400).point(item);
	d.at(hoverAt).point(onSpike).mark('hover');
	d.at(10_800).poster();
	d.at(12_000).point(onSpike);
	d.at(12_800).point({ x: 1368, y: 190 });
	d.at(12_900).click().mark('close');
	d.at(13_000).camera(closeUp);
	d.at(13_700).caption('Show each as a value, a graph, or a gauge.');
	d.at(14_300).mark('values');
	d.at(15_600).mark('graphs');
	d.at(16_900).mark('gauges');
	d.at(18_400).camera(wide);
	d.at(19_200).end(2200);
});

const m = film.marks;

export type Frame = BaseFrame & {
	/** 0 closed, 1 open, for the menu's entrance and exit. */
	menu: number;
	/** The CPU graph's hovered sample, counted back from now, or null when the pointer isn't on it. */
	hover: number | null;
	layout: number;
	readings: Readings;
};

/** The sample under the pointer, as HistoryChart.hoverIndex finds it. */
function hoverIndex(x: number, y: number): number | null {
	const c = cpuChart;
	if (x < c.x || x > c.x + c.width || y < c.y || y > c.y + c.height) return null;
	const back = Math.round((c.x + c.width - x) / step);
	return back < historyLength ? back : null;
}

export function frameAt(time: number): Frame {
	const base = film.frame(time);
	const { t } = base;
	// A menu appears at once on mouse-down and fades as it goes.
	const open = t >= m.open && t < m.close + 200;
	const menuOpacity = open ? Math.min(ramp(t, m.open, 100), 1 - ramp(t, m.close, 200)) : 0;
	const layout = t < m.values ? 0 : t < m.graphs ? 1 : t < m.gauges ? 2 : 3;
	return {
		...base,
		menu: menuOpacity,
		hover: open && t < m.close && base.cursor ? hoverIndex(base.cursor.x, base.cursor.y) : null,
		layout,
		readings: readingsAt(t)
	};
}
