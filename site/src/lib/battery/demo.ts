// The Common Battery demo: the menu bar item up close while the Mac charges, the notification at the
// level the user chose, the menu with its 12-hour chart and details, and the switch to time remaining
// as the adapter comes out. What each part shows is the app's: the item is BarRenderer's (item.ts),
// the menu is PanelView's, the notification is Notifier's copy for a charged alert. The Mac has the
// system's battery icon turned off, as Common Battery's Settings suggests, so one battery shows.
//
// The scene is a pure function of time, so the recorder can step through it frame by frame.

import { direct, type BaseFrame } from '../film/director';
import { noise, ramp } from '../film/motion';
import { extrasRight, menuBarHeight, screen, statusPadding, systemItems, wide } from '../mac/geometry';
import type { SymbolName } from '../mac/symbols';
import { width as itemImageWidth, type Reading } from './item';

/** What the menu's details read, beyond the item's reading. */
export type Details = {
	/** Watts into the battery: positive while charging, negative while it drains. */
	watts: number;
	/** The adapter's rating while one is connected. */
	adapter: number | null;
};

export type Frame = BaseFrame & {
	reading: Reading;
	details: Details;
	/** 0 closed, 1 open, for the menu's entrance and exit. */
	menu: number;
	/** 0 hidden, 1 in place, for the notification's slide in and out. */
	banner: number;
};

/** System extras this Mac has turned off: the system's battery, so only Common Battery's shows. */
export const hiddenSystem: SymbolName[] = ['battery.100percent'];

// Where things sit on the screen, in points; Demo.svelte lays out to the same numbers.
const itemWidth = itemImageWidth + 2 * statusPadding;
/** With those off, third-party extras end where their slots began, as Screen lays them out. */
const itemRight =
	extrasRight +
	systemItems
		.filter((item) => hiddenSystem.includes(item.symbol))
		.reduce((sum, item) => sum + item.width, 0);
const itemLeft = itemRight - itemWidth;
export const stage = {
	extrasRight: itemRight,
	item: { x: itemLeft, width: itemWidth, center: { x: itemLeft + itemWidth / 2, y: menuBarHeight / 2 } },
	// A status item's menu opens under its left edge. The panel is 320 wide with 8 either side.
	menu: { x: itemLeft, y: menuBarHeight + 5, width: 336 },
	// Notification banners sit in the top right corner, under the menu bar.
	banner: { x: screen.width - 14 - 344, y: menuBarHeight + 8, width: 344 }
};

/** The menu's 12-hour chart: a sample every two minutes, oldest first, from 9:41 last night. */
export type Sample = { minute: number; level: number; charging: boolean };
export const span = 12 * 60;

/**
 * Last evening on battery, then the Mac asleep overnight (a gap, as the chart leaves one), then the
 * morning on battery down to 24%, and the last 80 minutes on the charger, up to 79%.
 */
export const history: Sample[] = (() => {
	const samples: Sample[] = [];
	for (let minute = 0; minute <= span; minute += 2) {
		if (minute > 150 && minute < 560) continue;
		const wobble = (noise(minute, 4) - 0.5) * 0.006;
		const level =
			minute <= 150
				? 0.62 - (minute / 150) * 0.23
				: minute <= 640
					? 0.37 - ((minute - 560) / 80) * 0.13 + wobble
					: 0.24 + (1 - (1 - (minute - 640) / 80) ** 1.4) * 0.55;
		samples.push({ minute, level, charging: minute > 640 });
	}
	return samples;
})();

/** The level chosen under Tell me when charged to; the app offers 80, 90 and 100%. */
export const chargedAlert = 80;

/** Notifier's charged alert, for a level reached on power. */
export function notification(level: number) {
	const percent = Math.round(level * 100);
	return {
		title: percent >= 100 ? 'Battery Charged' : `Battery at ${percent}%`,
		body: 'You can unplug your Mac.'
	};
}

const parked = { x: 1250, y: 430 };
const aside = { x: 1310, y: 230 };
const out = { x: 1150, y: 450 };

/** Close on the item, back for the notification, the menu's corner, and wide to finish. */
const close = { x: stage.item.center.x, y: 0, zoom: 2.8 };
const corner = { x: screen.width, y: 0, zoom: 1.7 };
const menuShot = { x: screen.width, y: 0, zoom: 1.9 };

export const film = direct((d) => {
	d.camera(wide);
	d.at(400).camera(close);
	d.at(600).caption('Time to full, the level, and a bolt while it charges.');
	d.at(2800).camera(corner);
	d.at(3200).mark('full');
	d.at(3300).mark('alert').caption('Choose 80, 90 or 100%, and it tells you when to unplug.');
	d.at(6000).point(parked);
	d.at(6500).mark('bannerOut');
	d.at(6800).camera(menuShot);
	d.at(7200).point(stage.item.center);
	d.at(7400).click().mark('open').caption('Click for 12 hours of charge, live watts, cycles and capacity.');
	d.at(8000).point(aside);
	d.at(9600).poster();
	d.at(11_000).mark('unplug').caption('Unplug, and it switches to the time left.');
	d.at(12_000).mark('estimate');
	d.at(13_400).stay();
	d.at(14_000).point(out);
	d.at(14_200).click().mark('close').caption('');
	d.at(14_400).camera(wide);
	d.at(15_400).end(2400);
});

const m = film.marks;

/** The item's reading: charging to 80%, then on battery, a dash while macOS estimates, then the time. */
function readingAt(t: number): Reading {
	if (t < m.full) return { level: 0.79, state: 'charging', minutes: 52 };
	if (t < m.unplug) return { level: 0.8, state: 'charging', minutes: 50 };
	if (t < m.estimate) return { level: 0.8, state: 'discharging', minutes: null };
	return { level: 0.8, state: 'discharging', minutes: 6 * 60 + 18 };
}

/** With the menu open the app reads every two seconds, so the watts move a little, as they do. */
function detailsAt(t: number, reading: Reading): Details {
	const charging = reading.state === 'charging';
	const since = charging ? m.open : m.unplug;
	const tick = Math.max(0, Math.floor((t - since) / 2000));
	const jitter = (noise(tick, charging ? 1 : 2) - 0.5) * 0.8;
	return charging ? { watts: 32.6 + jitter, adapter: 140 } : { watts: -(11.4 + jitter), adapter: null };
}

export function frameAt(time: number): Frame {
	const base = film.frame(time);
	const { t } = base;
	const reading = readingAt(t);
	return {
		...base,
		reading,
		details: detailsAt(t, reading),
		menu: Math.min(ramp(t, m.open, 180), 1 - ramp(t, m.close, 160)),
		banner: Math.min(ramp(t, m.alert, 380), 1 - ramp(t, m.bannerOut, 300))
	};
}
