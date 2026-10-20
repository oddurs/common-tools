// Common Keys' page: what it does, each shown by a moment of its film.
import type { Page } from '../pages';

export const page: Page = {
	features: [
		{
			title: 'Fixed as you type.',
			text: 'A word finished on the wrong layout is retyped on the right one, and the keyboard switches. ⌘Z right away undoes it, and that word is left alone.',
			// "Takk fyrir, þetta er frábært!" typed, with the bubble for þetta still up.
			at: 5250,
			crop: { x: 24, y: 24, width: 960, height: 600 }
		},
		{
			title: 'Every keyboard.',
			text: 'All 251 layouts in macOS, across 35 scripts, read with the system’s own key tables. Korean syllables and Vietnamese tones compose both ways.',
			// "привет как дела?" in Chat, with the bubble and the flag on Russian.
			at: 9300,
			crop: { x: 102, y: 0, width: 1178, height: 736.25 }
		},
		{
			title: 'Each app, its own layout.',
			text: 'Each app comes back on the layout you last used there, or the one you usually write in. A switch in one never leaks into another.',
			// Chat just clicked forward over Notes, and the flag back on Russian.
			at: 17200
		}
	]
};
