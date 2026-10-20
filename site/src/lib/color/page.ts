// Common Color's page: what it does, each shown by a moment of its film.
import type { Page } from '../pages';

export const page: Page = {
	features: [
		{
			title: 'No permission.',
			text: 'Press ⌃⇧⌘C and click any pixel in macOS’s own loupe. Color gets that one color, never your screen, so there’s nothing to allow.',
			at: 4200,
			crop: { x: 92, y: 50, width: 720, height: 450 }
		},
		{
			title: 'Your format.',
			text: 'Hex, rgb(), hsl(), oklch(), Display P3, SwiftUI or AppKit, converted correctly between color spaces. A card by the pointer says what was copied.',
			at: 4800,
			crop: { x: 400, y: 215, width: 672, height: 420 }
		},
		{
			title: 'Picks and contrast.',
			text: 'The last 12 picks stay a click away, with the WCAG contrast between the newest two and whether it passes AA and AAA.',
			at: 'poster',
			crop: { x: 304, y: 0, width: 976, height: 610 }
		}
	]
};
