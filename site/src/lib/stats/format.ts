// StatKit's Format, for the film: the same rounding and units, so every number on screen is one the
// app could have written.

/** A fraction as a whole percentage, clamped to 0–100%. */
export const percent = (fraction: number) => `${Math.round(Math.min(Math.max(fraction, 0), 1) * 100)}%`;

function bytes(value: number, base: number): string {
	const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
	const round = (v: number) => (v < 10 ? Math.round(v * 10) / 10 : Math.round(v));
	let v = Math.max(value, 0);
	let unit = 0;
	// Round before choosing the unit, so 999.7 KB becomes 1.0 MB, not "1000 KB".
	while (unit < units.length - 1 && round(v) >= 1000) {
		v /= base;
		unit++;
	}
	if (unit === 0) return `${Math.round(v)} B`;
	return v < 10 && Math.round(v * 10) / 10 < 10
		? `${v.toFixed(1)} ${units[unit]}`
		: `${Math.round(v)} ${units[unit]}`;
}

/** Bytes per second in decimal units, as Activity Monitor reports traffic. */
export const rate = (bytesPerSecond: number) => `${bytes(bytesPerSecond, 1000)}/s`;

/** Decimal units, as Finder reports storage. */
export const storage = (value: number) => bytes(value, 1000);

/** Binary units labelled GB, as Apple reports RAM. */
export const memory = (value: number) => bytes(value, 1024);

export function uptime(seconds: number): string {
	const minutes = Math.floor(seconds / 60);
	const [d, h, m] = [Math.floor(minutes / 1440), Math.floor(minutes / 60) % 24, minutes % 60];
	if (d > 0) return `${d}d ${h}h`;
	if (h > 0) return `${h}h ${m}m`;
	return `${m}m`;
}

/** How long ago a sample was, as the menu's read-back says it. */
export function ago(seconds: number): string {
	if (seconds < 0.5) return 'now';
	const s = Math.round(seconds);
	return s < 60 ? `${s}s ago` : `${Math.floor(s / 60)}m ${s % 60}s ago`;
}
