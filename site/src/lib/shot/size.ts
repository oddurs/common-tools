// ShotKit's ImageSize and Geometry.snapped, in TypeScript, so every number the film shows (the size
// pill, the preview's caption, the history's subtitles) is the one the app would show.

/** The long edge a shot is sized to for prompts (`ImageSize.promptLongEdge`). */
export const promptLongEdge = 1568;

function fit(width: number, height: number, longEdge: number): [number, number] {
	const scale = Math.min(1, longEdge / Math.max(width, height));
	if (scale >= 1) return [width, height];
	return [Math.max(1, Math.round(width * scale)), Math.max(1, Math.round(height * scale))];
}

/** The size on the clipboard at the default setting, Prompt. */
export const sized = (width: number, height: number) => fit(width, height, promptLongEdge);

/** About one token per 750 pixels after fitting 2576 on the long edge, never more than 4,784. */
export function estimatedTokens(width: number, height: number): number {
	const [w, h] = fit(width, height, 2576);
	return Math.min(4784, Math.round((w * h) / 750));
}

/** "≈ 840 tokens", "≈ 2.1k tokens". */
export function describe(tokens: number): string {
	if (tokens < 1000) return `≈ ${tokens} tokens`;
	const tenths = Math.floor((tokens + 50) / 100);
	return `≈ ${Math.floor(tenths / 10)}.${tenths % 10}k tokens`;
}

export type Rect = { x: number; y: number; width: number; height: number };

/** Each edge on the nearest device pixel, as the overlay outlines it. */
export function snapped(rect: Rect, scale = 2): Rect {
	const snap = (v: number) => Math.round(v * scale) / scale;
	const x = snap(rect.x);
	const y = snap(rect.y);
	return { x, y, width: snap(rect.x + rect.width) - x, height: snap(rect.y + rect.height) - y };
}

/** The size pill's two runs for a rectangle in points: pixels as captured, tokens as sized. */
export function pill(rect: Rect, scale = 2): [string, string] {
	const width = Math.round(rect.width * scale);
	const height = Math.round(rect.height * scale);
	const [w, h] = sized(width, height);
	return [`${width} × ${height}`, describe(estimatedTokens(w, h))];
}

/** The preview's caption (`AppController.caption`). */
export function caption(width: number, height: number): string {
	const [w, h] = sized(width, height);
	return `Copied · ${w} × ${h} · ${describe(estimatedTokens(w, h))}`;
}

/** A history tile's subtitle: the sized shot and its cost. */
export function subtitle(width: number, height: number): string {
	const [w, h] = sized(width, height);
	return `${w} × ${h} · ${describe(estimatedTokens(w, h))}`;
}
