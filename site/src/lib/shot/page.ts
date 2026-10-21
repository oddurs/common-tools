// Common Shot's page: what it does, each shown by a moment of its film.
import type { Page } from '../pages';

export const page: Page = {
	card: 3,
	features: [
		{
			title: 'Drag, click, or Return.',
			text: 'Drag for an area, with its size and a loupe; click for the window under the pointer; Return for the whole screen.',
			at: 7000,
			crop: { x: 120, y: 100, width: 1120, height: 700 }
		},
		{
			title: 'Sized for prompts.',
			text: 'Shots go to the clipboard as PNG, at most 1568 pixels on the long edge, with what they cost in Claude tokens. Full resolution is a setting.',
			at: 9800,
			crop: { x: 832, y: 520, width: 448, height: 280 }
		},
		{
			title: 'Recent shots, close by.',
			text: 'The menu bar panel keeps your recent shots by day. Click one to copy it again, or drag it out as a file.',
			at: 15600,
			crop: { x: 560, y: 0, width: 720, height: 450 }
		}
	]
};
