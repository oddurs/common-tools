<script lang="ts">
	import type { Snippet } from 'svelte';
	import { page } from '$app/state';
	import { download, releasesOf, type Tool } from './tools';

	let { tool, children }: { tool: Tool; children?: Snippet } = $props();
	const app = $derived(`/Applications/${tool.name}.app`);
	const release = $derived(page.data.releases?.[tool.slug]);
</script>

<p>{tool.requires}.</p>
<ol>
	<li>
		Download <a href={download(tool, release)}><code>{tool.asset}</code></a>, unzip it, and move
		<b>{tool.name}</b> to Applications.
	</li>
	<li>
		Open it. The build is signed but not notarized, so the first time macOS says it can't verify the
		developer. Go to
		<b>System Settings › Privacy &amp; Security</b> and click <b>Open Anyway</b>. Or run:
		<pre><code>xattr -dr com.apple.quarantine "{app}"</code></pre>
	</li>
	{@render children?.()}
</ol>
<p>
	Every release, with checksums and notes, is on <a href={releasesOf(tool)}>GitHub</a>. To check a download:
	<code>shasum -a 256 -c {tool.asset}.sha256</code>.
</p>
