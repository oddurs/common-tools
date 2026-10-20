// What every film must do, whichever app it shows. Each app's own src/lib/<app>/demo.test.ts pins
// what its captions promise.
import { describe, expect, it } from 'vitest';
import type { BaseFrame, Film } from './film/director';
import { screen, viewport } from './mac/geometry';

const demos = Object.entries(
	import.meta.glob<{ film: Film; frameAt: (time: number) => BaseFrame }>('./*/demo.ts', { eager: true })
).map(([path, demo]) => [path.split('/')[1], demo] as const);

it('finds every film', () => {
	expect(demos.map(([app]) => app)).toEqual(expect.arrayContaining(['stats', 'keys', 'bar']));
});

describe.each(demos)('%s demo', (_, demo) => {
	it('loops seamlessly', () => {
		expect(demo.frameAt(1234)).toEqual(demo.frameAt(1234 + demo.film.duration));
	});
	it('has a poster inside the loop, fully faded in', () => {
		expect(demo.film.poster).toBeGreaterThan(0);
		expect(demo.film.poster).toBeLessThan(demo.film.duration);
		expect(demo.frameAt(demo.film.poster).opacity).toBe(1);
	});
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
