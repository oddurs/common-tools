// WCAG 2 contrast, shared by the tokens test and the design page so both report the same ratio.

/** The relative luminance of #rrggbb. */
export function luminance(hex: string): number {
	const channel = (i: number) => {
		const c = parseInt(hex.slice(i, i + 2), 16) / 255;
		return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
	};
	return 0.2126 * channel(1) + 0.7152 * channel(3) + 0.0722 * channel(5);
}

/** The contrast ratio of two opaque #rrggbb colours, from 1 to 21. */
export function contrast(fg: string, bg: string): number {
	const [a, b] = [luminance(fg), luminance(bg)].sort((x, y) => y - x);
	return (a + 0.05) / (b + 0.05);
}
