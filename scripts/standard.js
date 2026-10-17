// Keeps the three app repositories on the Common Tools app standard (standard/).
//
//   node scripts/standard.js check [app ...] [--from <dir>]    report drift; exit 1 if any
//   node scripts/standard.js apply <app> <worktree> [--seeds <file.json>]
//   node scripts/standard.js settings <check|apply> [app ...]   GitHub repository settings (needs gh)
//
// check reads each app's main branch: from ../<DIR> with `git show origin/main:<path>` by default,
// or from <dir>/<REPO>/ (a checkout, as in CI) with --from. apply writes the managed files into a
// worktree, keeping the app's own regions; --seeds supplies region text a file doesn't have yet.

import { execFileSync } from 'node:child_process';
import {
	existsSync,
	mkdirSync,
	readdirSync,
	readFileSync,
	statSync,
	writeFileSync,
	chmodSync
} from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { compare, merge, owned, render, settings } from '../standard/lib.js';

const root = fileURLToPath(new URL('..', import.meta.url));
const templates = join(root, 'standard', 'app');
const apps = Object.fromEntries(
	Object.entries(JSON.parse(readFileSync(join(root, 'standard', 'apps.json'), 'utf8'))).map(([slug, app]) => [
		slug,
		{ ...app, slug }
	])
);

const args = process.argv.slice(2);
const option = (name) => {
	const at = args.indexOf(name);
	return at >= 0 ? args.splice(at, 2)[1] : undefined;
};
const from = option('--from');
const seedsFile = option('--seeds');
const [command, ...rest] = args;

function usage(message) {
	if (message) console.error(`standard: ${message}`);
	console.error(
		'usage: node scripts/standard.js check [app ...] [--from <dir>] | apply <app> <worktree> [--seeds f] | settings <check|apply> [app ...]'
	);
	process.exit(2);
}

const pick = (names) => {
	for (const name of names)
		if (!(name in apps)) usage(`no app '${name}'; try: ${Object.keys(apps).join(', ')}`);
	return (names.length ? names : Object.keys(apps)).map((name) => apps[name]);
};

/** Every template file: its path in the app (rendered), its bytes, whether it's text and executable. */
function files(app) {
	const walk = (dir) =>
		readdirSync(dir, { withFileTypes: true }).flatMap((entry) =>
			entry.isDirectory() ? walk(join(dir, entry.name)) : [join(dir, entry.name)]
		);
	return walk(templates).map((source) => {
		const bytes = readFileSync(source);
		const text = !source.endsWith('.png');
		return {
			path: render(relative(templates, source), app),
			bytes,
			text: text ? render(bytes.toString('utf8'), app) : null,
			executable: (statSync(source).mode & 0o111) !== 0
		};
	});
}

/** Reads a file from an app's main branch, or null when it isn't there. */
function reader(app) {
	if (from) {
		const base = join(from, app.REPO);
		return {
			read: (path) => (existsSync(join(base, path)) ? readFileSync(join(base, path)) : null),
			executable: (path) => (statSync(join(base, path)).mode & 0o111) !== 0
		};
	}
	// The app repositories sit beside this one's main checkout, even when this runs in a worktree.
	const common = execFileSync(
		'git',
		['-C', root, 'rev-parse', '--path-format=absolute', '--git-common-dir'],
		{ encoding: 'utf8' }
	).trim();
	const repo = join(dirname(dirname(common)), app.DIR);
	execFileSync('git', ['-C', repo, 'fetch', '--quiet', 'origin']);
	const git = (...a) =>
		execFileSync('git', ['-C', repo, ...a], { maxBuffer: 1 << 26, stdio: ['ignore', 'pipe', 'ignore'] });
	return {
		read: (path) => {
			try {
				return git('show', `origin/main:${path}`);
			} catch {
				return null;
			}
		},
		executable: (path) => git('ls-tree', 'origin/main', '--', path).toString().startsWith('100755')
	};
}

function check(app) {
	const problems = [];
	const repo = reader(app);
	for (const file of files(app)) {
		const current = repo.read(file.path);
		if (!current) {
			problems.push(`${file.path}: missing`);
			continue;
		}
		if (file.text === null) {
			if (!current.equals(file.bytes)) problems.push(`${file.path}: differs from the standard`);
		} else {
			for (const p of compare(file.text, current.toString('utf8'))) problems.push(`${file.path}: ${p}`);
		}
		if (file.executable && !repo.executable(file.path)) problems.push(`${file.path}: must be executable`);
	}
	for (const [path, test] of Object.entries(owned)) {
		const current = repo.read(path);
		if (!current) problems.push(`${path}: missing`);
		else for (const p of test(current.toString('utf8'), app)) problems.push(`${path}: ${p}`);
	}
	return problems;
}

function apply(app, worktree) {
	const seeds = seedsFile ? JSON.parse(readFileSync(seedsFile, 'utf8')) : {};
	for (const file of files(app)) {
		const target = join(worktree, file.path);
		mkdirSync(dirname(target), { recursive: true });
		const current = existsSync(target) ? readFileSync(target) : null;
		const next =
			file.text === null
				? file.bytes
				: Buffer.from(merge(file.text, current?.toString('utf8'), seeds[file.path]));
		if (!current || !current.equals(next)) {
			writeFileSync(target, next);
			console.log(`wrote ${file.path}`);
		}
		if (file.executable) chmodSync(target, 0o755);
	}
	for (const [path, test] of Object.entries(owned)) {
		const target = join(worktree, path);
		const problems = existsSync(target) ? test(readFileSync(target, 'utf8'), app) : ['missing'];
		for (const p of problems) console.log(`fix by hand: ${path}: ${p}`);
	}
}

const gh = (...a) => execFileSync('gh', a, { encoding: 'utf8' });
const ghJson = (...a) => JSON.parse(gh(...a));

function settingsDrift(app) {
	const want = settings(app);
	const name = `oddurs/${app.REPO}`;
	const problems = [];
	const repo = ghJson('api', `repos/${name}`);
	for (const [key, value] of Object.entries(want.repo))
		if (repo[key] !== value)
			problems.push(`${key} is ${JSON.stringify(repo[key])}, want ${JSON.stringify(value)}`);
	if ([...repo.topics].sort().join(',') !== want.topics.join(','))
		problems.push(`topics are ${repo.topics.join(',')}, want ${want.topics.join(',')}`);
	const p = ghJson('api', `repos/${name}/branches/main/protection`);
	const have = {
		strict: p.required_status_checks?.strict,
		contexts: p.required_status_checks?.contexts?.join(','),
		enforce_admins: p.enforce_admins?.enabled,
		dismiss_stale_reviews: p.required_pull_request_reviews?.dismiss_stale_reviews,
		approvals: p.required_pull_request_reviews?.required_approving_review_count,
		conversation: p.required_conversation_resolution?.enabled,
		force_pushes: p.allow_force_pushes?.enabled,
		deletions: p.allow_deletions?.enabled
	};
	const expected = {
		strict: false,
		contexts: 'required',
		enforce_admins: true,
		dismiss_stale_reviews: true,
		approvals: 0,
		conversation: true,
		force_pushes: false,
		deletions: false
	};
	for (const [key, value] of Object.entries(expected))
		if (have[key] !== value)
			problems.push(
				`branch protection ${key} is ${JSON.stringify(have[key])}, want ${JSON.stringify(value)}`
			);
	const workflow = ghJson('api', `repos/${name}/actions/permissions/workflow`);
	if (workflow.default_workflow_permissions !== want.workflow_permissions)
		problems.push(
			`workflow token is ${workflow.default_workflow_permissions}, want ${want.workflow_permissions}`
		);
	const reporting = ghJson('api', `repos/${name}/private-vulnerability-reporting`);
	if (!reporting.enabled) problems.push('private vulnerability reporting is off');
	return problems;
}

function settingsApply(app) {
	const want = settings(app);
	const name = `oddurs/${app.REPO}`;
	const json = (method, path, body) =>
		execFileSync('gh', ['api', '-X', method, path, '--input', '-'], {
			input: JSON.stringify(body),
			encoding: 'utf8'
		});
	json('PATCH', `repos/${name}`, want.repo);
	json('PUT', `repos/${name}/topics`, { names: want.topics });
	json('PUT', `repos/${name}/branches/main/protection`, want.protection);
	json('PUT', `repos/${name}/actions/permissions/workflow`, {
		default_workflow_permissions: want.workflow_permissions
	});
	gh('api', '-X', 'PUT', `repos/${name}/private-vulnerability-reporting`);
	gh('api', '-X', 'PUT', `repos/${name}/vulnerability-alerts`);
	gh('api', '-X', 'PUT', `repos/${name}/automated-security-fixes`);
	console.log(`applied settings to ${name}`);
}

let failed = false;
switch (command) {
	case 'check':
		for (const app of pick(rest)) {
			const problems = check(app);
			console.log(problems.length ? `✗ ${app.NAME} (${app.REPO})` : `✓ ${app.NAME} (${app.REPO})`);
			for (const p of problems) console.log(`    ${p}`);
			failed ||= problems.length > 0;
		}
		break;
	case 'apply': {
		const [name, worktree] = rest;
		if (!name || !worktree) usage('apply needs an app and a worktree');
		apply(pick([name])[0], worktree);
		break;
	}
	case 'settings': {
		const [mode, ...names] = rest;
		if (mode !== 'check' && mode !== 'apply') usage('settings needs check or apply');
		for (const app of pick(names)) {
			if (mode === 'apply') settingsApply(app);
			const problems = settingsDrift(app);
			console.log(problems.length ? `✗ ${app.REPO} settings` : `✓ ${app.REPO} settings`);
			for (const p of problems) console.log(`    ${p}`);
			failed ||= problems.length > 0;
		}
		break;
	}
	default:
		usage(command ? `unknown command '${command}'` : '');
}
process.exit(failed ? 1 : 0);
