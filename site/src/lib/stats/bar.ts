// StatKit's BarRenderer layout pass, for the film: which parts each item draws and how wide each is,
// at regular density with captions on. Widths are what BarRenderer measures on macOS 26 (system
// font, 7.5-point captions, 10-point stacked values, 9-point rate pairs), and depend only on the
// layout, never on the values, so the item never resizes as numbers change.

export type Metric = 'cpu' | 'gpu' | 'memory' | 'network' | 'disk' | 'storage' | 'battery';
export type Style = 'value' | 'graph' | 'graphValue' | 'gauge' | 'gaugeValue';
export type BarItem = { metric: Metric; style: Style };
export type Part = 'caption' | 'graph' | 'gauge' | 'value';

export const captions: Record<Metric, string> = {
	cpu: 'CPU',
	gpu: 'GPU',
	memory: 'MEM',
	network: 'NET',
	disk: 'DISK',
	storage: 'FREE',
	battery: 'BAT'
};

const captionWidth: Record<Metric, number> = {
	cpu: 18,
	gpu: 19,
	memory: 20,
	network: 18,
	disk: 21,
	storage: 22,
	battery: 17
};
/** "100%" stacked; "888 GB"; "100%" and the charging bolt; the widest rate with its glyph. */
const valueWidth: Record<Metric, number> = {
	cpu: 30,
	gpu: 30,
	memory: 30,
	network: 53,
	disk: 55,
	storage: 38,
	battery: 38
};
export const graphWidth = 30;
export const gaugeWidth = 4;
export const itemGap = 11;
export const partGap = 3;

const showsValue = (style: Style) => style === 'value' || style === 'graphValue' || style === 'gaugeValue';

/** A caption sits above the value when there is one, otherwise beside the chart. */
export function parts(item: BarItem): Part[] {
	const parts: Part[] = [];
	if (!showsValue(item.style)) parts.push('caption');
	if (item.style === 'graph' || item.style === 'graphValue') parts.push('graph');
	if (item.style === 'gauge' || item.style === 'gaugeValue') parts.push('gauge');
	if (showsValue(item.style)) parts.push('value');
	return parts;
}

export function partWidth(part: Part, metric: Metric): number {
	return { caption: captionWidth[metric], graph: graphWidth, gauge: gaugeWidth, value: valueWidth[metric] }[
		part
	];
}

export const cellWidth = (item: BarItem) =>
	parts(item).reduce((sum, part, i) => sum + (i ? partGap : 0) + partWidth(part, item.metric), 0);

export const barWidth = (items: BarItem[]) =>
	items.reduce((sum, item, i) => sum + (i ? itemGap : 0) + cellWidth(item), 0);
