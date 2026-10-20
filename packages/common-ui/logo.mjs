// The Common Tools mark: a "C" of seven arcs, one per app in its brand colour, sorted round the wheel,
// on an ink squircle, drawn from the brand tokens so it never drifts from the icons.
//
//   node packages/common-ui/logo.mjs > site/static/icon.svg
import { brand, source, toOklch } from './build.mjs';
const { tokens } = source();
// One arc per app with a single system colour, ordered round the wheel from red.
const apps = Object.entries(tokens.brand.apps)
	.filter(([key, app]) => key !== 'about' && app.system)
	.map(([slug]) => [slug, brand(tokens, slug).mid])
	.sort((a, b) => ((toOklch(a[1]).h + 330) % 360) - ((toOklch(b[1]).h + 330) % 360));
const cx = 48, cy = 48, r = 23, stroke = 11;
const open = 70; // degrees of the C's mouth, centred on the right
const gap = 4;
const span = (360 - open - gap * (apps.length - 1)) / apps.length;
const pt = (deg) => [cx + r * Math.cos((deg * Math.PI) / 180), cy - r * Math.sin((deg * Math.PI) / 180)];
let start = open / 2;
const arcs = apps.map(([, color]) => {
	const [x1, y1] = pt(start), [x2, y2] = pt(start + span);
	const d = `M${x1.toFixed(2)} ${y1.toFixed(2)}A${r} ${r} 0 0 0 ${x2.toFixed(2)} ${y2.toFixed(2)}`;
	start += span + gap;
	return `  <path d="${d}" stroke="${color}"/>`;
});
console.log(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#3a3a40"/>
      <stop offset="1" stop-color="#121214"/>
    </linearGradient>
  </defs>
  <rect x="4" y="4" width="88" height="88" rx="21" fill="url(#g)"/>
  <g fill="none" stroke-width="${stroke}" stroke-linecap="butt">
${arcs.join('\n')}
  </g>
</svg>`);
