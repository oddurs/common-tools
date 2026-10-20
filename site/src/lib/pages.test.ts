// Each app's page: a few features, each with its still in both appearances.
import { existsSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { pages } from './pages';

describe.each(Object.entries(pages))('%s page', (slug, page) => {
	it('shows three or four features, each with a title and a sentence', () => {
		expect(page!.features.length).toBeGreaterThanOrEqual(3);
		expect(page!.features.length).toBeLessThanOrEqual(4);
		for (const f of page!.features) {
			expect(f.title, f.title).toMatch(/\.$/);
			expect(f.text.length, f.title).toBeGreaterThan(20);
		}
	});
	it('has every still, light and dark; run `pnpm film stills` after changing a feature', () => {
		page!.features.forEach((_, i) => {
			for (const name of [`${i + 1}.jpg`, `${i + 1}-dark.jpg`])
				expect(existsSync(`static/${slug}/features/${name}`), `${slug} ${name}`).toBe(true);
		});
	});
	it('crops stills to the film frame', () => {
		for (const { crop, title, stack } of page!.features)
			if (crop) {
				const strips = 1 + (stack?.length ?? 0);
				expect(crop.x + crop.width, title).toBeLessThanOrEqual(1280);
				expect(crop.y + crop.height, title).toBeLessThanOrEqual(800);
				expect(crop.width / (crop.height * strips), title).toBeCloseTo(1.6, 1);
			}
	});
});
