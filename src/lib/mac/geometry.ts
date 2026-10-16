// The screen every scene is set on: a 16-inch MacBook Pro, measured on one running macOS 26.
// Sizes are in points. The scene is cropped to 16:10 at the bottom, which only loses Dock space.

export const screen = { width: 1728, height: 1080 };

/** The menu bar on a notched display is taller than the 24 pt one on other screens. */
export const menuBarHeight = 33;

/** The camera housing, from NSScreen.auxiliaryTopLeftArea and auxiliaryTopRightArea. */
export const notch = { left: 771, right: 957 };

/** System extras, right to left: the clock, then each item's slot width. */
export const clock = { text: 'Thu Oct 16  9:41 AM', width: 140, margin: 12 };
export const systemItems = [
	{ symbol: 'switch.2', width: 34 },
	{ symbol: 'magnifyingglass', width: 32 },
	{ symbol: 'wifi', width: 34 },
	{ symbol: 'battery.100percent', width: 44 }
] as const;

/** Where third-party menu bar extras end: their right edge, just left of the system's own. */
export const extrasRight =
	screen.width - clock.margin - clock.width - systemItems.reduce((sum, item) => sum + item.width, 0);

/** A status item's slot: the symbol plus the padding macOS puts around it. */
export const statusSlot = 32;

/** The output frame the camera looks through. */
export const viewport = { width: 1280, height: 800 };

/** The zoom that shows the whole screen. */
export const wide = { x: screen.width / 2, y: screen.height / 2, zoom: viewport.width / screen.width };
