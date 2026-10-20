// The Common Shot demo: replying in a chat with the code it asks about. ⇧⌘2 freezes the screen under
// the overlay; hovering lights a window with its size; a drag over the code shows the size pill and
// the loupe; letting go flies the shot into the preview in the corner, as the app's Toast does, and
// it is on the clipboard, so ⌘V puts it in the message. The menu bar item's panel keeps it with the
// day's other shots. Sizes, placement and timings are the app's own (Overlay, Placement, Toast,
// ShotsPanel). The scene is a pure function of time, so the recorder can step through it.

import { direct, type BaseFrame } from '../film/director';
import { ramp, type Point } from '../film/motion';
import { extrasRight, menuBarHeight, screen, statusSlot, wide } from '../mac/geometry';
import { dragFrom, dragTo, composer, toastLayout, windows, type WindowID } from './scene';
import { caption, pill, snapped, type Rect } from './size';

export type Overlay = {
	/** The window lit under the pointer, when nothing is being dragged. */
	hovered: WindowID | null;
	/** What is lit and outlined: the drag, or the hovered window. */
	hole: Rect | null;
	/** The size pill's runs and where it sits, right-aligned under the hole. */
	pill: { runs: [string, string]; right: number; top: number } | null;
	loupe: Rect;
	hint: boolean;
};

export type Frame = BaseFrame & {
	/** Where the pointer is, whether it shows as the arrow or the overlay's crosshair. */
	pointer: Point;
	overlay: Overlay | null;
	/** The shot shrinking from where it was picked into the preview's thumbnail. */
	flight: (Rect & { radius: number }) | null;
	/** The preview card: how far it has faded in, and how far it has slid out to the right. */
	toast: { opacity: number; dx: number };
	/** The shot in the chat's message field, then in the sent message. */
	attached: number;
	sent: number;
	/** The menu bar item's panel, 0 to 1 as it fades in. */
	panel: number;
	/** The tile under the pointer in the panel, by position. */
	hoverTile: number | null;
};

/** The selection the drag ends on, as the overlay snaps it. */
export const selection = snapped({
	x: dragFrom.x,
	y: dragFrom.y,
	width: dragTo.x - dragFrom.x,
	height: dragTo.y - dragFrom.y
});
export const toast = toastLayout(selection, caption(selection.width * 2, selection.height * 2));

/** Common Shot's item: beside the system's own icons, where it first appears. */
export const item = { x: extrasRight - statusSlot, width: statusSlot };
/** The panel: the menu panel width plus its padding, under the item's left edge, kept 8 points inside. */
export const panel = {
	width: 320 + 16,
	x: Math.min(extrasRight - statusSlot, screen.width - 336 - 8),
	y: menuBarHeight + 4
};
/** The newest tile, top left of Today: panel padding, the Take Screenshot row, the card's inset and header. */
const firstTile = { x: panel.x + 8 + 12 + 72, y: panel.y + 8 + 22 + 8 + 12 + 14 + 8 + 46 };

const inField = { x: composer.x + 84, y: composer.y + 27 };
const aside = { x: composer.x + composer.width - 120, y: composer.y - 140 };
const inEditor = { x: 660, y: 560 };

/** The whole desk with the hint along the bottom; the drag up close, loupe and pill in frame. */
const intro = { x: 865, y: 598, zoom: 0.83 };
const onCode = { x: 640, y: 470, zoom: 2.2 };
/** Back out before letting go, so the shot's flight to the corner is in frame. */
const both = { x: 1030, y: 640, zoom: 0.92 };
/** The preview in the corner and the message field above it. */
const onChat = { x: 1290, y: 800, zoom: 1.45 };
const onBar = { x: 1440, y: 0, zoom: 1.2 };

export const film = direct((d) => {
	d.camera(wide);
	d.point(inField);
	d.at(200).camera(intro);
	d.at(400).caption('Press ⇧⌘2 and the screen freezes.');
	d.at(1500).hold('⇧', 'command', '2');
	// The overlay's own hint says what to do next, so the caption makes way for it.
	d.at(1650).mark('freeze').caption('');
	d.at(1950).release();
	// Resting on the chat, which lights up; across to the editor, which takes over; up to the code.
	d.at(2900).stay();
	d.at(3700).point(inEditor);
	d.at(3700).camera(onCode);
	d.at(4000).stay();
	d.at(4800).point(dragFrom);
	d.at(5000).stay().mark('down').caption('Drag an area. Its size and token cost follow.');
	d.at(6200).point(dragTo);
	d.at(7300).camera(both);
	d.at(8300).mark('pick').caption('Let go: it’s on the clipboard, ready to paste.');
	d.at(8600).camera(onChat);
	d.at(9300).stay();
	d.at(10_100).point(aside);
	d.at(10_900).hold('command', 'V');
	d.at(11_050).mark('paste').caption('Paste it: the chat gets the code as an image.');
	d.at(11_250).release();
	d.at(12_000).hold('return');
	d.at(12_100).mark('send');
	d.at(12_900).poster();
	d.at(12_250).release();
	d.at(13_000).camera(onBar).caption('Every recent shot waits in the menu bar.');
	d.at(13_100).stay();
	d.at(14_100).point({ x: item.x + item.width / 2, y: menuBarHeight / 2 });
	d.at(14_300).click().mark('open');
	d.at(15_100).point(firstTile);
	d.mark('tile');
	d.at(16_400).camera(wide);
	d.at(17_600).end(2400);
});

const m = film.marks;

/** The front-most window under `p`. */
function windowAt(p: Point): WindowID | null {
	for (const [id, w] of Object.entries(windows) as [WindowID, Rect][]) {
		if (p.x >= w.x && p.x < w.x + w.width && p.y >= w.y && p.y < w.y + w.height) return id;
	}
	return null;
}

/** `Placement.best`: the first candidate on the display, clear of every obstacle. */
function placed(candidates: Rect[], obstacles: Rect[]): Rect {
	const margin = 6;
	const fits = (r: Rect) =>
		r.x >= margin &&
		r.y >= margin &&
		r.x + r.width <= screen.width - margin &&
		r.y + r.height <= screen.height - margin;
	const clear = (r: Rect) =>
		!obstacles.some(
			(o) => r.x < o.x + o.width && o.x < r.x + r.width && r.y < o.y + o.height && o.y < r.y + r.height
		);
	return candidates.find((r) => fits(r) && clear(r)) ?? candidates[0];
}

/** The pill's width: 12-point monospaced digits and 10 points of padding either side. */
const pillWidth = (runs: [string, string]) => Math.ceil((runs[0].length + runs[1].length + 2) * 7) + 20;

function overlayAt(t: number, p: Point): Overlay | null {
	if (t < m.freeze || t >= m.pick) return null;
	const dragging = t >= m.down && (p.x - dragFrom.x >= 4 || p.y - dragFrom.y >= 4);
	const hovered = t < m.down ? windowAt(p) : 'editor';
	const hole = dragging
		? snapped({ x: dragFrom.x, y: dragFrom.y, width: p.x - dragFrom.x, height: p.y - dragFrom.y })
		: hovered
			? windows[hovered]
			: null;
	const obstacles: Rect[] = [];
	let pillAt: Overlay['pill'] = null;
	if (hole) {
		const runs = pill(hole);
		const width = pillWidth(runs);
		const right = hole.x + hole.width;
		const below = { x: right - width, y: hole.y + hole.height + 8, width, height: 24 };
		const above = { x: right - width, y: hole.y - 8 - 24, width, height: 24 };
		const at = placed([below, above], []);
		pillAt = { runs, right, top: at.y };
		obstacles.push(at);
	}
	// The loupe: below and right of the pointer, flipping left or up at the edges and around the pill.
	const side = 126;
	const near = 24;
	const far = near + side;
	const loupe = placed(
		[
			{ x: p.x + near, y: p.y + near, width: side, height: side },
			{ x: p.x - far, y: p.y + near, width: side, height: side },
			{ x: p.x + near, y: p.y - far, width: side, height: side },
			{ x: p.x - far, y: p.y - far, width: side, height: side }
		],
		obstacles
	);
	// The hint gives way within 48 points of the pointer, and while there's a selection.
	const hint = !dragging && p.y < screen.height - 24 - 24 - 48;
	return { hovered: dragging ? null : hovered, hole, pill: pillAt, loupe, hint };
}

export function frameAt(time: number): Frame {
	const base = film.frame(time);
	const { t } = base;
	const pointer = base.cursor!;
	const overlay = overlayAt(t, pointer);

	// Toast.fly: 250 ms from the pick to the thumbnail's place, then the card fades in over 150 ms
	// and the picture goes. Two seconds after it was shown it slides back out to the right.
	const flying = ramp(t, m.pick, 250);
	const landed = t >= m.pick + 250 + 150;
	const flight =
		t >= m.pick && !landed
			? {
					x: selection.x + (toast.thumb.x - selection.x) * flying,
					y: selection.y + (toast.thumb.y - selection.y) * flying,
					width: selection.width + (toast.thumb.width - selection.width) * flying,
					height: selection.height + (toast.thumb.height - selection.height) * flying,
					radius: 8 * flying
				}
			: null;
	const out = ramp(t, m.pick + 2000, 250);
	const toastState = {
		opacity: Math.min(ramp(t, m.pick + 250, 150), 1 - out),
		dx: out * (screen.width - toast.card.x)
	};

	return {
		...base,
		// The overlay sets the crosshair; the arrow is back as soon as it closes.
		cursor: overlay ? null : pointer,
		pointer,
		overlay,
		flight,
		toast: toastState,
		attached: t >= m.send ? 0 : ramp(t, m.paste, 180),
		sent: ramp(t, m.send, 220),
		panel: ramp(t, m.open, 150),
		hoverTile: t >= m.tile ? 0 : null
	};
}
