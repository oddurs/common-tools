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
};

export type Page = { features: Feature[] };

const modules = import.meta.glob<{ page: Page }>('./*/page.ts', { eager: true });

export const pages = Object.fromEntries(
	Object.entries(modules).map(([path, module]) => [path.split('/')[1], module.page])
) as Partial<Record<AppSlug, Page>>;
