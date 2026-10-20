// The demo should show what Common Shot actually does; these pin the behaviour the captions promise.
import { describe, expect, it } from 'vitest';
import * as shot from './demo';
import { chat, editor } from './scene';
import { caption, describe as tokens, estimatedTokens, pill, sized } from './size';

const m = shot.film.marks;
const at = shot.frameAt;

describe('the numbers, as ShotKit computes them (ImageSizeTests)', () => {
	it('sizes a full Retina screen for prompts', () => {
		expect(sized(3456, 2234)).toEqual([1568, 1014]);
		expect(sized(1280, 760)).toEqual([1280, 760]);
		expect(estimatedTokens(3456, 2234)).toBe(4784);
		expect(estimatedTokens(1568, 1014)).toBe(2120);
	});
	it('reads tokens short', () => {
		for (const [count, text] of [
			[840, '≈ 840 tokens'],
			[999, '≈ 999 tokens'],
			[1000, '≈ 1.0k tokens'],
			[2120, '≈ 2.1k tokens'],
			[4784, '≈ 4.8k tokens']
		] as const)
			expect(tokens(count)).toBe(text);
	});
});

describe('Common Shot demo', () => {
	it('freezes the screen when ⇧⌘2 is pressed, with the hint along the bottom', () => {
		expect(at(m.freeze - 50).overlay).toBeNull();
		expect(at(m.freeze - 50).keys).toEqual(['⇧', 'command', '2']);
		const frozen = at(m.freeze + 50);
		expect(frozen.overlay?.hint).toBe(true);
		expect(frozen.cursor).toBeNull();
	});
	it('lights the window under the pointer with its size, chat first, then the editor', () => {
		const onChat = at(m.freeze + 600).overlay!;
		expect(onChat.hovered).toBe('chat');
		expect(onChat.pill!.runs).toEqual(pill(chat));
		expect(onChat.pill!.runs).toEqual(['1280 × 800', '≈ 1.4k tokens']);
		const onEditor = at(m.down - 100).overlay!;
		expect(onEditor.hovered).toBe('editor');
		expect(onEditor.pill!.runs).toEqual(pill(editor));
	});
	it('shows the drag’s size and token cost, the loupe clear of the pill, and no hint', () => {
		const o = at(shot.film.poster).overlay!;
		expect(o.hole).toEqual(shot.selection);
		expect(o.pill!.runs).toEqual(pill(shot.selection));
		expect(o.hint).toBe(false);
		const pillLeft = o.pill!.right - 200;
		const clear =
			o.loupe.x >= o.pill!.right ||
			o.loupe.x + o.loupe.width <= pillLeft ||
			o.loupe.y >= o.pill!.top + 24 ||
			o.loupe.y + o.loupe.height <= o.pill!.top;
		expect(clear).toBe(true);
	});
	it('closes the overlay as you let go, and the shot flies into the preview', () => {
		const lettingGo = at(m.pick + 100);
		expect(lettingGo.overlay).toBeNull();
		expect(lettingGo.cursor).not.toBeNull();
		expect(lettingGo.flight).not.toBeNull();
		const landed = at(m.pick + 600);
		expect(landed.flight).toBeNull();
		expect(landed.toast.opacity).toBe(1);
		expect(at(m.pick + 2400).toast.opacity).toBe(0);
		expect(caption(shot.selection.width * 2, shot.selection.height * 2)).toBe(
			`Copied · ${pill(shot.selection)[0]} · ${pill(shot.selection)[1]}`
		);
	});
	it('pastes the shot into the message with ⌘V, and sends it', () => {
		expect(at(m.paste - 100).keys).toEqual(['command', 'V']);
		expect(at(m.paste - 100).attached).toBe(0);
		expect(at(m.paste + 300).attached).toBe(1);
		expect(at(m.send + 400).sent).toBe(1);
		expect(at(m.send + 400).attached).toBe(0);
	});
	it('opens the history panel from the menu bar item', () => {
		expect(at(m.open - 100).panel).toBe(0);
		expect(at(m.open + 200).panel).toBe(1);
		expect(at(m.tile + 100).hoverTile).toBe(0);
	});
});
