// The demo should show what Common Stats actually does; these pin what each caption promises.
import { describe, expect, it } from 'vitest';
import { captions } from './bar';
import * as stats from './demo';

const at = (mark: string) => stats.frameAt(stats.film.marks[mark] + 100);
const last = (values: number[]) => values[values.length - 1];

describe('Common Stats demo', () => {
	it('opens with the item in the menu bar, showing every metric the menu will', () => {
		const items = stats.layouts[stats.frameAt(1000).layout];
		expect(items.map((i) => i.metric).sort()).toEqual(Object.keys(captions).sort());
		expect(stats.frameAt(1000).menu).toBe(0);
	});

	it('opens the menu on the click, with three minutes of history at one sample a second', () => {
		expect(stats.frameAt(stats.film.marks.open - 50).menu).toBe(0);
		expect(at('open').menu).toBe(1);
		expect(at('open').readings.cpu).toHaveLength(180);
		expect(stats.historyLength * stats.interval).toBe(3 * 60 * 1000);
	});

	it('gets busy while the menu is open, and reads back the moment it started', () => {
		expect(last(at('open').readings.cpu)).toBeLessThan(0.3);
		expect(last(at('hover').readings.cpu)).toBeGreaterThan(0.8);
		const poster = stats.frameAt(stats.film.poster);
		expect(poster.menu).toBe(1);
		expect(poster.hover).not.toBeNull();
		const cpu = poster.readings.cpu;
		const hovered = cpu.length - 1 - poster.hover!;
		// The hovered sample is busy, and the one before it isn't: the start of the stretch.
		expect(cpu[hovered]).toBeGreaterThan(0.8);
		expect(cpu[hovered - 1]).toBeLessThan(0.3);
	});

	it('closes the menu, then shows values, graphs, and gauges', () => {
		expect(at('values').menu).toBe(0);
		expect(at('values').hover).toBeNull();
		const styles = (mark: string) => stats.layouts[at(mark).layout].map((i) => i.style);
		expect(styles('values').every((s) => s === 'value')).toBe(true);
		expect(styles('graphs').every((s) => s === 'graph')).toBe(true);
		expect(styles('gauges').every((s) => s === 'gaugeValue')).toBe(true);
	});

	it('only uses styles the app offers for each metric', () => {
		const rates = ['value', 'graph', 'graphValue'];
		const slow = ['value', 'gauge', 'gaugeValue'];
		for (const item of stats.layouts.flat()) {
			if (item.metric === 'network' || item.metric === 'disk') expect(rates).toContain(item.style);
			if (item.metric === 'storage' || item.metric === 'battery') expect(slow).toContain(item.style);
		}
	});

	it('fits the whole menu on the screen', () => {
		expect(stats.menu.y + stats.menuHeight).toBeLessThan(1080);
	});
});
