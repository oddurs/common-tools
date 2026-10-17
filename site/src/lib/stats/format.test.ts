import { expect, it } from 'vitest';
import { graph, rate } from './format';

it('writes rates the way the app does', () => {
	expect(rate(2.44)).toBe('2.4 MB/s');
	expect(rate(0.424)).toBe('424 KB/s');
	expect(rate(0.0052)).toBe('5.2 KB/s');
	expect(rate(0.000953)).toBe('953 B/s');
});

it('draws a graph across the full width, clipping values above the scale', () => {
	const path = graph([0, 200], 100, 50, 100);
	expect(path).toBe('M0.0,50.0L100.0,0.0');
	expect(graph([0, 50], 100, 50, 100, true)).toMatch(/Z$/);
});
