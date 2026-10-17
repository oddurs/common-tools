import { GITHUB_TOKEN } from '$app/env/private';
import { latestReleases } from '#lib/releases.ts';
import type { LayoutServerLoad } from './$types';

// Runs once, at build time: the site is prerendered.
export const load: LayoutServerLoad = async ({ fetch }) => ({
	releases: await latestReleases(fetch, GITHUB_TOKEN)
});
