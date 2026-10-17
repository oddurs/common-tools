import { describe, expect, it } from 'vitest';
import { wide } from '../mac/geometry';
import { direct } from './director';

const close = { x: 1728, y: 0, zoom: 2 };

const film = direct((d) => {
	d.camera(wide);
	d.at(500).caption('Hello.').point({ x: 100, y: 100 });
	d.at(1000).point({ x: 300, y: 100 }).click().mark('click');
	d.at(1200).hold('command').camera(close);
	d.wait(400).release().caption('');
	d.at(1500).poster();
	d.at(3000).end(1000);
});

describe('direct', () => {
	it('ends where end() says, and keeps marks and the poster', () => {
		expect(film.duration).toBe(4000);
		expect(film.poster).toBe(1500);
		expect(film.marks).toEqual({ click: 1000 });
	});

	it('glides the pointer between waypoints and rests at the ends', () => {
		expect(film.frame(0).cursor).toMatchObject({ x: 100, y: 100 });
		expect(film.frame(750).cursor).toMatchObject({ x: 200, y: 100 });
		expect(film.frame(2000).cursor).toMatchObject({ x: 300, y: 100 });
	});

	it('shows a caption until the next one, and holds keys until release', () => {
		expect(film.frame(400).caption).toBe('');
		expect(film.frame(900).caption).toBe('Hello.');
		expect(film.frame(1700).caption).toBe('');
		expect(film.frame(1300).keys).toEqual(['command']);
		expect(film.frame(1650).keys).toEqual([]);
	});

	it('pulses on clicks, moves the camera, and brings up the closing card', () => {
		expect(film.frame(1000).pulse).toBe(1);
		expect(film.frame(0).camera.zoom).toBeCloseTo(wide.zoom);
		expect(film.frame(2900).camera.zoom).toBe(2);
		expect(film.frame(2900).end).toBe(0);
		expect(film.frame(3700).end).toBe(1);
	});

	it('loops', () => {
		expect(film.frame(4750)).toEqual(film.frame(750));
	});

	it('refuses a script it cannot film', () => {
		expect(() => direct((d) => d.camera(wide).poster())).toThrow(/end/);
		expect(() => direct((d) => d.camera(wide).end(100))).toThrow(/poster/);
		expect(() => direct((d) => d.release())).toThrow(/nothing held/);
		expect(() => direct((d) => d.mark('a').mark('a'))).toThrow(/twice/);
		expect(() => direct((d) => d.at(500).point({ x: 0, y: 0 }).at(100).point({ x: 0, y: 0 }))).toThrow(
			/out of order/
		);
	});
});
