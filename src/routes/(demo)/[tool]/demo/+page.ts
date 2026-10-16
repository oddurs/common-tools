import { error } from '@sveltejs/kit';
import { films } from '#lib/film/films.ts';
import type { EntryGenerator, PageLoad } from './$types';

// Prerender one demo page per film.
export const entries: EntryGenerator = () => Object.keys(films).map((tool) => ({ tool }));

export const load: PageLoad = ({ params }) => {
	if (!(params.tool in films)) error(404, `no film for '${params.tool}'`);
	return { tool: params.tool as keyof typeof films };
};
