// The Common Tools app standard: rendering templates, keeping each app's own regions, and checking
// the files every app owns for the structure the standard expects. Pure functions; the CLI in
// scripts/standard.js does the reading and writing.

/** Fills {{KEY}} placeholders. An unknown key is an error, so a typo can't ship as literal text. */
export function render(text, vars) {
	return text.replace(/\{\{([A-Z_]+)\}\}/g, (_, key) => {
		if (!(key in vars)) throw new Error(`no value for {{${key}}}`);
		return vars[key];
	});
}

const marker = /standard:(begin|end) ([a-z-]+)/;

/**
 * Splits a file into shared text and named regions. Regions are delimited by lines containing
 * `standard:begin <name>` and `standard:end <name>`; the marker lines belong to the shared text.
 */
export function regions(text) {
	const parts = [];
	let shared = [];
	let open = null;
	for (const line of text.split('\n')) {
		const m = line.match(marker);
		if (m && m[1] === 'begin') {
			if (open) throw new Error(`region '${m[2]}' opens inside '${open.name}'`);
			shared.push(line);
			parts.push({ shared: shared.join('\n') });
			shared = [];
			open = { name: m[2], lines: [] };
		} else if (m && m[1] === 'end') {
			if (!open || open.name !== m[2]) throw new Error(`region '${m[2]}' closes without opening`);
			parts.push({ region: open.name, body: open.lines.join('\n') });
			open = null;
			shared.push(line);
		} else if (open) {
			open.lines.push(line);
		} else {
			shared.push(line);
		}
	}
	if (open) throw new Error(`region '${open.name}' never closes`);
	parts.push({ shared: shared.join('\n') });
	return parts;
}

const bodies = (parts) =>
	Object.fromEntries(parts.filter((p) => 'region' in p).map((p) => [p.region, p.body]));

/** The template's shared text with each region's body taken from `current`, else `seeds`, else kept empty. */
export function merge(template, current = '', seeds = {}) {
	const own = current ? bodies(regions(current)) : {};
	return regions(template)
		.map((part) => {
			if ('shared' in part) return part.shared;
			const body = own[part.region] ?? seeds[part.region] ?? part.body;
			return body === '' ? null : body;
		})
		.filter((piece) => piece !== null)
		.join('\n');
}

/** How `current` differs from the template outside the app's regions, as human-readable problems. */
export function compare(template, current) {
	const expected = merge(template, current);
	if (expected === current) return [];
	const want = expected.split('\n');
	const have = current.split('\n');
	let line = 0;
	while (line < want.length && want[line] === have[line]) line++;
	return [
		`differs from the standard at line ${line + 1}:\n    standard: ${JSON.stringify(want[line] ?? '<end of file>')}\n    here:     ${JSON.stringify(have[line] ?? '<end of file>')}`
	];
}

/** The `##` headings of a Markdown document, in order. */
const headings = (markdown) => [...markdown.matchAll(/^## (.+)$/gm)].map((m) => m[1].trim());

/** Checks an owned file's structure. Returns problems; an empty list means it conforms. */
export const owned = {
	'README.md'(text, app) {
		const problems = [];
		if (!text.startsWith(`# ${app.NAME}\n`)) problems.push(`must start with "# ${app.NAME}"`);
		const required = ['Install', 'Usage', 'Build from source', 'Development', 'Licence'];
		const found = headings(text).filter((h) => required.includes(h));
		if (found.join('|') !== required.join('|'))
			problems.push(
				`needs the sections ${required.join(', ')} in that order (found: ${found.join(', ') || 'none'})`
			);
		if (!text.includes(`releases/latest/download/${app.ASSET}.zip`))
			problems.push(`must link the latest download, releases/latest/download/${app.ASSET}.zip`);
		return problems;
	},
	'CHANGELOG.md'(text, app) {
		const problems = [];
		if (!text.startsWith('# Changelog\n')) problems.push('must start with "# Changelog"');
		const sections = headings(text);
		if (sections[0] !== '[Unreleased]') problems.push('the first section must be "## [Unreleased]"');
		for (const s of sections.slice(1))
			if (!/^\[\d+\.\d+\.\d+\] - \d{4}-\d{2}-\d{2}$/.test(s))
				problems.push(`"## ${s}" isn't "## [x.y.z] - YYYY-MM-DD"`);
		const repo = `https://github.com/oddurs/${app.REPO}/`;
		if (!text.includes(`[Unreleased]: ${repo}compare/`))
			problems.push(`needs an [Unreleased]: ${repo}compare/… link`);
		return problems;
	},
	'Package.swift'(text, app) {
		const problems = [];
		if (!text.startsWith('// swift-tools-version: 6.0\n'))
			problems.push('must declare swift-tools-version: 6.0');
		if (!text.includes(`name: "${app.ASSET}"`)) problems.push(`the package must be named "${app.ASSET}"`);
		const platform = text.match(/\.macOS\((?:\.v(\d+)|"([\d.]+)")\)/);
		const declared = platform ? (platform[2] ?? `${platform[1]}.0`) : null;
		if (declared !== app.MIN_MACOS)
			problems.push(`platforms must be macOS ${app.MIN_MACOS} (found ${declared})`);
		if (!text.includes(`.testTarget(name: "${app.KIT}Tests"`))
			problems.push(`needs the test target ${app.KIT}Tests`);
		return problems;
	},
	'Resources/Info.plist'(text, app) {
		const problems = [];
		const value = (key) =>
			text
				.match(new RegExp(`<key>${key}</key>\\s*<(?:string>([^<]*)</string|(true|false)/)>`))
				?.slice(1)
				.find(Boolean);
		const expect = {
			CFBundleDevelopmentRegion: 'en',
			CFBundleDisplayName: app.NAME,
			CFBundleName: app.NAME,
			CFBundleExecutable: app.TARGET,
			CFBundleIdentifier: app.BUNDLE,
			CFBundleIconFile: 'AppIcon',
			CFBundleInfoDictionaryVersion: '6.0',
			CFBundlePackageType: 'APPL',
			LSApplicationCategoryType: 'public.app-category.utilities',
			LSMinimumSystemVersion: app.MIN_MACOS,
			LSUIElement: 'true',
			NSHighResolutionCapable: 'true',
			NSHumanReadableCopyright: '© 2026 Oddur Sigurdsson'
		};
		for (const [key, want] of Object.entries(expect)) {
			const have = value(key);
			if (have !== want)
				problems.push(`${key} must be ${JSON.stringify(want)} (found ${JSON.stringify(have)})`);
		}
		for (const key of ['CFBundleShortVersionString', 'CFBundleVersion'])
			if (!value(key)) problems.push(`needs ${key}`);
		return problems;
	},
	'.github/ISSUE_TEMPLATE/bug_report.yml'(text) {
		return ['version', 'macos']
			.filter((id) => !new RegExp(`id: ${id}\\b`).test(text))
			.map((id) => `needs a field with id: ${id}`);
	},
	'.github/ISSUE_TEMPLATE/feature_request.yml'(text) {
		return text.includes('name:') ? [] : ['must be an issue form'];
	}
};

/** The GitHub settings every app repository has. */
export function settings(app) {
	return {
		repo: {
			description: app.description,
			homepage: `https://oddurs.github.io/common-tools/${app.slug}/`,
			has_issues: true,
			has_projects: false,
			has_wiki: false,
			has_discussions: false,
			allow_squash_merge: true,
			allow_merge_commit: false,
			allow_rebase_merge: false,
			allow_auto_merge: true,
			allow_update_branch: true,
			delete_branch_on_merge: true,
			squash_merge_commit_title: 'PR_TITLE',
			squash_merge_commit_message: 'PR_BODY'
		},
		topics: [
			'macos',
			'menu-bar',
			'menubar-app',
			'swift',
			'swiftui',
			'appkit',
			'apple-silicon',
			'common-tools',
			...app.topics
		].sort(),
		protection: {
			required_status_checks: { strict: false, contexts: ['required'] },
			enforce_admins: true,
			required_pull_request_reviews: { dismiss_stale_reviews: true, required_approving_review_count: 0 },
			restrictions: null,
			required_conversation_resolution: true,
			allow_force_pushes: false,
			allow_deletions: false
		},
		workflow_permissions: 'read'
	};
}
