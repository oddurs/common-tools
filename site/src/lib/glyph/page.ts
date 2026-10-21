// Common Glyph's page: what it does, each shown by a moment of its film.
import type { Page } from '../pages';

export const page: Page = {
	card: 3,
	features: [
		{
			title: 'Anything you like.',
			text: 'An image, an animated GIF, an emoji, or a piece of text. Add as many as you want, each its own menu bar item.',
			at: 14_500,
			crop: { x: 322, y: 104, width: 640, height: 400 }
		},
		{
			title: 'Made to fit.',
			text: 'Crop, rotate, and flip. Vision lifts the subject out of a photo, and Silhouette or Ink tints it like the system’s own icons.',
			at: 6600,
			crop: { x: 208, y: 140, width: 768, height: 480 }
		},
		{
			title: 'A menu for each.',
			text: 'Edit the glyph, choose or paste a new image, add another, or hide it. New glyphs start beside the clock, so a menu bar manager doesn’t hide them.',
			at: 'poster',
			crop: { x: 240, y: 0, width: 1024, height: 640 }
		}
	]
};
