import { error } from '@sveltejs/kit';
import { upcoming } from '#lib/tools.ts';
import type { EntryGenerator, PageLoad } from './$types';

// A page for each app on its way. Released apps have their own routes, which take precedence.
export const entries: EntryGenerator = () => upcoming.map(({ slug }) => ({ tool: slug }));

export const load: PageLoad = ({ params }) => {
	const app = upcoming.find((u) => u.slug === params.tool);
	if (!app) error(404, `no app '${params.tool}'`);
	return { app };
};
