// The demo should show what Common Bar actually does; these pin the behaviour the captions promise.
import { describe, expect, it } from 'vitest';
import { menuBarHeight, screen } from '../mac/geometry';
import * as bar from './demo';

const m = bar.film.marks;
const pinned = ['icloud.fill', 'message.fill', 'music.note'];
const shown = (f: bar.Frame) => f.icons.filter((i) => i.opacity > 0.5).map((i) => i.symbol);
const rowsOf = (f: bar.Frame) =>
	f.panel.items.flatMap((item) => (item.kind === 'row' ? [item.row.name] : []));
const clipboard = (f: bar.Frame) => f.icons.find((i) => i.symbol === bar.hidden[bar.chosen].symbol)!;

describe('Common Bar demo', () => {
	it('starts crowded, every icon showing and no folder yet', () => {
		const frame = bar.frameAt(1500);
		expect(shown(frame)).toHaveLength(bar.hidden.length + pinned.length);
		expect(frame.folder.opacity).toBe(0);
	});

	it('keeps only the pinned icons and More once the extras are in the folder', () => {
		const frame = bar.frameAt(m.open - 100);
		expect(shown(frame)).toEqual(pinned);
		expect(frame.folder.opacity).toBe(1);
		const hidden = frame.icons.filter((i) => !pinned.includes(i.symbol));
		expect(hidden.every((i) => i.x + bar.metrics.slot <= 0 || i.opacity === 0)).toBe(true);
	});

	it('lists every icon in the folder in its group: other apps, Common Tools, then macOS', () => {
		const frame = bar.frameAt(m.open + 600);
		expect(frame.panel.opacity).toBe(1);
		expect(frame.folder.open).toBe(true);
		expect(rowsOf(frame)).toHaveLength(bar.hidden.length);
		const headers = frame.panel.items.flatMap((i) => (i.kind === 'header' ? [i.title] : []));
		expect(headers).toEqual(['Apps', 'Common Tools', 'macOS']);
		expect(rowsOf(frame).slice(-4)).toEqual(['Common Shot', 'Common Color', 'Focus', 'Now Playing']);
		// Inside a group, menu bar order.
		const apps = bar.hidden.filter((h) => h.group === 'apps').map((h) => h.name);
		expect(rowsOf(frame).slice(0, apps.length)).toEqual(apps);
		const footer = frame.panel.items.flatMap((i) => (i.kind === 'footer' ? [i.title] : []));
		expect(footer).toEqual(['Edit Folder…', 'Settings…']);
	});

	it('opens the dropdown under More, its left edge with the folder’s, at the menu panel width', () => {
		expect(bar.stage.panel.x).toBe(bar.stage.folderX);
		expect(bar.stage.panel.y).toBe(menuBarHeight + 4);
		expect(bar.metrics.panelWidth).toBe(336);
	});

	it('highlights the row under the pointer', () => {
		const frame = bar.frameAt(m.type0 - 100);
		const row = frame.panel.items.find((i) => i.kind === 'row' && i.target === frame.panel.selected);
		expect(row && row.kind === 'row' && row.row.name).toBe('Vault');
	});

	it('narrows the list as letters are typed, the first match selected', () => {
		const one = bar.frameAt(m.type0 + 50);
		expect(one.panel.query).toBe('c');
		expect(rowsOf(one)).toEqual(rowsOf(bar.frameAt(m.open + 600)).filter((n) => /c/i.test(n)));
		expect(one.panel.selected).toBe(0);
		const two = bar.frameAt(m.type1 + 50);
		expect(two.panel.query).toBe('cl');
		expect(rowsOf(two)).toEqual(['Clipboard']);
		expect(two.panel.items[0]).toMatchObject({ kind: 'filter', count: 1 });
		expect(two.panel.selected).toBe(0);
	});

	it('marks the chosen row while the icon is brought in, with the dropdown still up', () => {
		const frame = bar.frameAt(m.choose + 200);
		expect(frame.panel.busy).toBe(0);
		expect(frame.panel.opacity).toBe(1);
	});

	it('brings the hidden icons on screen only for the moment of a move, right of the app’s menus', () => {
		const during = bar.frameAt(m.downIn + 200);
		expect(shown(during)).toHaveLength(bar.hidden.length + pinned.length);
		// Where a drag is safe on a display without a notch: the right half of the menu bar (Move.reachable).
		for (const icon of during.icons) expect(icon.x).toBeGreaterThanOrEqual(screen.width / 2);
		expect(shown(bar.frameAt(m.upIn + 200))).toEqual([...pinned, bar.hidden[bar.chosen].symbol]);
	});

	it('hides the pointer while it plays a ⌘-drag', () => {
		expect(bar.frameAt(m.dragIn + 100).cursor).toBeNull();
		expect(bar.frameAt(m.dragOut + 100).cursor).toBeNull();
		expect(bar.frameAt(m.dragIn - 100).cursor).not.toBeNull();
	});

	it('opens the icon’s own menu beside More as the dropdown gives way', () => {
		const frame = bar.frameAt(m.handOff + 400);
		expect(frame.panel.opacity).toBe(0);
		expect(frame.menu.opacity).toBe(1);
		const icon = clipboard(frame);
		expect(icon.x).toBe(frame.folder.x - bar.metrics.slot);
		expect(icon.open).toBe(true);
		expect(frame.folder.open).toBe(false);
		expect(frame.menu.x).toBe(icon.x);
	});

	it('puts the icon back in the folder once its menu closes', () => {
		const frame = bar.frameAt(m.upOut + 400);
		expect(frame.menu.opacity).toBe(0);
		expect(shown(frame)).toEqual(pinned);
	});

	it('never moves the folder off the right side of the menu bar', () => {
		for (let t = 0; t < bar.film.duration; t += 100) {
			expect(bar.frameAt(t).folder.x).toBeGreaterThan(screen.width / 2);
		}
	});
});
