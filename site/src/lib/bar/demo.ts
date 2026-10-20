// The Common Bar demo: a crowded menu bar tidied into the More folder, the folder's dropdown opened
// to its icons in their groups, a few letters typed to find one, and Return to open it. Everything is
// drawn from the app: the dropdown is `FolderPanel` on `MenuPanelSurface` (its width, row, header and
// footer metrics, the filter row, the progress mark on the chosen row), grouped as
// `FolderEntry.grouped` does, filtered as `Dropdown.matches` does. Opening is `Opener`: the divider
// comes down so the hidden icons are on screen for a moment, the chosen one, nearest the divider, is
// ⌘-dragged in beside the folder with the pointer hidden, the rest go back off-screen, and the dropdown
// gives way as the icon's own menu opens under it. When that menu closes, the icon is dragged back to
// its slot the same way. The scene is a pure function of time, so the recorder can step through it.

import { direct, type BaseFrame } from '../film/director';
import { clamp, ramp, type Point } from '../film/motion';
import { extrasRight, menuBarHeight, screen, statusSlot, wide } from '../mac/geometry';
import type { SymbolName } from '../mac/symbols';

export type Group = 'apps' | 'commonTools' | 'system';
export const groupTitles: Record<Group, string> = {
	apps: 'Apps',
	commonTools: 'Common Tools',
	system: 'macOS'
};

/** An icon left of the divider: its menu bar symbol, its row's name, and what its row shows. */
export type Hidden = {
	symbol: SymbolName;
	name: string;
	group: Group;
	/** Another app's icon, drawn as a tile in these colours with its symbol. */
	tile?: [string, string];
	/** A Common Tools app, drawn with its real icon. */
	slug?: 'color' | 'shot';
};

/** Left to right in the menu bar. macOS's own items show their SF Symbol in the dropdown (Dropdown.symbol). */
export const hidden: Hidden[] = [
	{ symbol: 'cup.and.saucer.fill', name: 'Awake', group: 'apps', tile: ['#ffb340', '#e8730c'] },
	{ symbol: 'moon', name: 'Focus', group: 'system' },
	{ symbol: 'calendar', name: 'Schedule', group: 'apps', tile: ['#ff6b5e', '#d92c20'] },
	{ symbol: 'camera.viewfinder', name: 'Common Shot', group: 'commonTools', slug: 'shot' },
	{ symbol: 'globe', name: 'Tunnel', group: 'apps', tile: ['#3fd0c5', '#0b8f9e'] },
	{ symbol: 'lock.fill', name: 'Vault', group: 'apps', tile: ['#6b7686', '#2f3846'] },
	{ symbol: 'play.circle', name: 'Now Playing', group: 'system' },
	{ symbol: 'shippingbox.fill', name: 'Containers', group: 'apps', tile: ['#5aa9ff', '#1f5fd6'] },
	{ symbol: 'eyedropper', name: 'Common Color', group: 'commonTools', slug: 'color' },
	{ symbol: 'video.fill', name: 'Recorder', group: 'apps', tile: ['#ff5f8f', '#c4164f'] },
	{ symbol: 'paperclip', name: 'Clipboard', group: 'apps', tile: ['#a78bfa', '#6d3fd8'] }
];
/** Right of the folder: these stay in the menu bar. */
export const pinned: SymbolName[] = ['music.note', 'message.fill', 'icloud.fill'];

/** The one opened: the nearest the divider, so a ⌘-drag can bring it beside the folder. */
export const chosen = hidden.length - 1;
/** What is typed to find it. */
export const typed = ['c', 'l'];

export const metrics = {
	slot: statusSlot,
	/** The folder: ellipsis.circle and its name, More, as Common Bar shows it to start with. */
	folder: 70,
	/** What macOS adds to the divider's length when it is all the way down (DividerItem.Metric.padding). */
	dividerPadding: 16,
	/** MenuPanelSurface: Tokens.Layout.menuPanelWidth plus Tokens.Space.xs either side. */
	panelWidth: 320 + 2 * 8,
	panelPadding: 8,
	/** MenuPanelHost.gap, Tokens.Space.xxs. */
	gap: 4,
	/** A row: 16 pt of icon or text, and 3 pt above and below. */
	row: 22,
	/** A SectionHeader in the subheadline style, and the space under it (Tokens.Space.xxs). */
	header: 14,
	headerBelow: 4,
	/** Tokens.Space.xs above every header but the first. */
	headerAbove: 8,
	/** A Divider with Tokens.Space.xxs above and below. */
	divider: 9,
	/** The icon's own menu: a stock macOS menu. */
	menuWidth: 248,
	menuPadding: 5,
	menuRow: 24,
	menuSeparator: 11
};

const folderX = extrasRight - pinned.length * metrics.slot - metrics.folder;
export const stage = {
	folderX,
	panel: { x: folderX, y: menuBarHeight + metrics.gap },
	/** Beside the folder, right of the divider: where the chosen icon is while its menu is open. */
	besideX: folderX - metrics.slot,
	/** Where the right end of the hidden icons is with the divider all the way down. */
	downEnd: folderX - metrics.dividerPadding
};

// The panel's contents, laid out as FolderPanel stacks them.

export type Row = Hidden & { index: number };
export type Item =
	| { kind: 'filter'; y: number; query: string; count: number }
	| { kind: 'header'; y: number; title: string }
	| { kind: 'row'; y: number; row: Row; target: number }
	| { kind: 'divider'; y: number }
	| { kind: 'footer'; y: number; title: string; shortcut?: string; target: number };

/** Dropdown.matches: every word of the query is in the name, ignoring case. */
export const matches = (query: string, name: string) =>
	query
		.split(' ')
		.filter(Boolean)
		.every((word) => name.toLowerCase().includes(word.toLowerCase()));

const groupOrder: Group[] = ['apps', 'commonTools', 'system'];

/** The rows in their groups (FolderEntry.grouped), in menu bar order inside each. */
export const rows: Row[] = groupOrder.flatMap((group) =>
	hidden.map((h, index) => ({ ...h, index })).filter((r) => r.group === group)
);

export function layoutPanel(query: string): { items: Item[]; height: number; visible: Row[] } {
	const m = metrics;
	const visible = rows.filter((r) => matches(query, r.name));
	const items: Item[] = [];
	let y = 0;
	if (query) {
		items.push({ kind: 'filter', y, query, count: visible.length });
		y += m.row;
		items.push({ kind: 'divider', y });
		y += m.divider;
	}
	const groups = groupOrder.filter((g) => visible.some((r) => r.group === g));
	let target = 0;
	groups.forEach((group, i) => {
		if (groups.length > 1) {
			if (i > 0) y += m.headerAbove;
			items.push({ kind: 'header', y, title: groupTitles[group] });
			y += m.header + m.headerBelow;
		}
		for (const row of visible.filter((r) => r.group === group)) {
			items.push({ kind: 'row', y, row, target: target++ });
			y += m.row;
		}
	});
	items.push({ kind: 'divider', y });
	y += m.divider;
	items.push({ kind: 'footer', y, title: 'Edit Folder…', target: target++ });
	y += m.row;
	items.push({ kind: 'footer', y, title: 'Settings…', shortcut: '⌘,', target: target++ });
	y += m.row;
	return { items, height: y + 2 * m.panelPadding, visible };
}

/** The chosen icon's own menu: a clipboard manager's history. */
export const iconMenu: ({ title: string; shortcut?: string; heading?: boolean } | null)[] = [
	{ title: 'Clipboard History', heading: true },
	{ title: 'Meeting moved to 3:30', shortcut: '⌘1' },
	{ title: 'Gate B22, boarding 4:05', shortcut: '⌘2' },
	{ title: '#0A84FF', shortcut: '⌘3' },
	{ title: 'Thanks, see you Thursday!', shortcut: '⌘4' },
	null,
	{ title: 'Clear History' },
	{ title: 'Settings…', shortcut: '⌘,' },
	{ title: 'Quit Clipboard', shortcut: '⌘Q' }
];

/** Each item's top inside the menu, and the menu's height. */
export const menuLayout = (() => {
	const m = metrics;
	let y = m.menuPadding;
	const tops = iconMenu.map((item) => {
		const top = y;
		y += item ? m.menuRow : m.menuSeparator;
		return top;
	});
	return { tops, height: y + m.menuPadding };
})();

// The script.

const y = menuBarHeight / 2;
const folderCenter = { x: folderX + metrics.folder / 2, y: y + 2 };
const full = layoutPanel('');
const rowCenter = (i: number): Point => {
	const item = full.items.find((it) => it.kind === 'row' && it.target === i)!;
	return {
		x: stage.panel.x + 110,
		y: stage.panel.y + metrics.panelPadding + item.y + metrics.row / 2
	};
};
const menuItemCenter = (i: number): Point => ({
	x: stage.besideX + 120,
	y: stage.panel.y + menuLayout.tops[i] + metrics.menuRow / 2
});

/** Close on the crowd at the right of the menu bar. */
const crowded = { x: screen.width, y: 0, zoom: 1.55 };
/** On the open dropdown, all of it. */
const onPanel = { x: screen.width, y: 0, zoom: 1.6 };
/** Wide enough for the hidden icons coming on screen beside the dropdown and the icon's menu. */
const onHandoff = { x: 1250, y: 0, zoom: 1.45 };

/** How long the divider's moves and the drags take to show. */
const step = { fade: 100, drag: 200, dragHidden: 330 };

export const film = direct((d) => {
	d.camera(wide);
	d.point({ x: 1150, y: 360 });
	d.at(400).camera(crowded).caption('A full menu bar: every app wants a spot.');
	d.at(2600).mark('tidy').caption('Common Bar tucks them into one folder: More.');
	d.at(3200).camera(onPanel);
	d.at(3300).stay();
	d.at(4300).point(folderCenter);
	d.at(4450).click().mark('open').caption('Click More, then type a few letters to find one.');
	d.at(5200).point(rowCenter(1));
	d.at(5500).stay();
	d.at(6100).point(rowCenter(3));
	d.at(6500).poster();
	d.at(7300).hold('C').mark('type0');
	d.at(7430).release();
	d.at(7600).hold('L').mark('type1');
	d.at(7730).release();
	d.at(7500).camera(onHandoff);
	d.at(8400).hold('return').mark('choose').caption('Return opens its own menu, right beside More.');
	d.at(8540).release();
	// Opener: the divider comes all the way down, the icon is ⌘-dragged beside the folder, the
	// divider stretches again, and the icon is pressed.
	d.at(8400 + 150).mark('downIn');
	d.at(8400 + 450).mark('dragIn');
	d.at(8400 + 850).mark('upIn');
	d.at(8400 + 1000).mark('handOff');
	d.stay();
	d.at(10_300).point(menuItemCenter(1));
	d.at(10_800).click().mark('close').stay();
	// Put back: the divider comes down, the icon is dragged back to its slot, and the divider stretches.
	d.at(10_800 + 200).mark('downOut');
	d.at(10_800 + 450).mark('dragOut');
	d.at(10_800 + 850).mark('upOut');
	d.at(11_900).point({ x: 1150, y: 380 });
	d.at(12_100).camera(wide);
	d.at(13_000).end(2600);
});

const marks = film.marks;

// The menu bar.

export type Placed = { symbol: SymbolName; x: number; opacity: number; open?: boolean };
export type Frame = BaseFrame & {
	icons: Placed[];
	folder: { x: number; opacity: number; open: boolean };
	panel: {
		opacity: number;
		query: string;
		items: Item[];
		height: number;
		/** The highlighted target, pointer and keyboard alike. */
		selected: number | null;
		/** The row being opened, showing a progress mark. */
		busy: number | null;
	};
	menu: { opacity: number; x: number; highlight: number | null };
	/** Milliseconds into the loop, for the progress mark's turn. */
	spin: number;
};

/** Where the right end of the icons left of the divider is, and how much of them shows. */
function block(t: number): { end: number; opacity: number } {
	if (t < marks.tidy) return { end: folderX + metrics.folder, opacity: 1 };
	const away = -40;
	if (t < marks.downIn) {
		const r = ramp(t, marks.tidy, 500);
		return {
			end: folderX + metrics.folder + (away - folderX - metrics.folder) * r,
			opacity: clamp(1.3 - r * 1.4)
		};
	}
	// The divider's length changes in one step; the icons show and go in a blink.
	const shown = (from: number, to: number) =>
		Math.min(ramp(t, from, step.fade), 1 - ramp(t, to, step.fade));
	const opacity = Math.max(shown(marks.downIn, marks.upIn), shown(marks.downOut, marks.upOut));
	return { end: stage.downEnd, opacity };
}

function layoutBar(t: number): Pick<Frame, 'icons' | 'folder'> {
	const m = metrics;
	const icons: Placed[] = [];
	let x = extrasRight;
	for (const symbol of [...pinned].reverse()) {
		x -= m.slot;
		icons.push({ symbol, x, opacity: 1 });
	}
	const panelUp = t >= marks.open && t < marks.handOff;
	const folder = { x: folderX, opacity: ramp(t, marks.tidy + 150, 200), open: panelUp };
	const b = block(t);
	// The chosen icon: in its slot, or beside the folder from the drag in until the drag back.
	const toBeside = ramp(t, marks.dragIn, step.drag) - ramp(t, marks.dragOut, step.drag);
	const menuOpen = t >= marks.handOff && t < marks.close;
	hidden.forEach((h, i) => {
		const slotX = b.end - (hidden.length - i) * m.slot;
		if (i === chosen && toBeside > 0) {
			icons.push({
				symbol: h.symbol,
				x: slotX + (stage.besideX - slotX) * toBeside,
				opacity: 1,
				open: menuOpen
			});
		} else {
			icons.push({ symbol: h.symbol, x: slotX, opacity: b.opacity });
		}
	});
	return { icons, folder };
}

/** The highlighted target under the pointer, if it is over one. */
function under(items: Item[], cursor: Point | null): number | null {
	if (!cursor) return null;
	const left = stage.panel.x + metrics.panelPadding;
	if (cursor.x < left || cursor.x > left + metrics.panelWidth - 2 * metrics.panelPadding) return null;
	const top = stage.panel.y + metrics.panelPadding;
	for (const item of items) {
		if (
			(item.kind === 'row' || item.kind === 'footer') &&
			cursor.y >= top + item.y &&
			cursor.y < top + item.y + metrics.row
		)
			return item.target;
	}
	return null;
}

export function frameAt(time: number): Frame {
	const base = film.frame(time);
	const t = base.t;
	// MenuBarDrag hides the pointer for the third of a second a drag takes.
	const dragging =
		(t >= marks.dragIn && t < marks.dragIn + step.dragHidden) ||
		(t >= marks.dragOut && t < marks.dragOut + step.dragHidden);
	const cursor = dragging ? null : base.cursor;

	const query = typed.slice(0, typed.filter((_, i) => t >= marks[`type${i}`]).length).join('');
	const { items, height } = layoutPanel(query);
	// The pointer sets the highlight until a letter is typed; typing selects the first match.
	let selected: number | null = null;
	if (query) selected = 0;
	else if (t >= marks.open) {
		for (let s = marks.open; s <= t; s += 50) selected = under(items, film.frame(s).cursor) ?? selected;
	}
	const panelOpacity = t < marks.handOff ? ramp(t, marks.open, 150) : 1 - ramp(t, marks.handOff, 60);

	let highlight: number | null = null;
	if (cursor && t >= marks.handOff && t < marks.close + 100) {
		const top = stage.panel.y;
		menuLayout.tops.forEach((itemTop, i) => {
			const item = iconMenu[i];
			if (!item || item.heading) return;
			const inside = cursor.x >= stage.besideX && cursor.x <= stage.besideX + metrics.menuWidth;
			if (inside && cursor.y >= top + itemTop && cursor.y < top + itemTop + metrics.menuRow)
				highlight = i;
		});
	}

	return {
		...base,
		cursor,
		...layoutBar(t),
		panel: {
			opacity: panelOpacity,
			query,
			items,
			height,
			selected,
			busy: t >= marks.choose && t < marks.handOff ? 0 : null
		},
		menu: {
			opacity: Math.min(ramp(t, marks.handOff, 120), 1 - ramp(t, marks.close, 150)),
			x: stage.besideX,
			highlight
		},
		spin: t
	};
}
