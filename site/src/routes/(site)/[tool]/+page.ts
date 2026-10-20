import { error } from '@sveltejs/kit';
import { tools } from '#lib/tools.ts';
import type { EntryGenerator, PageLoad } from './$types';

// A page for each app drawn by this shared page. Apps with a page of their own (stats, keys, bar)
// have their own routes, which take precedence.
export const entries: EntryGenerator = () =>
	tools.filter((t) => t.features).map(({ slug }) => ({ tool: slug }));

export const load: PageLoad = ({ params }) => {
	const tool = tools.find((t) => t.slug === params.tool && t.features);
	if (!tool) error(404, `no app '${params.tool}'`);
	return { tool };
};
