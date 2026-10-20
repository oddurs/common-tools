// The geometry of the menu's HistoryChart (apps/stats/Sources/CommonStats/HistoryChart.swift): newest
// sample on the right edge, one step per sample of the full history, monotone curves that never
// invent a peak, and a mirrored layout for rates with upload above a midline and download below.

/** Fritsch–Carlson tangents, as StatKit's monotoneTangents computes them. */
export function monotoneTangents(y: number[]): number[] {
	const n = y.length;
	if (n < 2) return y.map(() => 0);
	const d = y.slice(1).map((v, i) => v - y[i]);
	const m = new Array<number>(n).fill(0);
	m[0] = d[0];
	m[n - 1] = d[n - 2];
	for (let k = 1; k < n - 1; k++) m[k] = d[k - 1] * d[k] <= 0 ? 0 : (d[k - 1] + d[k]) / 2;
	for (let k = 0; k < n - 1; k++) {
		if (d[k] === 0) {
			m[k] = 0;
			m[k + 1] = 0;
			continue;
		}
		const a = m[k] / d[k];
		const b = m[k + 1] / d[k];
		const s = a * a + b * b;
		if (s > 9) {
			const t = 3 / Math.sqrt(s);
			m[k] = t * a * d[k];
			m[k + 1] = t * b * d[k];
		}
	}
	return m;
}

export type Rect = { x: number; y: number; width: number; height: number };

/** The y of a fraction in a plot area, growing up from its bottom, or down from its top. */
export const yOf = (f: number, rect: Rect, down: boolean) =>
	down ? rect.y + rect.height * f : rect.y + rect.height - rect.height * f;

/**
 * A series' smooth edge and the same edge closed to its baseline, as SVG paths. `values` are
 * fractions of full scale, oldest first; the newest sits on the plot's right edge.
 */
export function series(
	values: number[],
	rect: Rect,
	step: number,
	down = false
): { line: string; area: string } {
	const v = values.map((x) => Math.min(Math.max(x, 0), 1));
	const m = monotoneTangents(v);
	const sign = down ? 1 : -1;
	const first = rect.x + rect.width - (v.length - 1) * step;
	const px = (i: number) => first + i * step;
	const f = (n: number) => n.toFixed(2);
	let line = `M${f(px(0))},${f(yOf(v[0], rect, down))}`;
	for (let i = 0; i < v.length - 1; i++) {
		const c1y = yOf(v[i], rect, down) + sign * rect.height * (m[i] / 3);
		const c2y = yOf(v[i + 1], rect, down) - sign * rect.height * (m[i + 1] / 3);
		line += `C${f(px(i) + step / 3)},${f(c1y)} ${f(px(i + 1) - step / 3)},${f(c2y)} ${f(px(i + 1))},${f(yOf(v[i + 1], rect, down))}`;
	}
	const base = down ? rect.y : rect.y + rect.height;
	const area = `${line}L${f(px(v.length - 1))},${f(base)}L${f(first)},${f(base)}Z`;
	return { line, area };
}
