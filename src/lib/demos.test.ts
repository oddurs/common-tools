// The demos should show what the apps actually do; these pin the behaviour the captions promise.
import { describe, expect, it } from 'vitest';
import * as bar from './bar/demo';
import * as keys from './keys/demo';
import * as stats from './stats/demo';

const shown = (f: bar.Frame) => f.icons.filter((i) => i.opacity > 0.5).map((i) => i.glyph);

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
	it('starts crowded, with icons lost behind the notch', () => {
		const behind = bar.frameAt(1500).icons.filter((i) => i.x < bar.metrics.notch.right);
		expect(behind.length).toBeGreaterThan(0);
	});
	it('keeps only the visible section after the click', () => {
		expect(shown(bar.frameAt(5000))).toEqual(['cloud', 'bubble', 'note']);
	});
	it('hover shows the hidden section but not the always-hidden one', () => {
		const icons = shown(bar.frameAt(8000));
		expect(icons).toContain('drop');
		expect(icons).not.toContain('cup');
	});
	it('hides the icon dragged past the divider', () => {
		expect(shown(bar.frameAt(13_200))).toEqual(['cloud', 'bubble']);
	});
	it('⌥-click shows both sections', () => {
		expect(shown(bar.frameAt(bar.posterTime))).toContain('cup');
	});
	it('never pushes the chevron off-screen', () => {
		for (let t = 0; t < bar.duration; t += 100) {
			expect(bar.frameAt(t).chevron.x).toBeGreaterThan(bar.metrics.notch.right);
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
		expect(stats.frameAt(13_500).readings.cpu).toBeGreaterThan(60);
		expect(stats.frameAt(3000).readings.cpu).toBeLessThan(40);
	});
});
