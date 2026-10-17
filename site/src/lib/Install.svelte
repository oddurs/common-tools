<script lang="ts">
	// The Install section of every app's docs: the download, the Open Anyway step, the permission
	// where the app needs one, and the two terminal ways that skip Open Anyway.
	import { page } from '$app/state';
	import OpenAnyway from './OpenAnyway.svelte';
	import { brewLine, curlLine, download, releasesOf, type Tool } from './tools';

	let { tool }: { tool: Tool } = $props();
	const release = $derived(page.data.releases?.[tool.slug]);
</script>

<p>{tool.requires}.</p>
<ol>
	<li>
		Download <a href={download(tool, release)}><code>{tool.asset}</code></a>, unzip it, and move
		<b>{tool.name}</b> to Applications.
		{#if release?.dmg}
			Or open the <a href={release.dmg}>disk image</a> and drag it there.
		{/if}
	</li>
	<li>Open it. <OpenAnyway {tool} command /></li>
	{#if tool.permission}
		<li>
			Allow <b>{tool.permission.name}</b> access when asked, {tool.permission.why}. It's a switch in
			<b>System Settings › Privacy &amp; Security › {tool.permission.name}</b>. Until the builds are
			notarized, each update needs this allowed again, because the build's signature changes.
		</li>
	{/if}
	<li>{tool.firstRun}</li>
</ol>

<h3>From a terminal</h3>
<p>Both install the same build and clear the quarantine flag, so there is no Open Anyway step.</p>
{#if release?.cask}
	<pre><code>{brewLine(tool)}</code></pre>
	<p>
		Homebrew keeps it current with <code>brew upgrade</code>. The cask is in
		<a href="https://github.com/oddurs/homebrew-common-tools">oddurs/homebrew-common-tools</a>.
	</p>
{/if}
<pre><code>{curlLine(tool)}</code></pre>
<p>
	The script downloads the latest release, checks it against the published checksum, installs it in
	Applications in place of an older copy, and opens it. Name several apps to install them all, or run it
	with no name to list them. It's <a
		href="https://github.com/oddurs/common-tools/blob/main/site/static/install.sh"
		>short enough to read first</a
	>.
</p>
<p>
	Every release, with checksums and notes, is on <a href={releasesOf(tool)}>GitHub</a>. To check a download:
	<code>shasum -a 256 -c {tool.asset}.sha256</code>.
</p>
