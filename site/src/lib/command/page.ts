// Common Command's page: what it does, each shown by a moment of its film.
import type { Page } from '../pages';

export const page: Page = {
	features: [
		{
			title: 'Everything in one panel.',
			text: 'Apps, System Settings panes, files and folders from the Spotlight index, your shortcuts, and the web. “dark mode” finds the right pane.',
			at: 'darkTyped',
			crop: { x: 224, y: 36, width: 960, height: 600 }
		},
		{
			title: 'Learns what you mean.',
			text: 'Fuzzy matching on word starts, with case and accents folded. The result you choose for a query comes first next time.',
			at: 'calTyped',
			crop: { x: 224, y: 36, width: 960, height: 600 }
		},
		{
			title: 'Sums and units.',
			text: 'Sums like “(4 + 5) * 12” and conversions like “10 km to mi”, answered offline as you type. Return copies the result.',
			at: 'sumTyped',
			crop: { x: 224, y: 36, width: 960, height: 600 }
		}
	]
};
