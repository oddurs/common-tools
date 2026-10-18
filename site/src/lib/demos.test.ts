// The demos should show what the apps actually do; these pin the behaviour the captions promise.
import { describe, expect, it } from 'vitest';
import * as bar from './bar/demo';
import * as keys from './keys/demo';
import { screen, viewport } from './mac/geometry';
import * as stats from './stats/demo';

const shown = (f: bar.Frame) => f.icons.filter((i) => i.opacity > 0.5).map((i) => i.symbol);

describe.each([
	['stats', stats],
	['keys', keys],
	['bar', bar]
] as const)('%s demo', (_, demo) => {
	it('loops seamlessly', () => {
		expect(demo.frameAt(1234)).toEqual(demo.frameAt(1234 + demo.film.duration));
	});
	it('has a poster inside the loop, fully faded in', () => {
		expect(demo.film.poster).toBeGreaterThan(0);
		expect(demo.film.poster).toBeLessThan(demo.film.duration);
		expect(demo.frameAt(demo.film.poster).opacity).toBe(1);
	});
});

describe('Common Bar demo', () => {
	const m = bar.film.marks;
	it('starts crowded, every icon showing', () => {
		expect(shown(bar.frameAt(1500))).toHaveLength(17);
	});
	it('keeps only the pinned icons once the extras are in the folder', () => {
		expect(shown(bar.frameAt(m.open - 100))).toEqual(['icloud.fill', 'message.fill', 'music.note']);
	});
	it('lists every icon in the folder, in menu bar order', () => {
		const frame = bar.frameAt(m.open + 600);
		expect(frame.dropdown.opacity).toBe(1);
		expect(frame.dropdown.rows).toHaveLength(14);
		expect(frame.dropdown.rows[0].symbol).toBe('cup.and.saucer.fill');
		expect(frame.dropdown.rows.at(-1)!.symbol).toBe('paperclip');
	});
	it('opens the chosen icon beside the folder, then puts it back', () => {
		const open = bar.frameAt(m.itemOpen + 400);
		expect(open.dropdown.opacity).toBe(0);
		expect(open.itemMenu.opacity).toBe(1);
		const icon = open.icons.find((i) => i.symbol === 'paperclip' && i.opacity > 0.5)!;
		expect(icon.x).toBe(open.folder.x - bar.metrics.slot);
		expect(shown(bar.frameAt(m.itemClose + 600))).toEqual(['icloud.fill', 'message.fill', 'music.note']);
	});
	it('keeps hidden icons off the screen, never under the notch or the menus', () => {
		const frame = bar.frameAt(m.open - 100);
		const hidden = frame.icons.filter(
			(i) => !['icloud.fill', 'message.fill', 'music.note'].includes(i.symbol)
		);
		expect(hidden.every((i) => i.x + bar.metrics.slot <= 0)).toBe(true);
	});
	it('never moves the folder off the right side of the menu bar', () => {
		for (let t = 0; t < bar.film.duration; t += 100) {
			expect(bar.frameAt(t).folder.x).toBeGreaterThan(screen.width / 2);
		}
	});
});

describe('Common Stats demo', () => {
	it('reads back a sample that exists while hovering', () => {
		const frame = stats.frameAt(stats.film.poster);
		expect(frame.hover).not.toBeNull();
		expect(frame.hover!).toBeGreaterThanOrEqual(0);
		expect(frame.hover!).toBeLessThan(stats.historyLength);
	});
	it('shows the busy moment', () => {
		expect(stats.frameAt(12_500).readings.cpu).toBeGreaterThan(60);
		expect(stats.frameAt(3000).readings.cpu).toBeLessThan(40);
	});
});

describe.each([
	['stats', stats],
	['keys', keys],
	['bar', bar]
] as const)('%s demo camera', (_, demo) => {
	it('never shows past the edge of the screen', () => {
		for (let t = 0; t < demo.film.duration; t += 50) {
			const { x, y, zoom } = demo.frameAt(t).camera;
			expect(x - viewport.width / 2 / zoom).toBeGreaterThanOrEqual(-0.001);
			expect(y - viewport.height / 2 / zoom).toBeGreaterThanOrEqual(-0.001);
			expect(x + viewport.width / 2 / zoom).toBeLessThanOrEqual(screen.width + 0.001);
			expect(y + viewport.height / 2 / zoom).toBeLessThanOrEqual(screen.height + 0.001);
		}
	});
	it('ends on the closing card', () => {
		expect(demo.frameAt(demo.film.duration - 700).end).toBe(1);
	});
});
