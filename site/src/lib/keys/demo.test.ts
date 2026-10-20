// The demo should show what Common Keys actually does; these pin the behaviour the captions promise.
import { describe, expect, it } from 'vitest';
import { viewport } from '../mac/geometry';
import * as keys from './demo';

/** Whether the camera's frame at time t shows the menu bar's flag. */
function flagInView(t: number): boolean {
	const { x, y, zoom } = keys.frameAt(t).camera;
	const { center } = keys.flagItem;
	return (
		Math.abs(center.x - x) < viewport.width / 2 / zoom - 20 &&
		Math.abs(center.y - y) < viewport.height / 2 / zoom
	);
}

const inside = (p: { x: number; y: number }, r: { x: number; y: number; width: number; height: number }) =>
	p.x > r.x && p.x < r.x + r.width && p.y > r.y && p.y < r.y + r.height;

describe('Common Keys demo', () => {
	it('fixes þetta typed on U.S. and switches to Icelandic', () => {
		const before = keys.frameAt(keys.fixes[0] - 1);
		expect(before.flag).toBe('🇺🇸');
		expect(before.windows.notes.at(-1)!.text).toBe('/etta');
		const after = keys.frameAt(keys.film.poster);
		expect(after.flag).toBe('🇮🇸');
		expect(after.caption).toBe(keys.captions.fix);
		const word = after.windows.notes[after.bubble!.index];
		expect(word.fixed).toEqual({ original: '/etta', replacement: 'þetta', flag: '🇮🇸' });
		expect(after.bubble!.opacity).toBe(1);
	});

	it('fixes привет and 안녕하세요 the same way', () => {
		const russian = keys.frameAt(keys.fixes[1] + 200);
		expect(russian.windows.chat[0].fixed).toEqual({
			original: 'ghbdtn',
			replacement: 'привет',
			flag: '🇷🇺'
		});
		const korean = keys.frameAt(keys.fixes[2] + 200);
		expect(korean.windows.notes.find((w) => w.newline)!.fixed).toEqual({
			original: 'dkssudgktpdy',
			replacement: '안녕하세요',
			flag: '🇰🇷'
		});
	});

	it('brings each app back on the layout last used there, as the engine does', () => {
		const flags = keys.switches.map(({ at, window }) => [window, keys.frameAt(at + 1).flag]);
		// Chat hasn't been typed in, so it gets the preferred layout; the rest is what each last used.
		expect(flags).toEqual([
			['chat', '🇺🇸'],
			['notes', '🇮🇸'],
			['chat', '🇷🇺'],
			['notes', '🇰🇷']
		]);
	});

	it('brings an app forward only with a click on its window', () => {
		for (const { at, window } of keys.switches) {
			const click = keys.frameAt(at - 20);
			expect(click.pulse).toBeGreaterThan(0);
			expect(inside(click.cursor!, keys.windows[window])).toBe(true);
		}
	});

	it('hides the pointer while typing, as macOS does', () => {
		for (const at of [keys.fixes[0] - 300, keys.fixes[1] - 300, keys.fixes[2] - 300]) {
			expect(keys.frameAt(at).cursor).toBeNull();
		}
	});

	it('keeps the flag in view whenever the layout changes', () => {
		for (const at of [...keys.fixes, ...keys.switches.map((s) => s.at)]) {
			expect(flagInView(at + 100)).toBe(true);
		}
	});

	it('never puts a caption over a long row of keys', () => {
		for (let t = 0; t < keys.duration; t += 50) {
			const frame = keys.frameAt(t);
			if (frame.keys.length > 6) expect(frame.caption).toBe('');
		}
	});
});
