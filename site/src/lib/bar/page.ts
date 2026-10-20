// Common Bar's page: what it does, each shown by a moment of its film.
import type { Page } from '../pages';

export const page: Page = {
	features: [
		{
			title: 'A tidy menu bar.',
			text: 'Every icon left of your folders stays off the menu bar, clear of the notch. Click a folder to see them, each with its app’s icon and name.',
			at: 'poster',
			crop: { x: 160, y: 0, width: 1120, height: 700 }
		},
		{
			title: 'Type to find one.',
			text: 'Start typing to narrow the list. Arrows, Return and Escape work as in any menu, without taking focus from the app you’re in.',
			at: 8300,
			crop: { x: 480, y: 0, width: 800, height: 500 }
		},
		{
			title: 'Opens beside the folder.',
			text: 'Choose an icon and its own menu opens under the folder. When you’re done, the icon goes back where it was.',
			at: 9800,
			crop: { x: 400, y: 0, width: 720, height: 450 }
		}
	]
};
