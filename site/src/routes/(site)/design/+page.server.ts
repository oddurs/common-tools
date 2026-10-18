import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { entries, type Tokens } from '../../../../../packages/common-ui/build.mjs';
import swift from '../../../../../packages/CommonKit/Sources/CommonUI/Tokens.swift?raw';
import source from '../../../../../packages/common-ui/tokens.json';
import apps from '../../../../../apps.json';
import renders from '../../../../static/design/renders.json';
import { mapping, swatches } from '#lib/design.ts';
import type { PageServerLoad } from './$types';

// Vite builds and prerenders from site/, as the tests run; a bundled module can't find the
// repository from its own URL.
const root = join(process.cwd(), '..');

/** Each app's committed docs images besides its icon, with their sizes, read from the PNG header. */
function appImages() {
	return Object.keys(apps).flatMap((slug) => {
		const dir = join(root, 'apps', slug, 'docs');
		if (!existsSync(dir)) return [];
		return readdirSync(dir)
			.filter((file) => file.endsWith('.png') && file !== 'icon.png')
			.sort()
			.map((file) => {
				const png = readFileSync(join(dir, file));
				return {
					slug,
					file,
					path: `apps/${slug}/docs/${file}`,
					width: png.readUInt32BE(16),
					height: png.readUInt32BE(20)
				};
			});
	});
}

// Runs at build time, like every load here: the page is prerendered from the tokens as they are.
export const load: PageServerLoad = () => {
	const tokens = source as unknown as Tokens;
	const numbers = (group: Record<string, unknown>) =>
		entries(group).map(([name, value]) => ({ name, value: value as number }));
	return {
		swatches: swatches(tokens),
		mapping: mapping(tokens, swift),
		type: entries(tokens.type).map(([name, step]) => ({ name, ...step })),
		space: numbers(tokens.space),
		radius: numbers(tokens.radius),
		durations: numbers(tokens.motion.duration),
		easings: entries(tokens.motion.easing).map(([name, curve]) => ({ name, curve })),
		layers: numbers(tokens.layer),
		layout: numbers(tokens.layout),
		shadows: entries(tokens.elevation).map(([name]) => name),
		about: {
			space: tokens.space.about ?? '',
			radius: tokens.radius.about ?? '',
			motion: tokens.motion.about,
			layout: tokens.layout.about ?? '',
			type: tokens.type.about ?? '',
			contrast: tokens.contrast.about
		},
		renders,
		appImages: appImages(),
		palette: Object.keys(tokens.palette).length,
		apps: Object.fromEntries(Object.entries(apps).map(([slug, app]) => [slug, app.NAME]))
	};
};
