// The demo should show what Common Color actually does; these pin the behaviour the captions promise.
import { describe, expect, it } from 'vitest';
import * as color from './demo';

const m = color.film.marks;

/** WCAG 2 relative luminance of an sRGB hex colour. */
function luminance(hex: string): number {
	const [r, g, b] = [1, 3, 5].map((i) => {
		const c = parseInt(hex.slice(i, i + 2), 16) / 255;
		return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
	});
	return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

describe('Common Color demo', () => {
	it('shows the loupe in place of the pointer only while picking, and only over the poster', () => {
		expect(color.frameAt(m.sample - 50).loupe).toBeNull();
		expect(color.frameAt(m.pick + 50).loupe).toBeNull();
		const reach = color.loupe.cells / 4;
		for (let t = m.sample; t < m.pick; t += 25) {
			const frame = color.frameAt(t);
			expect(frame.cursor).toBeNull();
			const { x, y } = frame.loupe!;
			expect(x - reach).toBeGreaterThan(color.poster.x);
			expect(x + reach).toBeLessThan(color.poster.x + color.poster.width);
			expect(y - reach).toBeGreaterThan(color.poster.y);
			expect(y + reach).toBeLessThan(color.poster.y + color.poster.height);
		}
	});

	it('picks the sun, with its edge in the loupe', () => {
		const frame = color.frameAt(m.pick - 20);
		expect(frame.loupe).toEqual({ ...color.target, opacity: 1 });
		const grid = color.magnified(frame.loupe!);
		const middle = (color.loupe.cells - 1) / 2;
		expect(grid[middle][middle]).toBe(color.palette.sun);
		expect(grid.flat()).toContain(color.palette.ink);
	});

	it('says it copied the pixel as hex, beside the pointer', () => {
		const frame = color.frameAt(m.pick + 400);
		expect(frame.card).toMatchObject({ x: color.target.x + 16, y: color.target.y + 16, opacity: 1 });
		expect(color.formats[frame.card!.format]).toEqual({ title: 'Hex', text: color.palette.sun });
		expect(color.frameAt(m.pick + 2000).card).toBeNull();
	});

	it('pastes what was copied', () => {
		expect(color.frameAt(m.paste - 50).pasted).toBe(false);
		expect(color.frameAt(m.paste).pasted).toBe(true);
		expect(color.frameAt(m.paste).front).toBe('editor');
	});

	it('writes every format of the same colour', () => {
		const [r, g, b] = [1, 3, 5].map((i) => parseInt(color.palette.sun.slice(i, i + 2), 16));
		expect(color.formats.map((f) => f.title)).toEqual([
			'Hex',
			'RGB',
			'HSL',
			'OKLCH',
			'Display P3',
			'SwiftUI',
			'AppKit'
		]);
		expect(color.formats[1].text).toBe(`rgb(${r} ${g} ${b})`);
		expect(color.formats[5].text).toBe(
			`Color(.sRGB, red: 1, green: ${(g / 255).toFixed(4)}, blue: ${(b / 255).toFixed(4)})`
		);
	});

	it('shows the pick first among the last 12, and the contrast of the newest two', () => {
		expect(color.recent).toHaveLength(12);
		expect(color.recent.slice(0, 2)).toEqual([color.palette.sun, color.palette.ink]);
		const [a, b] = color.recent.slice(0, 2).map(luminance);
		const ratio = (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
		expect(`${Math.floor(ratio * 100) / 100}:1`).toBe(color.contrast.text);
		expect(ratio >= 4.5 && ratio < 7).toBe(true); // Passes AA, not AAA, for normal text.
	});

	it('copies OKLCH from the row under the pointer, and says so under the menu bar item', () => {
		expect(color.frameAt(m.copy - 50).hover).toBe(color.chosenFormat);
		expect(color.formats[color.chosenFormat].title).toBe('OKLCH');
		const after = color.frameAt(m.copy + 400);
		expect(after.panel).toBe(0);
		expect(after.card).toMatchObject({ format: color.chosenFormat, x: color.stage.item.left + 16 });
	});

	it('holds the pointer still for every click', () => {
		for (const at of [m.focus, m.open, m.formats, m.copy]) {
			expect(color.frameAt(at - 150).cursor).toEqual(color.frameAt(at).cursor);
		}
	});
});
