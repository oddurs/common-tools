import sizes from '../../../static/symbols/symbols.json';

export type SymbolName = Exclude<keyof typeof sizes, 'cursor'>;

/** Point size of a rendered SF Symbol, as scripts/render-glyphs.swift measured it. */
export const symbolSize = (name: SymbolName) => sizes[name];

export const cursor = sizes.cursor;
