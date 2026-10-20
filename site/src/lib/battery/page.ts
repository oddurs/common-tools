// Common Battery's page: what it does, each shown by a moment of its film.
import type { Page } from '../pages';

export const page: Page = {
	features: [
		{
			title: 'Your parts, your order.',
			text: 'The icon, the percentage beside it or inside it, and the time left, in the order you choose. Red when low, yellow in Low Power Mode, or monochrome.',
			at: 2000,
			crop: { x: 358, y: 0, width: 560, height: 350 }
		},
		{
			title: 'Alerts at your levels.',
			text: 'A notification as the battery drains to the level you choose, and as it charges to 80, 90 or 100%.',
			at: 5000,
			crop: { x: 640, y: 0, width: 640, height: 400 }
		},
		{
			title: 'Everything in one menu.',
			text: 'A 12-hour charge chart, live watts, cycle count, capacity and temperature. The time left learns how you use your Mac.',
			at: 13_000,
			crop: { x: 448, y: 0, width: 832, height: 520 }
		}
	]
};
