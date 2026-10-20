// The demo should show what Common Command actually does; these pin the behaviour the captions promise.
import { describe, expect, it } from 'vitest';
import * as command from './demo';
import { results } from './results';

const m = command.film.marks;
const topHit = (f: command.Frame) => f.sections[0]?.rows[0];

describe('Common Command demo', () => {
	it('opens over Notes, which keeps the menu bar, after ⌥Space', () => {
		expect(command.frameAt(m.open - 100).panel).toBe(0);
		const open = command.frameAt(m.open + 200);
		expect(open.panel).toBe(1);
		expect(open.keys).toEqual(['option', 'Space']);
	});
	it('fades in over 120 ms, as PanelController.show does', () => {
		expect(command.frameAt(m.open + 60).panel).toBeCloseTo(0.5);
		expect(command.frameAt(m.open + 120).panel).toBe(1);
	});
	it('finds Calendar as the Top Hit from three letters, every group showing in the poster', () => {
		const frame = command.frameAt(command.film.poster);
		expect(frame.query).toBe('cal');
		expect(frame.caption).toContain('Calendar');
		expect(frame.sections.map((s) => s.title)).toEqual([
			'Top Hit',
			'Applications',
			'System Settings',
			'Search the Web'
		]);
		expect(topHit(frame)?.title).toBe('Calendar');
		expect(frame.sections[1].rows[0].title).toBe('Calculator');
	});
	it('finds the Appearance pane for “dark mode”', () => {
		const frame = command.frameAt(m.selectSum - 300);
		expect(frame.query).toBe('dark mode');
		expect(topHit(frame)).toMatchObject({ title: 'Appearance', icon: 'appearance' });
		expect(frame.caption).toContain('dark mode');
	});
	it('converts 10 km to miles, and Return copies the number into the note', () => {
		const converted = command.frameAt(m.close - 200);
		expect(converted.sections[0].title).toBe('Conversion');
		expect(topHit(converted)).toMatchObject({ title: '6.21371 mi', subtitle: 'Copy' });
		expect(command.frameAt(m.close - 40).keys).toEqual(['Return']);
		expect(command.frameAt(m.close + 10).panel).toBe(0);
		// The calculation copies the number alone (Results.compose's `copied`), so that is what pastes.
		expect(command.frameAt(m.paste).added).toBe('6.21371');
		expect(command.frameAt(m.typed).added).toBe('6.21371 miles.');
	});
	it('replaces the query after ⌘A, as the field does', () => {
		expect(command.frameAt(m.selectDark + 100)).toMatchObject({ query: 'cal', selectAll: true });
		expect(command.frameAt(m.dark + 50)).toMatchObject({ query: 'd', selectAll: false });
	});
	it('has the app’s results for every query it types', () => {
		for (const query of command.typed) expect(results[query], query).toBeDefined();
	});
	it('types at a readable, human speed', () => {
		const changes: number[] = [];
		let last = '';
		for (let t = m.dark; t < m.darkTyped; t += 5) {
			const { query } = command.frameAt(t);
			if (query !== last) changes.push(t);
			last = query;
		}
		const gaps = changes.slice(1).map((t, i) => t - changes[i]);
		expect(Math.min(...gaps)).toBeGreaterThanOrEqual(120);
	});
	it('hides the note’s caret while the panel has the keyboard', () => {
		for (let t = m.open; t < m.close; t += 100) expect(command.frameAt(t).noteCaret).toBe(false);
	});
});
