import { error } from '@sveltejs/kit';
import { tools } from '#lib/tools.ts';
import type { EntryGenerator, PageLoad } from './$types';

// One page per app, all from the same template.
export const entries: EntryGenerator = () => tools.map(({ slug }) => ({ tool: slug }));

export const load: PageLoad = ({ params }) => {
	const tool = tools.find((t) => t.slug === params.tool);
	if (!tool) error(404, `no app '${params.tool}'`);
	return { tool };
};
