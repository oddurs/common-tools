import { describe, expect, it } from 'vitest';
import { along, captionAt, clickPulse, ease, loopOpacity, noise } from './scene';

describe('noise', () => {
	it('is the same every run, so recordings are reproducible', () => {
		expect(noise(42, 3)).toBe(noise(42, 3));
	});
	it('stays in [0, 1) and differs by seed', () => {
		const values = Array.from({ length: 1000 }, (_, n) => noise(n, 1));
		expect(Math.min(...values)).toBeGreaterThanOrEqual(0);
		expect(Math.max(...values)).toBeLessThan(1);
		expect(noise(7, 1)).not.toBe(noise(7, 2));
	});
});

describe('ease', () => {
	it('clamps outside [0, 1]', () => {
		expect(ease(-1)).toBe(0);
		expect(ease(2)).toBe(1);
		expect(ease(0.5)).toBeCloseTo(0.5);
	});
});

describe('along', () => {
	const path = [
		{ at: 100, x: 0, y: 0 },
		{ at: 200, x: 100, y: 50 }
	];
	it('rests before the first and after the last waypoint', () => {
		expect(along(path, 0)).toMatchObject({ x: 0, y: 0 });
		expect(along(path, 999)).toMatchObject({ x: 100, y: 50 });
	});
	it('passes through the midpoint halfway', () => {
		expect(along(path, 150)).toEqual({ x: 50, y: 25 });
	});
});

describe('captionAt', () => {
	it('shows nothing before the first caption, then the latest started', () => {
		const captions: [number, string][] = [
			[10, 'a'],
			[20, 'b']
		];
		expect(captionAt(captions, 5)).toBe('');
		expect(captionAt(captions, 15)).toBe('a');
		expect(captionAt(captions, 25)).toBe('b');
	});
});

it('fades the loop in and out', () => {
	expect(loopOpacity(0, 10_000)).toBe(0);
	expect(loopOpacity(5000, 10_000)).toBe(1);
	expect(loopOpacity(10_000, 10_000)).toBe(0);
});

it('pulses only just after a click', () => {
	expect(clickPulse([100], 99)).toBe(0);
	expect(clickPulse([100], 100)).toBe(1);
	expect(clickPulse([100], 1000)).toBe(0);
});
