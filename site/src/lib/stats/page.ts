// Common Stats' page: what it does, each shown by a moment of its film.
import type { Page } from '../pages';

export const page: Page = {
	card: 2,
	features: [
		{
			title: 'Native.',
			text: 'The menu bar tints it like the clock, and a click opens a real menu. VoiceOver reads every value.',
			at: 4500,
			crop: { x: 616, y: 0, width: 664, height: 415 }
		},
		{
			title: 'Graphs that tell the truth.',
			text: 'Monotone curves, so smoothing never invents a peak. Rate graphs show their scale, and hovering reads back any past value.',
			at: 'poster',
			crop: { x: 135, y: 102, width: 1056, height: 660 }
		},
		{
			title: 'Yours to arrange.',
			text: 'Show each metric as a value, a graph, or a gauge, whichever suits it, or hide it. Drag to reorder, and pick a density and update rate.',
			// The bar three ways, stacked: values, graphs, gauges.
			at: 'values',
			stack: ['graphs', 'gauges'],
			crop: { x: 552, y: 0, width: 544, height: 113 }
		}
	]
};
