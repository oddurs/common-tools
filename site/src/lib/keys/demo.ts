// The demo video's script. Every fix in it is real engine output, checked with `common-keys convert`:
// "/etta" on U.S. is "þetta" on Icelandic, "ghbdtn" is "привет", "dkssudgktpdy" is "안녕하세요"
// (from U.S. or Icelandic alike, whose letter keys agree). "Takk fyrir," reads the same on both.
//
// As in the app, a fix lands when the space after the word is pressed, and the space follows it.
// Bringing an app forward restores the layout last used there, or the preferred one (U.S.) in an
// app not typed in yet (`Engine.appDidActivate`, `AppLayoutChoice`).
//
// The scene is a pure function of time, so the recorder can step through it frame by frame.

import { direct, type BaseFrame } from '../film/director';
import type { Point } from '../film/motion';
import { extrasRight, menuBarHeight, viewport, wide } from '../mac/geometry';

export type WindowID = 'notes' | 'chat';

export type Word = {
	text: string;
	newline?: boolean;
	/** What was on screen before Common Keys fixed it, and what the fix put there. */
	fixed?: { original: string; replacement: string; flag: string };
};

/** The engine's frame, with the typing on top. Its caption comes from the typing script. */
export type Frame = Omit<BaseFrame, 'keys'> & {
	front: WindowID;
	flag: string;
	windows: Record<WindowID, Word[]>;
	/** The fixed word wearing the bubble, and its opacity as it fades in and out. */
	bubble: { window: WindowID; index: number; opacity: number } | null;
	/** Keys just pressed, as labelled on a U.S. keyboard. */
	keys: string;
	caretOn: boolean;
};

type Step =
	| { kind: 'type'; text: string; showKeys?: boolean }
	| { kind: 'fix'; replacement: string; flag: string }
	| { kind: 'wait'; ms: number }
	| { kind: 'caption'; text: string }
	| { kind: 'front'; window: WindowID; flag: string };

/** How long the closing card holds. */
const endFor = 2200;

export const captions = {
	problem: 'Typing Icelandic, but the U.S. layout is on…',
	fix: 'Common Keys fixes the word and switches to Icelandic.',
	scripts: 'Every script: Cyrillic, Greek, Hebrew, Arabic…',
	korean: 'Korean composes into syllables, too.',
	apps: 'And every app keeps its own language.'
};

const script: Step[] = [
	{ kind: 'caption', text: captions.problem },
	{ kind: 'wait', ms: 500 },
	{ kind: 'type', text: 'Takk fyrir, ' },
	{ kind: 'wait', ms: 300 },
	{ kind: 'type', text: '/etta', showKeys: true },
	{ kind: 'wait', ms: 250 },
	{ kind: 'fix', replacement: 'þetta', flag: '🇮🇸' },
	{ kind: 'caption', text: captions.fix },
	{ kind: 'type', text: ' er frábært!' },
	{ kind: 'wait', ms: 1200 },

	// Chat hasn't been typed in yet, so it comes forward on the preferred layout.
	{ kind: 'front', window: 'chat', flag: '🇺🇸' },
	{ kind: 'caption', text: captions.scripts },
	{ kind: 'wait', ms: 600 },
	{ kind: 'type', text: 'ghbdtn', showKeys: true },
	{ kind: 'wait', ms: 250 },
	{ kind: 'fix', replacement: 'привет', flag: '🇷🇺' },
	{ kind: 'type', text: ' как дела?' },
	{ kind: 'wait', ms: 1200 },

	// Notes was last typed in on Icelandic, so that is what it comes back to. Twelve keys fill the
	// bottom of the frame, so the caption waits until they have gone.
	{ kind: 'front', window: 'notes', flag: '🇮🇸' },
	{ kind: 'caption', text: '' },
	{ kind: 'wait', ms: 500 },
	{ kind: 'type', text: '\n' },
	{ kind: 'type', text: 'dkssudgktpdy', showKeys: true },
	{ kind: 'wait', ms: 250 },
	{ kind: 'fix', replacement: '안녕하세요', flag: '🇰🇷' },
	{ kind: 'type', text: ' 반가워요!' },
	{ kind: 'wait', ms: 450 },
	{ kind: 'caption', text: captions.korean },
	{ kind: 'wait', ms: 1600 },

	{ kind: 'caption', text: captions.apps },
	{ kind: 'wait', ms: 1100 },
	{ kind: 'front', window: 'chat', flag: '🇷🇺' },
	{ kind: 'wait', ms: 1500 },
	{ kind: 'front', window: 'notes', flag: '🇰🇷' },
	{ kind: 'wait', ms: 1700 },
	{ kind: 'caption', text: '' },
	{ kind: 'wait', ms: endFor }
];

const keyInterval = 95;
/** The bubble's life in `FixBubble`: it fades in, holds 2.2 s, and fades out (Motion fast, base). */
const bubbleIn = 150;
const bubbleFor = 2200;
const bubbleOut = 250;
const keysFor = 1400;
const fadeFor = 600;

type Event = { at: number; step: Step; char?: string };

/** The script laid out in time, one event per key. */
const timeline = (() => {
	const events: Event[] = [];
	let at = fadeFor;
	for (const step of script) {
		if (step.kind === 'type') {
			for (const [index, char] of [...step.text].entries()) {
				// A little unevenness, the same every run, so it reads as a person typing.
				at += keyInterval + ((index * 37) % 5) * 12;
				events.push({ at, step, char });
			}
		} else if (step.kind === 'wait') {
			at += step.ms;
		} else {
			events.push({ at, step });
			if (step.kind === 'fix') at += 140;
		}
	}
	return { events, end: at + fadeFor };
})();

export const duration = timeline.end;

/** When the steps matching `test` happen. */
const whenAll = (test: (step: Step) => boolean) =>
	timeline.events.filter((event) => test(event.step)).map((event) => event.at);
const when = (test: (step: Step) => boolean) => whenAll(test)[0];
export const captionAt = (text: string) => when((step) => step.kind === 'caption' && step.text === text);
/** When each fix lands, in order. */
export const fixes = whenAll((step) => step.kind === 'fix');
/** When each app comes forward, in order. */
export const switches = timeline.events
	.filter((event) => event.step.kind === 'front')
	.map((event) => ({ at: event.at, window: (event.step as { window: WindowID }).window }));

// Where the windows sit on the screen, in points; Demo.svelte lays out to the same numbers. They sit
// under the flag, so a push-in on either one's text also holds the flag in the menu bar. Chat sits
// up and to the right behind Notes, so with Notes in front its title bar shows above it, as a
// window behind does, and nothing of it pokes out at the edges of the frame.
export const windows = {
	notes: { x: 640, y: 100, width: 760, height: 300 },
	chat: { x: 740, y: 40, width: 640, height: 340 }
} as const;

/** Where the pointer clicks to bring each window forward: a part of it the other one doesn't cover. */
const clickOn: Record<WindowID, Point> = {
	notes: { x: 690, y: 330 },
	chat: { x: 1180, y: 68 }
};

/** The flag's status item: its right edge against the system's own extras. */
export const flagItem = { right: extrasRight, center: { x: extrasRight - 19, y: menuBarHeight / 2 } };

/** Where the push-ins' right edge falls: in the gap between the battery and Wi-Fi symbols. */
const frameRight = 1476;
/** A shot of `zoom` with its top on the menu bar and its right edge at `frameRight`. */
const underFlag = (zoom: number) => ({
	x: frameRight - viewport.width / 2 / zoom,
	y: viewport.height / 2 / zoom,
	zoom
});
// Each push-in holds the front window's text and the menu bar's flag, so every layout change is seen
// on the flag as it happens. The Notes shot holds both windows, so the switches between apps play
// in it too.
const desk = underFlag(1.45);
const onChat = underFlag(1.6);
const endAt = duration - endFor - 400;

/** How long the pointer takes to reach a window, and how long it rests there before clicking. */
const glide = 650;
const rest = 130;

/** The camera, the pointer and the closing card; captions and keys come from the typing script. */
export const film = direct((d) => {
	d.camera(wide);
	d.at(250).camera(desk);
	d.at(switches[0].at - 1100).camera(onChat);
	d.at(switches[1].at - 1100).camera(desk);
	d.at(endAt - 500).camera(wide);

	// macOS hides the pointer while you type; it shows again where it was when the mouse moves.
	d.at(0).point({ x: 1280, y: 380 });
	for (const { at, window } of switches) {
		d.at(at - rest - glide)
			.stay()
			.wait(glide)
			.point(clickOn[window])
			.wait(rest - 60)
			.click();
	}

	// The first fix, the bubble showing and the menu bar already on Icelandic.
	d.at(fixes[0] + 700).poster();
	d.at(endAt).end(duration - endAt);
});

/** When the pointer starts moving for each switch; it shows from then until the next key. */
const moves = switches.map(({ at }) => at - rest - glide);

export function frameAt(time: number): Frame {
	const base = film.frame(time);
	const { t } = base;
	const frame: Frame = {
		...base,
		front: 'notes',
		flag: '🇺🇸',
		caption: '',
		windows: { notes: [{ text: '' }], chat: [{ text: '' }] },
		bubble: null,
		keys: '',
		caretOn: true
	};
	let bubbleAt = -Infinity;
	let lastKey = -Infinity;
	let keysAt = -Infinity;

	for (const event of timeline.events) {
		if (event.at > t) break;
		const { step } = event;
		const words = frame.windows[frame.front];
		switch (step.kind) {
			case 'type': {
				const char = event.char!;
				if (char === ' ') words.push({ text: '' });
				else if (char === '\n') words.push({ text: '', newline: true });
				else words[words.length - 1].text += char;
				lastKey = event.at;
				if (step.showKeys) {
					if (event.at - keysAt > keysFor) frame.keys = '';
					frame.keys += char;
					keysAt = event.at;
				}
				break;
			}
			case 'fix': {
				const word = words[words.length - 1];
				word.fixed = { original: word.text, replacement: step.replacement, flag: step.flag };
				word.text = step.replacement;
				frame.flag = step.flag;
				frame.bubble = { window: frame.front, index: words.length - 1, opacity: 0 };
				bubbleAt = event.at;
				break;
			}
			case 'caption':
				frame.caption = step.text;
				break;
			case 'front':
				// A new front app hides the bubble at once.
				frame.front = step.window;
				frame.flag = step.flag;
				frame.bubble = null;
				break;
		}
	}
	if (frame.bubble) {
		const since = t - bubbleAt;
		frame.bubble.opacity = Math.max(
			0,
			Math.min(since / bubbleIn, 1, 1 - (since - bubbleIn - bubbleFor) / bubbleOut)
		);
		if (frame.bubble.opacity === 0 && since > bubbleIn) frame.bubble = null;
	}
	if (t - keysAt > keysFor) frame.keys = '';
	// The caret holds steady while typing and blinks when idle, as text fields do.
	frame.caretOn = t - lastKey < 500 || Math.floor(t / 530) % 2 === 0;
	const moved = Math.max(-Infinity, ...moves.filter((at) => at <= t));
	if (moved < lastKey || moved === -Infinity) frame.cursor = null;
	return frame;
}
