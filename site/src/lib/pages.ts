// What each app's page says beyond its film: a few features, each with a still from the film. Each app
// keeps its own in src/lib/<app>/page.ts, beside its film, so adding a page touches nothing shared.
// `pnpm film stills <app>` draws the stills into static/<app>/features/.

import type { AppSlug } from './tools';

export type Feature = {
	/** A few words, ending with a full stop. */
	title: string;
	/** One or two sentences, every claim true of the app's code. */
	text: string;
	/** The film's moment to show: ms, a mark, or "poster". */
	at: number | string;
	/** The part of the 1280 × 800 frame to show; the whole frame when left out. */
	crop?: { x: number; y: number; width: number; height: number };
	/**
	 * Further moments to show under the first, each cropped to the same strip and stacked top to
	 * bottom, for something too thin for a 16:10 frame of its own, like the menu bar in three styles.
	 * With it, `crop` is one strip, and the strips together make the 16:10.
	 */
	stack?: (number | string)[];
};

export type Page = {
	features: Feature[];
	/** Which feature's still (from 1) the card shows when the page is shared; the first when left out. */
	card?: number;
};

const modules = import.meta.glob<{ page: Page }>('./*/page.ts', { eager: true });

export const pages = Object.fromEntries(
	Object.entries(modules).map(([path, module]) => [path.split('/')[1], module.page])
) as Partial<Record<AppSlug, Page>>;
