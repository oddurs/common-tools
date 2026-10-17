<script lang="ts">
	// The one step every download needs until the builds are notarized, written once.
	import type { Tool } from './tools';

	let { tool, command = false }: { tool: Tool; command?: boolean } = $props();
</script>

The first time, macOS says it can't verify the developer: the build is signed but not notarized. Open
<b>System Settings › Privacy &amp; Security</b>, scroll down, and click <b>Open Anyway</b> next to
{tool.name}.
{#if command}
	Or clear the flag from a terminal:
	<pre><code>xattr -dr com.apple.quarantine "/Applications/{tool.name}.app"</code></pre>
{/if}
