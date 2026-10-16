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
		expect(demo.frameAt(1234)).toEqual(demo.frameAt(1234 + demo.duration));
	});
	it('has a poster inside the loop, fully faded in', () => {
		expect(demo.posterTime).toBeGreaterThan(0);
		expect(demo.posterTime).toBeLessThan(demo.duration);
		expect(demo.frameAt(demo.posterTime).opacity).toBe(1);
	});
});

describe('Common Bar demo', () => {
	it('starts crowded, every icon showing', () => {
		expect(shown(bar.frameAt(1500))).toHaveLength(17);
	});
	it('keeps only the icons right of the chevron after the click', () => {
		expect(shown(bar.frameAt(5000))).toEqual(['icloud.fill', 'message.fill', 'music.note']);
	});
	it('shows the hidden icons on hover', () => {
		expect(shown(bar.frameAt(8000))).toContain('drop.fill');
	});
	it('hides the icon dragged past the chevron', () => {
		expect(shown(bar.frameAt(13_400))).toEqual(['icloud.fill', 'message.fill']);
	});
	it('keeps visible icons right of the chevron and hidden ones left of it', () => {
		const frame = bar.frameAt(1500);
		const right = frame.icons.filter((i) => i.x > frame.chevron.x).map((i) => i.symbol);
		expect(right).toEqual(['icloud.fill', 'message.fill', 'music.note']);
	});
	it('never moves the chevron off the right side of the menu bar', () => {
		for (let t = 0; t < bar.duration; t += 100) {
			expect(bar.frameAt(t).chevron.x).toBeGreaterThan(screen.width / 2);
		}
	});
});

describe('Common Stats demo', () => {
	it('reads back a sample that exists while hovering', () => {
		const frame = stats.frameAt(stats.posterTime);
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
		for (let t = 0; t < demo.duration; t += 50) {
			const { x, y, zoom } = demo.frameAt(t).camera;
			expect(x - viewport.width / 2 / zoom).toBeGreaterThanOrEqual(-0.001);
			expect(y - viewport.height / 2 / zoom).toBeGreaterThanOrEqual(-0.001);
			expect(x + viewport.width / 2 / zoom).toBeLessThanOrEqual(screen.width + 0.001);
			expect(y + viewport.height / 2 / zoom).toBeLessThanOrEqual(screen.height + 0.001);
		}
	});
	it('ends on the closing card', () => {
		expect(demo.frameAt(demo.duration - 700).end).toBe(1);
	});
});
