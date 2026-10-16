// The screen every scene is set on: a 1728-point-wide display with no camera housing, as macOS 26
// draws it. Sizes are in points. The scene is cropped to 16:10 at the bottom, which only loses Dock
// space.

export const screen = { width: 1728, height: 1080 };

/** The menu bar on a display without a notch. Notched displays use a taller one. */
export const menuBarHeight = 24;

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
