// The demo should show what Common Stats actually does; these pin the behaviour the captions promise.
import { describe, expect, it } from 'vitest';
import * as stats from './demo';

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
