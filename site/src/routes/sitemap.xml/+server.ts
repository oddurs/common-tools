import { sitemap } from '#lib/seo.ts';

// Written once, at build time, like every page.
export const prerender = true;

export const GET = () =>
	new Response(
		`<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${sitemap
			.map((url) => `\t<url><loc>${url}</loc></url>`)
			.join('\n')}\n</urlset>\n`,
		{ headers: { 'content-type': 'application/xml' } }
	);
