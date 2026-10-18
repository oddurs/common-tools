// The Common Bar demo: a crowded menu bar tidied into the More folder, the folder opened to list
// the icons in it by app, and one of them opened from there. Sizes and the folder's symbol are the
// app's own (MenuBarController, FolderMenu). Opening an icon brings it on screen just long enough for its
// menu: the one chosen here is the nearest the divider, which Common Bar shows right beside the
// folder (MenuBarModel.blockEnd). The scene is a pure function of time, so the recorder can step
// through it.

import { direct, type BaseFrame } from '../film/director';
import { clamp, ramp } from '../film/motion';
import { extrasRight, menuBarHeight, screen, statusSlot, wide } from '../mac/geometry';
import type { SymbolName } from '../mac/symbols';

/** Left to right: other apps' menu bar icons, with the names a folder gives them. */
const hidden: [SymbolName, string][] = [
	['cup.and.saucer.fill', 'Keep Awake'],
	['gauge.with.dots.needle.33percent', 'Activity'],
	['timer', 'Timer'],
	['globe', 'VPN'],
	['headphones', 'Audio'],
	['calendar', 'Calendar'],
	['keyboard', 'Input'],
	['drop.fill', 'Color Picker'],
	['lock.fill', 'Passwords'],
	['video.fill', 'Recorder'],
	['shippingbox.fill', 'Containers'],
	['bolt.fill', 'Power'],
	['eye', 'Watcher'],
	['paperclip', 'Clipboard']
];
/** Right of the folder: these stay in the menu bar. */
const pinned: SymbolName[] = ['music.note', 'message.fill', 'icloud.fill'];

/** The one opened from the folder: the nearest the divider, so it shows beside the folder. */
export const chosen = hidden.length - 1;

export type Placed = { symbol: SymbolName; x: number; opacity: number };
export type Row = { symbol: SymbolName; name: string };
export type Frame = BaseFrame & {
	icons: Placed[];
	folder: { x: number; open: boolean };
	/** The folder's menu: its rows, how far it has faded in, and the row under the pointer. */
	dropdown: { opacity: number; rows: Row[]; highlight: number | null };
	/** The chosen icon's own menu. */
	itemMenu: { opacity: number; x: number };
};

export const metrics = {
	right: extrasRight,
	slot: statusSlot,
	/** The folder: ellipsis.circle and its name, More, as Common Bar shows it to start with. */
	folder: 70,
	row: 24,
	dropdownWidth: 210,
	itemMenuWidth: 190
};

const folderX = metrics.right - pinned.length * metrics.slot - metrics.folder;
export const stage = {
	folderX,
	dropdown: { x: folderX, y: menuBarHeight + 5 },
	/** Where the chosen icon sits while it is open: just left of the folder. */
	chosenX: folderX - metrics.slot
};

/** How far the hidden icons are in place, 1, or pushed off the screen's left edge, 0. */
function tidy(t: number): number {
	return 1 - ramp(t, marks.tidy, 600);
}

function layout(t: number): Pick<Frame, 'icons' | 'folder' | 'itemMenu'> {
	const m = metrics;
	const icons: Placed[] = [];
	let x = m.right;
	for (const symbol of [...pinned].reverse()) {
		x -= m.slot;
		icons.push({ symbol, x, opacity: 1 });
	}
	x -= m.folder;
	const folder = { x, open: dropdownOpacity(t) > 0.5 };
	const r = tidy(t);
	// The divider stretches, pushing every icon left of the folder past the screen's edge.
	const push = (1 - r) * (x + 80);
	for (const [symbol] of [...hidden].reverse()) {
		x -= m.slot;
		icons.push({ symbol, x: x - push, opacity: clamp(r * 1.4 - 0.2) });
	}
	// Opened from the folder, the chosen icon comes in beside it, and goes back once its menu closes.
	const out = Math.min(ramp(t, marks.choose, 260), 1 - ramp(t, marks.itemClose, 260));
	if (out > 0) {
		const [symbol] = hidden[chosen];
		icons.push({ symbol, x: stage.chosenX - (1 - out) * 120, opacity: out });
	}
	const itemMenu = {
		opacity: Math.min(ramp(t, marks.itemOpen, 160), 1 - ramp(t, marks.itemClose, 120)),
		x: stage.chosenX
	};
	return { icons, folder, itemMenu };
}

function dropdownOpacity(t: number): number {
	return Math.min(ramp(t, marks.open, 160), 1 - ramp(t, marks.choose, 120));
}

const y = menuBarHeight / 2;
const folderCenter = { x: folderX + metrics.folder / 2, y: y + 2 };
const rowCenter = (i: number) => ({
	x: stage.dropdown.x + 80,
	y: stage.dropdown.y + 7 + i * metrics.row + metrics.row / 2
});
const crowded = { x: screen.width, y: 0, zoom: 1.25 };
const close = { x: screen.width - 260, y: 0, zoom: 1.6 };

/** In on the right of the menu bar, wide enough to show the crowd at first, closer for the folder. */
export const film = direct((d) => {
	d.camera(wide);
	d.at(500).camera(crowded);
	d.at(600).caption('A full menu bar: every app wants a spot.');
	d.at(3000).mark('tidy').caption('Common Bar keeps the extras in one folder, out of the way.');
	d.at(4400).camera(close);
	d.at(4600).point({ x: 1250, y: 300 });
	d.at(5600).point(folderCenter);
	d.at(5700).click().mark('open').caption('Click More to see them, each with its app.');
	d.at(6500).point(rowCenter(3));
	d.at(7300).poster();
	d.at(8000).point(rowCenter(chosen));
	d.at(8200).mark('hover');
	d.at(8800).point(rowCenter(chosen));
	d.at(8900).click().mark('choose').caption('Choose one, and it opens right beside the folder.');
	d.at(9300).mark('itemOpen');
	d.at(9600).point({ x: stage.chosenX + 60, y: menuBarHeight + 40 });
	d.at(11_400).point({ x: 1100, y: 420 });
	d.at(11_600).click().mark('itemClose').caption('Close it, and it goes back in the folder.');
	d.at(13_400).camera(wide);
	d.at(14_000).end(2600);
});

const marks = film.marks;

export function frameAt(time: number): Frame {
	const base = film.frame(time);
	const t = base.t;
	const highlight = t >= marks.hover && t < marks.choose ? chosen : null;
	return {
		...base,
		...layout(t),
		dropdown: {
			opacity: dropdownOpacity(t),
			rows: hidden.map(([symbol, name]) => ({ symbol, name })),
			highlight
		}
	};
}
