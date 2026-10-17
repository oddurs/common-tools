// What each app's latest release is, read from GitHub when the site is built: the version, when it
// shipped, how big the download is, and what its CHANGELOG says changed. The site redeploys daily,
// so a new release shows up without touching this repository.

import { tools, type Tool } from './tools';

export type Notes = { heading: string; items: string[] }[];

export type Release = {
	version: string;
	/** ISO date, e.g. 2026-10-16. */
	date: string;
	/** Bytes of the download. */
	size: number;
	/** The CHANGELOG's section for this version: Added, Changed, Fixed… */
	notes: Notes;
};

export type Releases = Partial<Record<Tool['slug'], Release>>;

/**
 * The sections of one version in a Keep a Changelog file. Bullets may wrap onto indented lines.
 * Returns an empty list when the version isn't there.
 */
export function changelogNotes(changelog: string, version: string): Notes {
	const lines = changelog.split('\n');
	const start = lines.findIndex((line) => line.startsWith(`## [${version}]`));
	if (start < 0) return [];
	const notes: Notes = [];
	for (const line of lines.slice(start + 1)) {
		if (line.startsWith('## ')) break;
		if (line.startsWith('### ')) notes.push({ heading: line.slice(4).trim(), items: [] });
		else if (line.startsWith('- ') && notes.length) notes[notes.length - 1].items.push(line.slice(2).trim());
		else if (/^\s+\S/.test(line) && notes.length) {
			const items = notes[notes.length - 1].items;
			if (items.length) items[items.length - 1] += ` ${line.trim()}`;
		}
	}
	return notes.filter((section) => section.items.length);
}

const escape = (text: string) =>
	text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

/** The little Markdown a CHANGELOG bullet uses (bold, code, links), as HTML. Everything else is escaped. */
export function inlineMarkdown(text: string): string {
	return escape(text)
		.replace(/`([^`]+)`/g, '<code>$1</code>')
		.replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>')
		.replace(/\[([^\]]+)\]\((https:\/\/[^)\s]+)\)/g, '<a href="$2">$1</a>');
}

type Fetch = typeof fetch;

/** One tool's latest release, or null when GitHub can't say (offline, rate-limited, nothing released). */
export async function latestRelease(tool: Tool, fetch: Fetch, token?: string): Promise<Release | null> {
	const repo = new URL(tool.repo).pathname.slice(1);
	const headers: Record<string, string> = { accept: 'application/vnd.github+json' };
	if (token) headers.authorization = `Bearer ${token}`;
	try {
		const response = await fetch(`https://api.github.com/repos/${repo}/releases/latest`, { headers });
		if (!response.ok) throw new Error(`GitHub answered ${response.status}`);
		const release = (await response.json()) as {
			tag_name: string;
			published_at: string;
			assets: { name: string; size: number }[];
		};
		const version = release.tag_name.replace(/^v/, '');
		const asset = release.assets.find((a) => a.name === tool.asset);
		if (!asset) throw new Error(`release ${release.tag_name} has no ${tool.asset}`);
		const changelog = await fetch(
			`https://raw.githubusercontent.com/${repo}/${release.tag_name}/CHANGELOG.md`
		);
		const notes = changelog.ok ? changelogNotes(await changelog.text(), version) : [];
		return { version, date: release.published_at.slice(0, 10), size: asset.size, notes };
	} catch (error) {
		// The site still builds without release details; the download links don't depend on them.
		console.warn(`releases: no details for ${tool.name}: ${(error as Error).message}`);
		return null;
	}
}

export async function latestReleases(fetch: Fetch, token?: string): Promise<Releases> {
	const found = await Promise.all(tools.map((tool) => latestRelease(tool, fetch, token)));
	return Object.fromEntries(tools.flatMap((tool, i) => (found[i] ? [[tool.slug, found[i]]] : [])));
}

/** "1.7 MB", as Finder rounds it. */
export const megabytes = (bytes: number) => `${(bytes / 1_000_000).toFixed(1)} MB`;

/** "Oct 16, 2026". */
export const shortDate = (iso: string) =>
	new Date(`${iso}T12:00:00Z`).toLocaleDateString('en-US', {
		month: 'short',
		day: 'numeric',
		year: 'numeric'
	});
