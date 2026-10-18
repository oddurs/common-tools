// The demo video's script. Every fix in it is real engine output, checked with `common-keys convert`:
// "/etta" on U.S. is "þetta" on Icelandic, "ghbdtn" is "привет", "dkssudgktpdy" is "안녕하세요".
//
// As in the app, a fix lands when the space after the word is pressed, and the space follows it.
//
// The scene is a pure function of time, so the recorder can step through it frame by frame.

import { direct, type BaseFrame } from '../film/director';
import { screen, wide } from '../mac/geometry';

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
	/** The fixed word wearing the bubble. */
	bubble: { window: WindowID; index: number } | null;
	/** Keys just pressed, as labelled on a U.S. keyboard. */
	keys: string;
	caretOn: boolean;
	/** Milliseconds since the menu bar flag changed and since the bubble appeared, for their entrances. */
	sinceFlag: number;
	sinceBubble: number;
};

type Step =
	| { kind: 'type'; text: string; showKeys?: boolean }
	| { kind: 'fix'; replacement: string; flag: string }
	| { kind: 'wait'; ms: number }
	| { kind: 'caption'; text: string }
	| { kind: 'front'; window: WindowID; flag: string };

/** How long the closing card holds. */
const endFor = 2200;

const script: Step[] = [
	{ kind: 'caption', text: 'Typing Icelandic, but the U.S. layout is on…' },
	{ kind: 'wait', ms: 900 },
	{ kind: 'type', text: 'See you at noon. ' },
	{ kind: 'wait', ms: 350 },
	{ kind: 'type', text: '/etta', showKeys: true },
	{ kind: 'wait', ms: 250 },
	{ kind: 'fix', replacement: 'þetta', flag: '🇮🇸' },
	{ kind: 'caption', text: 'Common Keys fixes the word and switches to Icelandic.' },
	{ kind: 'type', text: ' er frábært!' },
	{ kind: 'wait', ms: 1800 },

	{ kind: 'front', window: 'chat', flag: '🇺🇸' },
	{ kind: 'caption', text: 'Every script: Cyrillic, Greek, Hebrew, Arabic…' },
	{ kind: 'wait', ms: 700 },
	{ kind: 'type', text: 'ghbdtn', showKeys: true },
	{ kind: 'wait', ms: 250 },
	{ kind: 'fix', replacement: 'привет', flag: '🇷🇺' },
	{ kind: 'type', text: ' как дела?' },
	{ kind: 'wait', ms: 1700 },

	{ kind: 'front', window: 'notes', flag: '🇺🇸' },
	{ kind: 'caption', text: 'Korean composes into syllables, too.' },
	{ kind: 'wait', ms: 600 },
	{ kind: 'type', text: '\n' },
	{ kind: 'type', text: 'dkssudgktpdy', showKeys: true },
	{ kind: 'wait', ms: 250 },
	{ kind: 'fix', replacement: '안녕하세요', flag: '🇰🇷' },
	{ kind: 'type', text: ' 반가워요!' },
	{ kind: 'wait', ms: 1800 },

	{ kind: 'caption', text: 'And every app keeps its own language.' },
	{ kind: 'front', window: 'chat', flag: '🇷🇺' },
	{ kind: 'wait', ms: 1300 },
	{ kind: 'front', window: 'notes', flag: '🇰🇷' },
	{ kind: 'wait', ms: 1300 },
	{ kind: 'front', window: 'chat', flag: '🇷🇺' },
	{ kind: 'wait', ms: 1800 },
	{ kind: 'caption', text: '' },
	{ kind: 'wait', ms: endFor }
];

const keyInterval = 95;
const bubbleFor = 2200;
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

/** When the first step matching `test` happens. */
const when = (test: (step: Step) => boolean) => timeline.events.find((event) => test(event.step))!.at;
const captionAt = (text: string) => when((step) => step.kind === 'caption' && step.text.startsWith(text));

// Where the windows sit on the screen, in points; Demo.svelte lays out to the same numbers.
export const windows = {
	notes: { x: 440, y: 170, width: 780, height: 470 },
	chat: { x: 860, y: 300, width: 700, height: 440 }
} as const;

/** A medium shot of both windows and the menu bar, pushing in on each fix and up to the flag. */
const medium = { x: 1000, y: 400, zoom: 1 };
const onNotes = { x: windows.notes.x + 330, y: windows.notes.y + 150, zoom: 1.55 };
const onChat = { x: windows.chat.x + 300, y: windows.chat.y + 140, zoom: 1.55 };
const onFlag = { x: screen.width, y: 0, zoom: 2.1 };
const endAt = duration - endFor - 400;

/** The camera and the closing card; captions and keys come from the typing script above. */
export const film = direct((d) => {
	d.camera(wide);
	d.at(300).camera(medium);
	d.at(when((step) => step.kind === 'type' && !!step.showKeys) - 400).camera(onNotes);
	d.at(captionAt('Every script') - 200).camera(onChat);
	d.at(captionAt('Korean') - 200).camera({ ...onNotes, y: onNotes.y + 40 });
	d.at(captionAt('And every app')).camera(onFlag);
	d.at(endAt - 500).camera(wide);
	// The first fix, bubble showing.
	d.at(timeline.events.find((event) => event.step.kind === 'fix')!.at + 600).poster();
	d.at(endAt).end(duration - endAt);
});

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
		caretOn: true,
		sinceFlag: Infinity,
		sinceBubble: Infinity
	};
	let bubbleAt = -Infinity;
	let flagAt = -Infinity;
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
				if (frame.flag !== step.flag) flagAt = event.at;
				frame.flag = step.flag;
				frame.bubble = { window: frame.front, index: words.length - 1 };
				bubbleAt = event.at;
				break;
			}
			case 'caption':
				frame.caption = step.text;
				break;
			case 'front':
				frame.front = step.window;
				if (frame.flag !== step.flag) flagAt = event.at;
				frame.flag = step.flag;
				frame.bubble = null;
				break;
		}
	}
	if (t - bubbleAt > bubbleFor) frame.bubble = null;
	frame.sinceFlag = t - flagAt;
	frame.sinceBubble = t - bubbleAt;
	if (t - keysAt > keysFor) frame.keys = '';
	// The caret holds steady while typing and blinks when idle, as text fields do.
	frame.caretOn = t - lastKey < 500 || Math.floor(t / 530) % 2 === 0;
	return frame;
}
