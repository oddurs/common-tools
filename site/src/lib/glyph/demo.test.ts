// The demo should show what Common Glyph actually does; these pin the behaviour the captions promise.
import { describe, expect, it } from 'vitest';
import { menuBarHeight } from '../mac/geometry';
import * as glyph from './demo';

const m = glyph.film.marks;
const bar = (t: number) => glyph.frameAt(t).glyphs.map((g) => `${g.id}:${g.source}`);

describe('Common Glyph demo', () => {
	it('shows the starter glyph until a picture is dropped on the drop zone', () => {
		expect(bar(1000)).toEqual(['mochi:star']);
		const dropping = glyph.frameAt(m.drop - 40);
		expect(dropping.drag?.over).toBe(true);
		expect(dropping.picture).toBe(0);
		expect(bar(m.drop + 400)).toEqual(['mochi:photo']);
		expect(glyph.frameAt(m.drop + 400).picture).toBe(1);
	});
	it('lifts the subject from the Background menu, then draws it as a silhouette', () => {
		expect(glyph.frameAt(m.lift - 20).popup).toEqual({ opacity: 1, hover: true });
		expect(glyph.frameAt(m.lift + 400).background).toBe('subject');
		expect(bar(m.lift + 400)).toEqual(['mochi:subject']);
		expect(bar(m.silhouette + 400)).toEqual(['mochi:silhouette']);
		expect(glyph.frameAt(m.silhouette + 400).style).toBe('silhouette');
	});
	it('adds an emoji and a kaomoji as glyphs of their own, each from its own editor', () => {
		expect(glyph.frameAt(m.add1 + 400).sheet).toEqual({ id: 'glyph', open: 1 });
		expect(bar(m.flower + 400)).toEqual(['mochi:silhouette', 'glyph:flower']);
		expect(glyph.frameAt(m.add2 + 400).sheet).toEqual({ id: 'glyph2', open: 1 });
		expect(bar(m.kaomoji + 400)).toEqual(['mochi:silhouette', 'glyph:flower', 'glyph2:kaomoji']);
		expect(glyph.frameAt(m.kaomoji + 400).rows).toEqual(['mochi', 'glyph', 'glyph2']);
	});
	it('names new glyphs as Library.freshName does', () => {
		expect(glyph.names.glyph).toBe('Glyph');
		expect(glyph.names.glyph2).toBe('Glyph 2');
	});
	it('draws every glyph 85% of the menu bar tall', () => {
		for (const size of Object.values(glyph.glyphSize))
			expect(size.height).toBe(Math.round(menuBarHeight * 0.85));
	});
	it("opens Mochi's menu under its item, with the other two glyphs beside it", () => {
		const poster = glyph.frameAt(glyph.film.poster);
		expect(poster.menu).toBe(1);
		expect(poster.settings).toBe(0);
		expect(poster.glyphs).toHaveLength(3);
		expect(glyph.frameAt(m.close + 400).menu).toBe(0);
	});
});
