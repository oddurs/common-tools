import { error } from '@sveltejs/kit';
import { tools } from '#lib/tools.ts';
import type { EntryGenerator, PageLoad } from './$types';

// The card shown when a page is shared: one for the home page, one per app. `pnpm film cards`
// photographs each into static/.
export const entries: EntryGenerator = () => [{ page: 'home' }, ...tools.map(({ slug }) => ({ page: slug }))];

export const load: PageLoad = ({ params }) => {
	if (params.page === 'home') return { tool: null };
	const tool = tools.find((t) => t.slug === params.page);
	if (!tool) error(404, `no card '${params.page}'`);
	return { tool };
};
