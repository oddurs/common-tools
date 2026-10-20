// The demo should show what Common Battery actually does; these pin the behaviour the captions promise.
import { describe, expect, it } from 'vitest';
import * as battery from './demo';
import { duration, layout, parts, width } from './item';

const m = battery.film.marks;
const captionAt = (t: number) => battery.frameAt(t).caption;

describe('Common Battery demo', () => {
	it("sizes the item as BarRenderer does: the widest time, '100%', and the icon, 4 points apart", () => {
		expect(parts).toEqual(['time', 'percent', 'battery']);
		// ceil(33.797 + 33.779 + 25.5 + 2 × 4)
		expect(width).toBe(102);
	});
	it('centres each reading by its ink, on whole points', () => {
		const x = (r: Parameters<typeof layout>[0]) => layout(r).map((p) => p.x);
		expect(x({ level: 0.79, state: 'charging', minutes: 52 })).toEqual([8, 38, 68]);
		// A dash while macOS estimates is narrower, so the whole reading moves to stay centred.
		expect(x({ level: 0.8, state: 'discharging', minutes: null })).toEqual([18, 29, 59]);
	});
	it('opens on the item while it charges: time to full, the level, the bolt', () => {
		const f = battery.frameAt(1600);
		expect(f.caption).toMatch(/Time to full/);
		expect(f.reading).toEqual({ level: 0.79, state: 'charging', minutes: 52 });
		expect(duration(f.reading.minutes)).toBe('0:52');
	});
	it('posts the charged alert once the level reaches the one chosen, on power', () => {
		expect([80, 90, 100]).toContain(battery.chargedAlert);
		expect(battery.frameAt(m.alert - 50).banner).toBe(0);
		const f = battery.frameAt(m.alert + 1000);
		expect(f.banner).toBe(1);
		expect(Math.round(f.reading.level * 100)).toBeGreaterThanOrEqual(battery.chargedAlert);
		expect(f.reading.state).toBe('charging');
		expect(battery.notification(f.reading.level)).toEqual({
			title: 'Battery at 80%',
			body: 'You can unplug your Mac.'
		});
		expect(captionAt(m.alert + 1000)).toMatch(/80, 90 or 100%/);
	});
	it('shows the menu with the chart and live details on the poster, the alert gone', () => {
		const f = battery.frameAt(battery.film.poster);
		expect(f.menu).toBe(1);
		expect(f.banner).toBe(0);
		expect(f.details.adapter).not.toBeNull();
		expect(f.details.watts).toBeGreaterThan(0);
		expect(f.caption).toMatch(/12 hours/);
		// The watts are read every two seconds while the menu is open, so they move.
		expect(battery.frameAt(m.open + 500).details.watts).not.toBe(
			battery.frameAt(m.open + 2500).details.watts
		);
	});
	it('draws 12 hours of history: charging up to now, and a gap while the Mac slept', () => {
		const h = battery.history;
		expect(h[0].minute).toBe(0);
		expect(h.at(-1)!.minute).toBe(battery.span);
		expect(h.at(-1)!.charging).toBe(true);
		expect(h.some((s, i) => i > 0 && s.minute - h[i - 1].minute > 5)).toBe(true);
		expect(Math.round(h.at(-1)!.level * 100)).toBe(79);
	});
	it('switches to the time left on unplugging: a dash while macOS estimates, then the time', () => {
		const unplugged = battery.frameAt(m.unplug + 300);
		expect(unplugged.reading.state).toBe('discharging');
		expect(unplugged.reading.minutes).toBeNull();
		expect(unplugged.details.adapter).toBeNull();
		expect(unplugged.details.watts).toBeLessThan(0);
		expect(unplugged.caption).toMatch(/Unplug/);
		const estimated = battery.frameAt(m.estimate + 300);
		expect(duration(estimated.reading.minutes)).toBe('6:18');
		expect(estimated.menu).toBe(1);
	});
	it('ends with the menu closed', () => {
		expect(battery.frameAt(m.close + 400).menu).toBe(0);
	});
});
