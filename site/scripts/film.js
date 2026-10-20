// The film tool: lists, shoots, and records the demo films, and renders the glyphs they draw.
//
//   pnpm film list                                   each film's length, poster, and marks
//   pnpm film shot <tool> [moment ...] [--dark]      stills into shots/; a moment is ms, a mark, or "poster"
//   pnpm film record [tool ...] [--light | --dark]   videos and posters into static/<tool>/
//   pnpm film stills [tool ...]                      each page feature's still into static/<tool>/features/
//   pnpm film glyphs                                 SF Symbols and the cursor into static/symbols/
//
// shot and record run their own dev server with file watching off, so editing the site while a
// recording runs can't reload the page under it. They need Google Chrome; record also needs ffmpeg.

import { spawn } from 'node:child_process';
import { mkdir, mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright-core';
import { createServer } from 'vite';

const root = fileURLToPath(new URL('..', import.meta.url));
const fps = 30;
const viewport = { width: 1280, height: 800 };

function run(command, args) {
	return new Promise((resolve, reject) => {
		const child = spawn(command, args, { stdio: ['ignore', 'inherit', 'inherit'], cwd: root });
		child.on('error', reject);
		child.on('exit', (code) => (code === 0 ? resolve() : reject(new Error(`${command} exited ${code}`))));
	});
}

function usage(message) {
	if (message) console.error(`film: ${message}`);
	console.error(
		'usage: pnpm film list | shot <tool> [moment ...] [--dark] | record [tool ...] [--light|--dark] | stills [tool ...] | glyphs'
	);
	process.exit(2);
}

/** A dev server of our own, so the page never hot-reloads mid-recording. */
async function serve(work) {
	const server = await createServer({
		root,
		logLevel: 'error',
		server: { port: 5390, strictPort: false, hmr: false, watch: null }
	});
	await server.listen();
	try {
		const { films } = await server.ssrLoadModule('/src/lib/film/films.ts');
		const { pages } = await server.ssrLoadModule('/src/lib/pages.ts');
		return await work(server.resolvedUrls.local[0].replace(/\/$/, ''), films, pages);
	} finally {
		await server.close();
	}
}

/** Opens a film's page held still, ready to be stepped with seek(). */
async function open(browser, base, tool, dark, clean = false) {
	const page = await browser.newPage({ viewport, deviceScaleFactor: 2 });
	await page.goto(`${base}/${tool}/demo/?record${dark ? '&dark' : ''}${clean ? '&clean' : ''}`, {
		waitUntil: 'networkidle'
	});
	await page.waitForFunction(() => '__seek' in window);
	// The stage never moves, so measure it once and shoot that rectangle. An element screenshot waits
	// for the element to be "stable" every frame, which stalls on a busy machine.
	const clip = await page.locator('#stage').boundingBox();
	if (!clip) throw new Error(`the ${tool} film has no #stage`);
	return {
		page,
		clip,
		async still(t, options) {
			await page.evaluate((t) => window.__seek(t), t);
			// Two animation frames: one for Svelte to update the DOM, one for it to paint.
			await page.evaluate(
				() => new Promise((done) => requestAnimationFrame(() => requestAnimationFrame(done)))
			);
			await page.screenshot({ clip, ...options, timeout: 120_000 });
		}
	};
}

function pickTools(names, films) {
	for (const name of names)
		if (!(name in films)) usage(`no film '${name}'; try: ${Object.keys(films).join(', ')}`);
	return names.length ? names : Object.keys(films);
}

const [command, ...args] = process.argv.slice(2);
const flags = new Set(args.filter((arg) => arg.startsWith('--')));
const words = args.filter((arg) => !arg.startsWith('--'));

switch (command) {
	case 'list':
		await serve(async (_, films) => {
			for (const [tool, film] of Object.entries(films)) {
				const marks = Object.entries(film.marks).map(([name, at]) => `${name}@${at}`);
				console.log(
					`${tool.padEnd(6)} ${(film.duration / 1000).toFixed(1)} s  poster@${film.poster}  ${marks.join(' ')}`
				);
			}
		});
		break;

	case 'shot': {
		const [tool, ...moments] = words;
		if (!tool) usage('shot needs a tool');
		const out = join(root, 'shots');
		await mkdir(out, { recursive: true });
		await serve(async (base, films) => {
			pickTools([tool], films);
			const film = films[tool];
			const browser = await chromium.launch({ channel: 'chrome' });
			try {
				const { still } = await open(browser, base, tool, flags.has('--dark'));
				for (const moment of moments.length ? moments : ['poster']) {
					const t = moment === 'poster' ? film.poster : (film.marks[moment] ?? Number(moment));
					if (!Number.isFinite(t)) usage(`'${moment}' is not ms, a mark, or poster`);
					const path = join(out, `${tool}${flags.has('--dark') ? '-dark' : ''}-${moment}.png`);
					await still(t, { path });
					console.log(path);
				}
			} finally {
				await browser.close();
			}
		});
		break;
	}

	case 'record':
		await serve(async (base, films) => {
			const variants = flags.has('--light') ? [false] : flags.has('--dark') ? [true] : [false, true];
			const browser = await chromium.launch({ channel: 'chrome' });
			try {
				for (const tool of pickTools(words, films)) {
					const film = films[tool];
					const out = join(root, 'static', tool);
					for (const dark of variants) {
						const suffix = dark ? '-dark' : '';
						const frames = await mkdtemp(join(tmpdir(), `film-${tool}-`));
						try {
							const { page, still } = await open(browser, base, tool, dark);
							const count = Math.ceil((film.duration / 1000) * fps);
							console.log(
								`==> ${tool}${suffix}: ${count} frames (${(film.duration / 1000).toFixed(1)} s)`
							);
							for (let index = 0; index < count; index++) {
								await still((index * 1000) / fps, {
									path: join(frames, `${String(index).padStart(5, '0')}.png`)
								});
								if (index % 150 === 0) console.log(`    ${index}/${count}`);
							}
							await still(film.poster, {
								path: join(out, `poster${suffix}.jpg`),
								type: 'jpeg',
								quality: 88
							});
							console.log(`==> encoding static/${tool}/demo${suffix}.mp4`);
							// prettier-ignore
							await run('ffmpeg', [
								'-y', '-loglevel', 'error', '-framerate', String(fps), '-i', join(frames, '%05d.png'),
								// 1920 wide stays sharp on a retina screen at a fraction of the full capture's bytes.
								'-vf', 'scale=1920:1200:flags=lanczos', '-c:v', 'libx264', '-preset', 'slow', '-crf', '22',
								'-pix_fmt', 'yuv420p', '-movflags', '+faststart', join(out, `demo${suffix}.mp4`)
							]);
							await page.close();
						} finally {
							await rm(frames, { recursive: true, force: true });
						}
					}
				}
			} finally {
				await browser.close();
			}
		});
		break;

	case 'stills':
		await serve(async (base, films, pages) => {
			const browser = await chromium.launch({ channel: 'chrome' });
			try {
				for (const tool of pickTools(words, films)) {
					const features = pages[tool]?.features;
					if (!features) usage(`no page features for '${tool}'; add src/lib/${tool}/page.ts`);
					const film = films[tool];
					const out = join(root, 'static', tool, 'features');
					await mkdir(out, { recursive: true });
					for (const dark of [false, true]) {
						const { page, clip, still } = await open(browser, base, tool, dark, true);
						for (const [index, feature] of features.entries()) {
							const at =
								feature.at === 'poster'
									? film.poster
									: (film.marks[feature.at] ?? feature.at);
							if (!Number.isFinite(at))
								usage(
									`${tool} feature ${index + 1}: '${feature.at}' is not ms, a mark, or poster`
								);
							const crop = feature.crop ?? {
								x: 0,
								y: 0,
								width: viewport.width,
								height: viewport.height
							};
							const path = join(out, `${index + 1}${dark ? '-dark' : ''}.jpg`);
							await still(at, {
								path,
								type: 'jpeg',
								quality: 86,
								clip: {
									x: clip.x + crop.x,
									y: clip.y + crop.y,
									width: crop.width,
									height: crop.height
								}
							});
							console.log(path);
						}
						await page.close();
					}
				}
			} finally {
				await browser.close();
			}
		});
		break;

	case 'glyphs':
		await run('swift', ['scripts/render-glyphs.swift']);
		break;

	default:
		usage(command ? `unknown command '${command}'` : '');
}
