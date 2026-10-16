export const percent = (n: number) => `${Math.round(n)}%`;

/** A rate given in MB/s, written the way the app writes it. */
export function rate(mbps: number): string {
	if (mbps >= 1) return `${mbps.toFixed(1)} MB/s`;
	const kb = mbps * 1000;
	return kb >= 1 ? `${kb.toFixed(kb < 10 ? 1 : 0)} KB/s` : `${Math.round(kb * 1000)} B/s`;
}

/** An SVG path for a history graph: the line, or the line closed down to the baseline as an area. */
export function graph(values: number[], width: number, height: number, max: number, area = false): string {
	const step = width / (values.length - 1);
	const points = values.map(
		(v, i) => `${(i * step).toFixed(1)},${(height - (Math.min(v, max) / max) * height).toFixed(1)}`
	);
	const line = `M${points.join('L')}`;
	return area ? `${line}L${width},${height}L0,${height}Z` : line;
}
